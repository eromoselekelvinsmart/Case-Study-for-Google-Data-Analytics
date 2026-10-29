-- =====================================================================
-- Cyclistic case study | 01_load_raw.sql
-- Author: Eromosele Smart Ochie
-- Engine: DuckDB (run from the project folder: cyclistic-bike-share-analysis/)
--
-- Loads the two quarterly Divvy files exactly as downloaded.
-- Everything comes in as text so nothing is converted before I have
-- looked at it. Types are set on purpose in 02_standardize.sql.
-- =====================================================================

CREATE OR REPLACE TABLE raw_trips_2019_q1 AS
SELECT *
FROM read_csv('data/raw/Divvy_Trips_2019_Q1.csv', header = true, all_varchar = true);

CREATE OR REPLACE TABLE raw_trips_2020_q1 AS
SELECT *
FROM read_csv('data/raw/Divvy_Trips_2020_Q1.csv', header = true, all_varchar = true);

-- Quick profile: row counts and date coverage per file
CREATE OR REPLACE TABLE profile_raw AS
SELECT '2019 Q1' AS source_file,
       COUNT(*)                         AS row_count,
       COUNT(DISTINCT trip_id)          AS distinct_ids,
       MIN(start_time)                  AS first_start,
       MAX(start_time)                  AS last_start
FROM raw_trips_2019_q1
UNION ALL
SELECT '2020 Q1',
       COUNT(*),
       COUNT(DISTINCT ride_id),
       MIN(started_at),
       MAX(started_at)
FROM raw_trips_2020_q1;
