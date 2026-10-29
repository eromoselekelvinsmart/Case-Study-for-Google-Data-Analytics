-- =====================================================================
-- Cyclistic case study | 02_standardize.sql
-- Author: Eromosele Smart Ochie
--
-- The two files use different column names and rider labels:
--   2019: trip_id, start_time, from_station_*, usertype (Subscriber/Customer)
--   2020: ride_id, started_at, start_station_*, member_casual (member/casual)
-- I map 2019 onto the 2020 layout so both quarters can be stacked.
-- =====================================================================

CREATE OR REPLACE TABLE trips_2019_std AS
SELECT
    CAST(trip_id AS VARCHAR)                         AS ride_id,
    'docked_bike'                                    AS rideable_type,   -- 2019 only had docked bikes (no e-bikes yet)
    CAST(start_time AS TIMESTAMP)                    AS started_at,
    CAST(end_time   AS TIMESTAMP)                    AS ended_at,
    TRIM(from_station_name)                          AS start_station_name,
    TRY_CAST(from_station_id AS INTEGER)             AS start_station_id,
    TRIM(to_station_name)                            AS end_station_name,
    TRY_CAST(to_station_id AS INTEGER)               AS end_station_id,
    CASE usertype
        WHEN 'Subscriber' THEN 'member'
        WHEN 'Customer'   THEN 'casual'
    END                                              AS member_casual,
    NULLIF(TRIM(gender), '')                         AS gender,          -- 2019 only
    TRY_CAST(birthyear AS INTEGER)                   AS birth_year,      -- 2019 only
    -- tripduration is stored as text like "1,783.0"; strip the comma before casting
    TRY_CAST(REPLACE(tripduration, ',', '') AS DOUBLE) AS reported_duration_sec,
    2019                                             AS source_year
FROM raw_trips_2019_q1;

CREATE OR REPLACE TABLE trips_2020_std AS
SELECT
    ride_id,
    rideable_type,
    CAST(started_at AS TIMESTAMP)                    AS started_at,
    CAST(ended_at   AS TIMESTAMP)                    AS ended_at,
    TRIM(start_station_name)                         AS start_station_name,
    TRY_CAST(start_station_id AS INTEGER)            AS start_station_id,
    TRIM(end_station_name)                           AS end_station_name,
    TRY_CAST(end_station_id AS INTEGER)              AS end_station_id,
    member_casual,
    CAST(NULL AS VARCHAR)                            AS gender,
    CAST(NULL AS INTEGER)                            AS birth_year,
    CAST(NULL AS DOUBLE)                             AS reported_duration_sec,
    2020                                             AS source_year
FROM raw_trips_2020_q1;

-- Stack both quarters
CREATE OR REPLACE TABLE all_trips AS
SELECT * FROM trips_2019_std
UNION ALL BY NAME
SELECT * FROM trips_2020_std;
