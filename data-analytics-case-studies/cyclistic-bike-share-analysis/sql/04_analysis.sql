-- =====================================================================
-- Cyclistic case study | 04_analysis.sql
-- Author: Eromosele Smart Ochie
--
-- Builds every summary table used in the Excel workbook, the charts and
-- the report, and exports each one to data/processed/ as CSV.
-- Business question: how do annual members and casual riders use
-- Cyclistic bikes differently?
-- =====================================================================

-- 1) Headline comparison: members vs casual riders (both quarters combined)
CREATE OR REPLACE TABLE a01_rider_summary AS
SELECT
    member_casual,
    COUNT(*)                                                         AS rides,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)               AS share_of_rides_pct,
    ROUND(AVG(ride_length_min), 1)                                   AS avg_ride_min,
    ROUND(MEDIAN(ride_length_min), 1)                                AS median_ride_min,
    ROUND(100.0 * AVG(CASE WHEN ride_length_min > 30 THEN 1 ELSE 0 END), 1) AS pct_rides_over_30_min,
    ROUND(100.0 * AVG(CASE WHEN day_type = 'Weekend' THEN 1 ELSE 0 END), 1) AS pct_weekend_rides,
    ROUND(100.0 * AVG(CASE WHEN is_round_trip THEN 1 ELSE 0 END), 1) AS pct_round_trips
FROM trips_clean
GROUP BY member_casual
ORDER BY member_casual DESC;

-- 2) Same comparison split by year, with year-over-year growth
CREATE OR REPLACE TABLE a02_rider_summary_by_year AS
WITH y AS (
    SELECT ride_year, member_casual,
           COUNT(*)                          AS rides,
           ROUND(AVG(ride_length_min), 1)    AS avg_ride_min,
           ROUND(MEDIAN(ride_length_min), 1) AS median_ride_min
    FROM trips_clean
    GROUP BY ride_year, member_casual
)
SELECT y.*,
       ROUND(100.0 * (rides - LAG(rides) OVER (PARTITION BY member_casual ORDER BY ride_year))
             / LAG(rides) OVER (PARTITION BY member_casual ORDER BY ride_year), 1) AS yoy_rides_pct
FROM y
ORDER BY member_casual DESC, ride_year;

-- 3) Day of week (1 = Sunday)
CREATE OR REPLACE TABLE a03_by_weekday AS
SELECT member_casual, day_of_week, day_name,
       COUNT(*)                          AS rides,
       ROUND(AVG(ride_length_min), 1)    AS avg_ride_min,
       ROUND(MEDIAN(ride_length_min), 1) AS median_ride_min
FROM trips_clean
GROUP BY member_casual, day_of_week, day_name
ORDER BY member_casual DESC, day_of_week;

-- 4) Hour of day, weekday vs weekend (share of each rider type's rides)
CREATE OR REPLACE TABLE a04_by_hour AS
WITH h AS (
    SELECT member_casual, day_type, start_hour, COUNT(*) AS rides
    FROM trips_clean
    GROUP BY member_casual, day_type, start_hour
)
SELECT h.*,
       ROUND(100.0 * rides / SUM(rides) OVER (PARTITION BY member_casual, day_type), 2) AS pct_of_type_daytype
FROM h
ORDER BY member_casual DESC, day_type, start_hour;

-- 5) Peak windows: top 3 start hours for each rider type and day type
CREATE OR REPLACE TABLE a05_peak_windows AS
SELECT member_casual, day_type, start_hour, rides, pct_of_type_daytype,
       ROW_NUMBER() OVER (PARTITION BY member_casual, day_type ORDER BY rides DESC) AS peak_rank
FROM a04_by_hour
QUALIFY peak_rank <= 3
ORDER BY member_casual DESC, day_type, peak_rank;

-- 6) Weekday x hour heatmap (rides)
CREATE OR REPLACE TABLE a06_heatmap AS
SELECT member_casual, day_of_week, day_name, start_hour, COUNT(*) AS rides
FROM trips_clean
GROUP BY member_casual, day_of_week, day_name, start_hour
ORDER BY member_casual DESC, day_of_week, start_hour;

-- 7) Month-by-month (seasonal) trend and casual share
CREATE OR REPLACE TABLE a07_by_month AS
WITH m AS (
    SELECT ride_year, ride_month, month_name,
           COUNT(*) FILTER (WHERE member_casual = 'member') AS member_rides,
           COUNT(*) FILTER (WHERE member_casual = 'casual') AS casual_rides,
           ROUND(AVG(ride_length_min) FILTER (WHERE member_casual = 'member'), 1) AS member_avg_min,
           ROUND(AVG(ride_length_min) FILTER (WHERE member_casual = 'casual'), 1) AS casual_avg_min
    FROM trips_clean
    GROUP BY ride_year, ride_month, month_name
)
SELECT m.*,
       ROUND(100.0 * casual_rides / (member_rides + casual_rides), 1) AS casual_share_pct
FROM m
ORDER BY ride_year, ride_month;

-- 8) Ride-length distribution
CREATE OR REPLACE TABLE a08_length_bands AS
WITH b AS (
    SELECT member_casual, length_band, COUNT(*) AS rides
    FROM trips_clean
    GROUP BY member_casual, length_band
)
SELECT b.*, ROUND(100.0 * rides / SUM(rides) OVER (PARTITION BY member_casual), 1) AS pct_of_type
FROM b
ORDER BY member_casual DESC, length_band;

-- 9) Daily ride counts (for the trend line)
CREATE OR REPLACE TABLE a09_daily AS
SELECT ride_date, ride_year,
       COUNT(*) FILTER (WHERE member_casual = 'member') AS member_rides,
       COUNT(*) FILTER (WHERE member_casual = 'casual') AS casual_rides
FROM trips_clean
GROUP BY ride_date, ride_year
ORDER BY ride_date;

-- 10) Where casual riders start: top 15 stations by casual rides
CREATE OR REPLACE TABLE a10_casual_hotspots AS
SELECT start_station_id,
       MAX_BY(start_station_name, started_at)                          AS station_name,
       COUNT(*)                                                        AS total_rides,
       COUNT(*) FILTER (WHERE member_casual = 'casual')                AS casual_rides,
       ROUND(100.0 * COUNT(*) FILTER (WHERE member_casual = 'casual') / COUNT(*), 1) AS casual_share_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE member_casual = 'casual' AND day_type = 'Weekend')
             / NULLIF(COUNT(*) FILTER (WHERE member_casual = 'casual'), 0), 1)       AS casual_weekend_pct,
       ROUND(MEDIAN(ride_length_min) FILTER (WHERE member_casual = 'casual'), 1)     AS casual_median_min
FROM trips_clean
GROUP BY start_station_id
ORDER BY casual_rides DESC
LIMIT 15;

-- 11) Conversion-ready casual rides: weekday, commute hours (6-9 am or 4-6 pm), under 30 min.
--     These look like member trips, taken without a membership.
CREATE OR REPLACE TABLE a11_commute_like_casual AS
SELECT member_casual,
       COUNT(*)                                                         AS rides,
       COUNT(*) FILTER (WHERE day_type = 'Weekday'
                          AND (start_hour BETWEEN 6 AND 9 OR start_hour BETWEEN 16 AND 18)
                          AND ride_length_min < 30)                     AS commute_like_rides,
       ROUND(100.0 * commute_like_rides / rides, 1)                     AS commute_like_pct
FROM trips_clean
GROUP BY member_casual
ORDER BY member_casual DESC;

CREATE OR REPLACE TABLE a12_commute_like_casual_stations AS
SELECT start_station_id,
       MAX_BY(start_station_name, started_at) AS station_name,
       COUNT(*)                               AS commute_like_casual_rides
FROM trips_clean
WHERE member_casual = 'casual'
  AND day_type = 'Weekday'
  AND (start_hour BETWEEN 6 AND 9 OR start_hour BETWEEN 16 AND 18)
  AND ride_length_min < 30
GROUP BY start_station_id
ORDER BY commute_like_casual_rides DESC
LIMIT 15;

-- 12) Churn indicator 1 - station level.
--     No rider IDs exist, so I track member ride volume by start station.
--     Jan-Feb only, to compare like-for-like before COVID-19 changed March 2020.
CREATE OR REPLACE TABLE a13_station_member_yoy AS
WITH s AS (
    SELECT start_station_id,
           MAX_BY(start_station_name, started_at) AS station_name,
           COUNT(*) FILTER (WHERE ride_year = 2019 AND member_casual = 'member' AND ride_month <= 2) AS member_rides_janfeb_2019,
           COUNT(*) FILTER (WHERE ride_year = 2020 AND member_casual = 'member' AND ride_month <= 2) AS member_rides_janfeb_2020
    FROM trips_clean
    GROUP BY start_station_id
), net AS (
    SELECT 100.0 * (SUM(member_rides_janfeb_2020) - SUM(member_rides_janfeb_2019))
                 / SUM(member_rides_janfeb_2019) AS network_growth_pct
    FROM s
)
SELECT s.*,
       ROUND(100.0 * (member_rides_janfeb_2020 - member_rides_janfeb_2019) / member_rides_janfeb_2019, 1) AS station_growth_pct,
       ROUND(net.network_growth_pct, 1) AS network_growth_pct,
       CASE
           WHEN member_rides_janfeb_2020 < member_rides_janfeb_2019 THEN 'Declining'
           WHEN 100.0 * (member_rides_janfeb_2020 - member_rides_janfeb_2019) / member_rides_janfeb_2019
                < net.network_growth_pct / 2                       THEN 'Lagging network'
           ELSE 'Growing'
       END AS member_trend_flag
FROM s, net
WHERE member_rides_janfeb_2019 >= 500          -- busy stations only, so % changes are meaningful
ORDER BY station_growth_pct;

-- 13) Churn indicator 2 - March split (first vs second half of the month)
CREATE OR REPLACE TABLE a14_march_split AS
WITH m AS (
    SELECT ride_year, member_casual,
           CASE WHEN day(started_at) <= 14 THEN 'Mar 1-14' ELSE 'Mar 15-31' END AS march_period,
           COUNT(*) AS rides
    FROM trips_clean
    WHERE ride_month = 3
    GROUP BY ride_year, member_casual, march_period
)
SELECT m19.member_casual, m19.march_period,
       m19.rides AS rides_2019,
       m20.rides AS rides_2020,
       ROUND(100.0 * (m20.rides - m19.rides) / m19.rides, 1) AS yoy_pct
FROM m m19
JOIN m m20 ON m20.member_casual = m19.member_casual
          AND m20.march_period  = m19.march_period
          AND m20.ride_year = 2020
WHERE m19.ride_year = 2019
ORDER BY m19.member_casual DESC, m19.march_period;

-- 14) 2019 rider profile (gender and birth year only exist in 2019)
CREATE OR REPLACE TABLE a15_profile_2019 AS
SELECT member_casual,
       COUNT(*)                                                                         AS rides_2019,
       ROUND(100.0 * COUNT(*) FILTER (WHERE gender IS NULL) / COUNT(*), 1)               AS gender_missing_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE gender = 'Female') / COUNT(gender), 1)       AS female_pct_of_known,
       ROUND(MEDIAN(rider_age), 0)                                                      AS median_age,
       ROUND(100.0 * COUNT(*) FILTER (WHERE rider_age IS NULL) / COUNT(*), 1)            AS age_missing_pct
FROM trips_clean
WHERE ride_year = 2019
GROUP BY member_casual
ORDER BY member_casual DESC;

-- 15) Hourly fact table - the pivot-table source loaded into Excel
CREATE OR REPLACE TABLE fact_rides_hourly AS
SELECT ride_date, ride_year, ride_month, month_name, day_of_week, day_name, day_type,
       start_hour, member_casual,
       COUNT(*)                                            AS rides,
       ROUND(SUM(ride_length_min), 2)                      AS total_ride_min,
       COUNT(*) FILTER (WHERE is_round_trip)               AS round_trips,
       COUNT(*) FILTER (WHERE ride_length_min > 30)        AS rides_over_30_min
FROM trips_clean
GROUP BY ALL
ORDER BY ride_date, start_hour, member_casual;

-- ---------------------------------------------------------------------
-- Export
-- ---------------------------------------------------------------------
COPY cleaning_log                   TO 'data/processed/00_cleaning_log.csv'              (HEADER);
COPY a01_rider_summary              TO 'data/processed/01_rider_summary.csv'             (HEADER);
COPY a02_rider_summary_by_year      TO 'data/processed/02_rider_summary_by_year.csv'     (HEADER);
COPY a03_by_weekday                 TO 'data/processed/03_by_weekday.csv'                (HEADER);
COPY a04_by_hour                    TO 'data/processed/04_by_hour.csv'                   (HEADER);
COPY a05_peak_windows               TO 'data/processed/05_peak_windows.csv'              (HEADER);
COPY a06_heatmap                    TO 'data/processed/06_heatmap_weekday_hour.csv'      (HEADER);
COPY a07_by_month                   TO 'data/processed/07_by_month.csv'                  (HEADER);
COPY a08_length_bands               TO 'data/processed/08_ride_length_bands.csv'         (HEADER);
COPY a09_daily                      TO 'data/processed/09_daily_rides.csv'               (HEADER);
COPY a10_casual_hotspots            TO 'data/processed/10_casual_hotspot_stations.csv'   (HEADER);
COPY a11_commute_like_casual        TO 'data/processed/11_commute_like_rides.csv'        (HEADER);
COPY a12_commute_like_casual_stations TO 'data/processed/12_commute_like_casual_stations.csv' (HEADER);
COPY a13_station_member_yoy         TO 'data/processed/13_station_member_yoy.csv'        (HEADER);
COPY a14_march_split                TO 'data/processed/14_march_split.csv'               (HEADER);
COPY a15_profile_2019               TO 'data/processed/15_rider_profile_2019.csv'        (HEADER);
COPY fact_rides_hourly              TO 'data/processed/fact_rides_hourly.csv'            (HEADER);
