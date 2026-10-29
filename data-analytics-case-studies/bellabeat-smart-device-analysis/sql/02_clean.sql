-- =====================================================================
-- Bellabeat case study | 02_clean.sql
-- Author: Eromosele Smart Ochie
--
-- Cleaning rules for a user-day (first match wins):
--   D1  2016-05-12            -> exclude (export cut-off; most users only have part of this day)
--   D2  0 steps all day        -> exclude (device not worn)
--   D3  < 10 hours tracked     -> exclude (activity minutes + minutes asleep under 600;
--                                 10 h/day is the usual wear-time rule in accelerometer studies)
--   otherwise                  -> valid day
-- Other fixes:
--   - exact duplicate rows removed from sleepDay (3) and minuteSleep (543)
--   - all date/time text converted to DATE / TIMESTAMP (formats like 4/12/2016 12:00:00 AM)
-- =====================================================================

-- Sleep: one row per user per night, duplicates removed
CREATE OR REPLACE TABLE sleep_day AS
SELECT DISTINCT
    CAST(Id AS BIGINT)                                               AS user_id,
    CAST(strptime(SleepDay, '%m/%d/%Y %I:%M:%S %p') AS DATE)         AS activity_date,
    CAST(TotalSleepRecords AS INTEGER)                               AS sleep_records,
    CAST(TotalMinutesAsleep AS INTEGER)                              AS minutes_asleep,
    CAST(TotalTimeInBed AS INTEGER)                                  AS minutes_in_bed
FROM raw_sleep_day;

-- Daily activity with sleep attached and day-validity flag
CREATE OR REPLACE TABLE daily_flagged AS
WITH a AS (
    SELECT
        CAST(Id AS BIGINT)                                AS user_id,
        CAST(strptime(ActivityDate, '%m/%d/%Y') AS DATE)  AS activity_date,
        CAST(TotalSteps AS INTEGER)                       AS total_steps,
        ROUND(CAST(TotalDistance AS DOUBLE), 2)           AS total_distance_km,
        CAST(VeryActiveMinutes AS INTEGER)                AS very_active_min,
        CAST(FairlyActiveMinutes AS INTEGER)              AS fairly_active_min,
        CAST(LightlyActiveMinutes AS INTEGER)             AS lightly_active_min,
        CAST(SedentaryMinutes AS INTEGER)                 AS sedentary_min,
        CAST(Calories AS INTEGER)                         AS calories
    FROM raw_daily_activity
)
SELECT
    a.*,
    very_active_min + fairly_active_min + lightly_active_min + sedentary_min        AS activity_tracked_min,
    s.minutes_asleep,
    s.minutes_in_bed,
    (s.minutes_asleep IS NOT NULL)                                                  AS has_sleep_record,
    very_active_min + fairly_active_min + lightly_active_min + sedentary_min
        + COALESCE(s.minutes_asleep, 0)                                             AS total_tracked_min,
    CASE
        WHEN a.activity_date = DATE '2016-05-12'                                    THEN 'D1_export_cutoff_day'
        WHEN total_steps = 0                                                        THEN 'D2_not_worn'
        WHEN very_active_min + fairly_active_min + lightly_active_min + sedentary_min
             + COALESCE(s.minutes_asleep, 0) < 600                                  THEN 'D3_under_10h_tracked'
        ELSE 'valid'
    END                                                                             AS day_flag
FROM a
LEFT JOIN sleep_day s USING (user_id, activity_date);

CREATE OR REPLACE TABLE cleaning_log AS
SELECT day_flag, COUNT(*) AS user_days, COUNT(DISTINCT user_id) AS users
FROM daily_flagged
GROUP BY day_flag
ORDER BY day_flag;

-- Clean daily table used for analysis
CREATE OR REPLACE TABLE daily_clean AS
SELECT
    user_id,
    activity_date,
    dayofweek(activity_date) + 1                                     AS day_of_week,  -- 1 = Sunday
    strftime(activity_date, '%A')                                    AS day_name,
    CASE WHEN dayofweek(activity_date) IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    date_diff('day', DATE '2016-04-12', activity_date) + 1           AS study_day,
    total_steps,
    total_distance_km,
    very_active_min,
    fairly_active_min,
    lightly_active_min,
    sedentary_min,
    very_active_min + fairly_active_min                              AS mvpa_min,          -- moderate-to-vigorous
    fairly_active_min + 2 * very_active_min                          AS mvpa_equivalent_min, -- CDC: 1 vigorous min = 2 moderate
    calories,
    activity_tracked_min,
    has_sleep_record,
    minutes_asleep,
    minutes_in_bed,
    ROUND(minutes_asleep * 1.0 / NULLIF(minutes_in_bed, 0), 3)       AS sleep_efficiency,
    total_tracked_min
FROM daily_flagged
WHERE day_flag = 'valid';

-- Hourly table: steps + intensity + calories, kept only for valid days
CREATE OR REPLACE TABLE hourly_clean AS
WITH h AS (
    SELECT
        CAST(st.Id AS BIGINT)                                        AS user_id,
        strptime(st.ActivityHour, '%m/%d/%Y %I:%M:%S %p')            AS activity_hour,
        CAST(st.StepTotal AS INTEGER)                                AS steps,
        CAST(i.TotalIntensity AS INTEGER)                            AS total_intensity,
        CAST(c.Calories AS INTEGER)                                  AS calories
    FROM raw_hourly_steps st
    JOIN raw_hourly_intensities i ON i.Id = st.Id AND i.ActivityHour = st.ActivityHour
    JOIN raw_hourly_calories   c ON c.Id = st.Id AND c.ActivityHour = st.ActivityHour
)
SELECT
    h.user_id,
    h.activity_hour,
    CAST(h.activity_hour AS DATE)                                    AS activity_date,
    hour(h.activity_hour)                                            AS hour_of_day,
    d.day_of_week,
    d.day_name,
    d.day_type,
    h.steps,
    h.total_intensity,
    h.calories
FROM h
JOIN daily_clean d
  ON d.user_id = h.user_id
 AND d.activity_date = CAST(h.activity_hour AS DATE);

-- Minute-level sleep: duplicates removed; used to find when people fall asleep
CREATE OR REPLACE TABLE sleep_minutes AS
SELECT DISTINCT
    CAST(Id AS BIGINT)                                   AS user_id,
    strptime(date, '%m/%d/%Y %I:%M:%S %p')               AS minute_ts,
    CAST(value AS INTEGER)                               AS sleep_state,   -- 1 asleep, 2 restless, 3 awake
    CAST(logId AS BIGINT)                                AS log_id
FROM raw_minute_sleep;

-- Weight log: kept only to measure how many people use manual logging
CREATE OR REPLACE TABLE weight_log AS
SELECT
    CAST(Id AS BIGINT)                                   AS user_id,
    CAST(strptime(Date, '%m/%d/%Y %I:%M:%S %p') AS DATE) AS log_date,
    ROUND(CAST(WeightKg AS DOUBLE), 1)                   AS weight_kg,
    TRY_CAST(BMI AS DOUBLE)                              AS bmi,
    (IsManualReport = 'True')                            AS is_manual
FROM raw_weight_log;
