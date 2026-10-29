-- =====================================================================
-- Bellabeat case study | 01_load_raw.sql
-- Author: Eromosele Smart Ochie
-- Engine: DuckDB (run from the project folder: bellabeat-smart-device-analysis/)
--
-- Source: FitBit Fitness Tracker Data (Mobius, Kaggle, CC0), folder
-- "Fitabase Data 4.12.16-5.12.16". dailySteps / dailyCalories /
-- dailyIntensities are not loaded: I joined them to dailyActivity and
-- found 0 mismatches, so they are exact subsets of it.
-- Everything is loaded as text first; types are set in 02_clean.sql.
-- =====================================================================

CREATE OR REPLACE TABLE raw_daily_activity AS
SELECT * FROM read_csv('data/raw/dailyActivity_merged.csv', header = true, all_varchar = true);

CREATE OR REPLACE TABLE raw_sleep_day AS
SELECT * FROM read_csv('data/raw/sleepDay_merged.csv', header = true, all_varchar = true);

CREATE OR REPLACE TABLE raw_hourly_steps AS
SELECT * FROM read_csv('data/raw/hourlySteps_merged.csv', header = true, all_varchar = true);

CREATE OR REPLACE TABLE raw_hourly_intensities AS
SELECT * FROM read_csv('data/raw/hourlyIntensities_merged.csv', header = true, all_varchar = true);

CREATE OR REPLACE TABLE raw_hourly_calories AS
SELECT * FROM read_csv('data/raw/hourlyCalories_merged.csv', header = true, all_varchar = true);

CREATE OR REPLACE TABLE raw_minute_sleep AS
SELECT * FROM read_csv('data/raw/minuteSleep_merged.csv', header = true, all_varchar = true);

CREATE OR REPLACE TABLE raw_weight_log AS
SELECT * FROM read_csv('data/raw/weightLogInfo_merged.csv', header = true, all_varchar = true);

-- Public health benchmarks I added to judge the Fitbit numbers against
CREATE OR REPLACE TABLE ref_guidelines AS
SELECT * FROM read_csv('data/reference/health_guidelines.csv', header = true);

-- Profile: rows, distinct users and duplicate rows per file
CREATE OR REPLACE TABLE profile_raw AS
SELECT 'dailyActivity' AS source_file, COUNT(*) AS row_count, COUNT(DISTINCT Id) AS users,
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM raw_daily_activity)) AS exact_duplicate_rows
FROM raw_daily_activity
UNION ALL
SELECT 'sleepDay', COUNT(*), COUNT(DISTINCT Id),
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM raw_sleep_day))
FROM raw_sleep_day
UNION ALL
SELECT 'hourlySteps', COUNT(*), COUNT(DISTINCT Id),
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM raw_hourly_steps))
FROM raw_hourly_steps
UNION ALL
SELECT 'hourlyIntensities', COUNT(*), COUNT(DISTINCT Id),
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM raw_hourly_intensities))
FROM raw_hourly_intensities
UNION ALL
SELECT 'hourlyCalories', COUNT(*), COUNT(DISTINCT Id),
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM raw_hourly_calories))
FROM raw_hourly_calories
UNION ALL
SELECT 'minuteSleep', COUNT(*), COUNT(DISTINCT Id),
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM raw_minute_sleep))
FROM raw_minute_sleep
UNION ALL
SELECT 'weightLogInfo', COUNT(*), COUNT(DISTINCT Id),
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM raw_weight_log))
FROM raw_weight_log;
