-- =====================================================================
-- Cyclistic case study | 03_clean.sql
-- Author: Eromosele Smart Ochie
--
-- Cleaning rules (applied in this order; first match wins):
--   R1  HQ QR station       -> remove (bikes pulled from service for quality checks, not customer rides)
--   R2  missing end station  -> remove (ride never closed properly)
--   R3  length <= 0 seconds  -> remove (end time before start time)
--   R4  length < 60 seconds  -> remove (false starts / re-docks; Divvy already drops these
--                               from 2019, so removing them from 2020 keeps the years comparable)
--   R5  length > 24 hours    -> remove (bike not returned / lost, not a real ride)
-- Nothing is deleted from all_trips; every row gets a flag so the log can be audited.
-- =====================================================================

CREATE OR REPLACE TABLE trips_flagged AS
SELECT
    *,
    date_diff('second', started_at, ended_at) AS ride_length_sec,
    CASE
        WHEN start_station_name = 'HQ QR' OR end_station_name = 'HQ QR'      THEN 'R1_hq_test_ride'
        WHEN ended_at IS NULL OR end_station_id IS NULL                     THEN 'R2_missing_end'
        WHEN date_diff('second', started_at, ended_at) <= 0                 THEN 'R3_non_positive_length'
        WHEN date_diff('second', started_at, ended_at) < 60                 THEN 'R4_under_60_seconds'
        WHEN date_diff('second', started_at, ended_at) > 86400              THEN 'R5_over_24_hours'
        ELSE 'keep'
    END AS clean_flag
FROM all_trips;

-- Duplicate check (expected: zero)
CREATE OR REPLACE TABLE check_duplicates AS
SELECT ride_id, COUNT(*) AS n
FROM trips_flagged
GROUP BY ride_id
HAVING COUNT(*) > 1;

-- Cleaning log: how many rows each rule removed, per year
CREATE OR REPLACE TABLE cleaning_log AS
SELECT source_year, clean_flag, COUNT(*) AS rows_affected
FROM trips_flagged
GROUP BY ALL
ORDER BY source_year, clean_flag;

-- Clean analysis table with the derived fields used everywhere else
CREATE OR REPLACE TABLE trips_clean AS
SELECT
    ride_id,
    source_year                                          AS ride_year,
    member_casual,
    rideable_type,
    started_at,
    ended_at,
    start_station_id,
    -- "(*)" and "(Temp)" are suffixes Divvy adds to some station names; strip them for display
    regexp_replace(start_station_name, '\s*\((\*|Temp)\)', '', 'g') AS start_station_name,
    end_station_id,
    regexp_replace(end_station_name,   '\s*\((\*|Temp)\)', '', 'g') AS end_station_name,
    ride_length_sec,
    ROUND(ride_length_sec / 60.0, 2)                     AS ride_length_min,
    CAST(started_at AS DATE)                             AS ride_date,
    month(started_at)                                    AS ride_month,
    strftime(started_at, '%b')                           AS month_name,
    dayofweek(started_at) + 1                            AS day_of_week,   -- 1 = Sunday ... 7 = Saturday (same as Excel WEEKDAY(x,1))
    strftime(started_at, '%A')                           AS day_name,
    CASE WHEN dayofweek(started_at) IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    hour(started_at)                                     AS start_hour,
    (start_station_id = end_station_id)                  AS is_round_trip,
    CASE
        WHEN ride_length_sec <  5 * 60 THEN '01 | < 5 min'
        WHEN ride_length_sec < 10 * 60 THEN '02 | 5-10 min'
        WHEN ride_length_sec < 20 * 60 THEN '03 | 10-20 min'
        WHEN ride_length_sec < 30 * 60 THEN '04 | 20-30 min'
        WHEN ride_length_sec < 60 * 60 THEN '05 | 30-60 min'
        ELSE                                '06 | 60+ min'
    END                                                  AS length_band,
    gender,
    CASE WHEN birth_year BETWEEN 1929 AND 2003 THEN source_year - birth_year END AS rider_age  -- ages 16-90 only
FROM trips_flagged
WHERE clean_flag = 'keep';
