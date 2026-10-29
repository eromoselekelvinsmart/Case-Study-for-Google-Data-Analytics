-- =====================================================================
-- Bellabeat case study | 03_analysis.sql
-- Author: Eromosele Smart Ochie
--
-- Business questions:
--   1. What are some trends in smart device usage?
--   2. How could these trends apply to Bellabeat customers?
--   3. How could these trends help influence Bellabeat marketing strategy?
-- Every summary is exported to data/processed/ for Excel and the report.
-- =====================================================================

-- 1) Which features do people actually use? (users with any data of each type)
CREATE OR REPLACE TABLE b01_feature_use AS
WITH total AS (SELECT COUNT(DISTINCT user_id) AS n FROM daily_flagged)
SELECT 'Steps / activity (automatic)' AS feature,
       COUNT(DISTINCT user_id) AS users,
       ROUND(100.0 * COUNT(DISTINCT user_id) / (SELECT n FROM total), 1) AS pct_of_users
FROM daily_flagged
UNION ALL
SELECT 'Sleep (must wear overnight)', COUNT(DISTINCT user_id),
       ROUND(100.0 * COUNT(DISTINCT user_id) / (SELECT n FROM total), 1)
FROM sleep_day
UNION ALL
SELECT 'Weight (mostly manual entry)', COUNT(DISTINCT user_id),
       ROUND(100.0 * COUNT(DISTINCT user_id) / (SELECT n FROM total), 1)
FROM weight_log;

-- 2) Per-user profile: averages over valid days, benchmarked against public guidelines
CREATE OR REPLACE TABLE b02_user_profile AS
WITH u AS (
    SELECT user_id,
           COUNT(*)                                    AS valid_days,
           COUNT(*) FILTER (WHERE has_sleep_record)    AS nights_with_sleep,
           ROUND(AVG(total_steps))                     AS avg_steps,
           ROUND(AVG(mvpa_min), 1)                     AS avg_mvpa_min_per_day,
           ROUND(AVG(mvpa_equivalent_min) * 7)         AS weekly_mvpa_equivalent_min,
           ROUND(AVG(sedentary_min) FILTER (WHERE has_sleep_record)) AS avg_sedentary_min_awake,
           ROUND(AVG(minutes_asleep))                  AS avg_minutes_asleep,
           ROUND(AVG(calories))                        AS avg_calories
    FROM daily_clean
    GROUP BY user_id
)
SELECT u.*,
       (SELECT COUNT(*) FROM weight_log w WHERE w.user_id = u.user_id) AS weight_logs,
       CASE
           WHEN avg_steps <  5000  THEN '1 Sedentary (<5k)'
           WHEN avg_steps <  7500  THEN '2 Low active (5k-7.5k)'
           WHEN avg_steps < 10000  THEN '3 Somewhat active (7.5k-10k)'
           WHEN avg_steps <= 12500 THEN '4 Active (10k-12.5k)'
           ELSE                         '5 Highly active (>12.5k)'
       END                                                              AS step_category,
       (weekly_mvpa_equivalent_min >= 150)                              AS meets_cdc_activity,
       CASE WHEN avg_minutes_asleep IS NULL THEN NULL
            ELSE avg_minutes_asleep >= 420 END                          AS meets_7h_sleep,
       ROUND(100.0 * nights_with_sleep / valid_days, 1)                 AS pct_days_with_sleep,
       CASE
           WHEN nights_with_sleep = 0                    THEN 'Never tracks sleep'
           WHEN 1.0 * nights_with_sleep / valid_days < 0.5 THEN 'Sometimes (<50% of days)'
           ELSE                                               'Mostly (50%+ of days)'
       END                                                              AS sleep_tracking_habit
FROM u
ORDER BY avg_steps DESC;

-- 3) Users per step category (Tudor-Locke & Bassett, 2004)
CREATE OR REPLACE TABLE b03_step_categories AS
SELECT step_category,
       COUNT(*) AS users,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_users
FROM b02_user_profile
GROUP BY step_category
ORDER BY step_category;

-- 4) Guideline scorecard
CREATE OR REPLACE TABLE b04_guideline_scorecard AS
SELECT 'Average 8,000+ steps/day'                    AS benchmark,
       COUNT(*) FILTER (WHERE avg_steps >= 8000)       AS users_meeting,
       COUNT(*)                                        AS users_measured
FROM b02_user_profile
UNION ALL
SELECT 'Average 10,000+ steps/day',
       COUNT(*) FILTER (WHERE avg_steps >= 10000), COUNT(*)
FROM b02_user_profile
UNION ALL
SELECT '150+ min/week moderate-equivalent activity (CDC)',
       COUNT(*) FILTER (WHERE meets_cdc_activity), COUNT(*)
FROM b02_user_profile
UNION ALL
SELECT '7+ hours sleep on average (AASM / CDC)',
       COUNT(*) FILTER (WHERE meets_7h_sleep), COUNT(meets_7h_sleep)
FROM b02_user_profile;

ALTER TABLE b04_guideline_scorecard ADD COLUMN pct_meeting DOUBLE;
UPDATE b04_guideline_scorecard SET pct_meeting = ROUND(100.0 * users_meeting / users_measured, 1);

-- 5) Overall daily averages (valid days)
CREATE OR REPLACE TABLE b05_daily_averages AS
SELECT COUNT(*)                                              AS valid_user_days,
       COUNT(DISTINCT user_id)                               AS users,
       ROUND(AVG(total_steps))                               AS avg_steps,
       ROUND(MEDIAN(total_steps))                            AS median_steps,
       ROUND(AVG(very_active_min), 1)                        AS avg_very_active_min,
       ROUND(AVG(fairly_active_min), 1)                      AS avg_fairly_active_min,
       ROUND(AVG(lightly_active_min), 1)                     AS avg_lightly_active_min,
       ROUND(AVG(sedentary_min))                             AS avg_sedentary_min_all_days,
       ROUND(AVG(sedentary_min) FILTER (WHERE has_sleep_record))     AS avg_sedentary_min_sleep_tracked_days,
       ROUND(AVG(sedentary_min) FILTER (WHERE NOT has_sleep_record)) AS avg_sedentary_min_no_sleep_days,
       ROUND(AVG(calories))                                  AS avg_calories,
       ROUND(100.0 * AVG(CASE WHEN has_sleep_record THEN 1 ELSE 0 END), 1) AS pct_days_with_sleep_record
FROM daily_clean;

-- 6) Day of week patterns
CREATE OR REPLACE TABLE b06_by_weekday AS
SELECT day_of_week, day_name,
       COUNT(*)                                   AS user_days,
       ROUND(AVG(total_steps))                    AS avg_steps,
       ROUND(AVG(mvpa_min), 1)                    AS avg_mvpa_min,
       ROUND(AVG(sedentary_min) FILTER (WHERE has_sleep_record)) AS avg_sedentary_min_awake,
       ROUND(AVG(minutes_asleep))                 AS avg_minutes_asleep,
       ROUND(100.0 * AVG(CASE WHEN has_sleep_record THEN 1 ELSE 0 END), 1) AS pct_days_with_sleep
FROM daily_clean
GROUP BY day_of_week, day_name
ORDER BY day_of_week;

-- 7) Hour of day: average steps per user-hour, weekday vs weekend
CREATE OR REPLACE TABLE b07_by_hour AS
SELECT day_type, hour_of_day,
       ROUND(AVG(steps))            AS avg_steps,
       ROUND(AVG(total_intensity), 1) AS avg_intensity,
       ROUND(AVG(calories))         AS avg_calories
FROM hourly_clean
GROUP BY day_type, hour_of_day
ORDER BY day_type, hour_of_day;

-- 8) Engagement over the month: how many people wore the device each day
CREATE OR REPLACE TABLE b08_daily_engagement AS
SELECT f.activity_date,
       date_diff('day', DATE '2016-04-12', f.activity_date) + 1                  AS study_day,
       COUNT(DISTINCT f.user_id) FILTER (WHERE f.day_flag = 'valid')             AS users_with_valid_day,
       COUNT(DISTINCT f.user_id) FILTER (WHERE f.day_flag = 'valid' AND f.has_sleep_record) AS users_tracking_sleep
FROM daily_flagged f
WHERE f.activity_date < DATE '2016-05-12'
GROUP BY f.activity_date
ORDER BY f.activity_date;

-- 9) Sleep summary (nights with a record)
CREATE OR REPLACE TABLE b09_sleep_summary AS
SELECT COUNT(*)                                                   AS nights,
       COUNT(DISTINCT user_id)                                    AS users,
       ROUND(AVG(minutes_asleep))                                 AS avg_minutes_asleep,
       ROUND(AVG(minutes_in_bed))                                 AS avg_minutes_in_bed,
       ROUND(AVG(minutes_in_bed - minutes_asleep))                AS avg_minutes_awake_in_bed,
       ROUND(100.0 * AVG(sleep_efficiency), 1)                    AS avg_sleep_efficiency_pct,
       ROUND(100.0 * AVG(CASE WHEN minutes_asleep >= 420 THEN 1 ELSE 0 END), 1) AS pct_nights_7h_plus
FROM daily_clean
WHERE has_sleep_record;

-- 10) When do people fall asleep? (start of each sleep log, from minute data)
CREATE OR REPLACE TABLE b10_sleep_onset AS
WITH starts AS (
    SELECT user_id, log_id, MIN(minute_ts) AS sleep_start, COUNT(*) AS log_minutes
    FROM sleep_minutes
    GROUP BY user_id, log_id
)
SELECT hour(sleep_start)       AS onset_hour,
       COUNT(*)                AS sleep_logs,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_logs
FROM starts
WHERE log_minutes >= 180          -- main sleep only, not naps
GROUP BY onset_hour
ORDER BY onset_hour;

-- 11) Relationships (Pearson r)
CREATE OR REPLACE TABLE b11_correlations AS
SELECT 'Steps vs calories'                    AS pair, ROUND(CORR(total_steps, calories), 2) AS pearson_r, COUNT(*) AS n_days FROM daily_clean
UNION ALL
SELECT 'Very active minutes vs calories',      ROUND(CORR(very_active_min, calories), 2), COUNT(*) FROM daily_clean
UNION ALL
SELECT 'Awake sedentary minutes vs sleep',     ROUND(CORR(sedentary_min, minutes_asleep), 2), COUNT(*) FROM daily_clean WHERE has_sleep_record
UNION ALL
SELECT 'Steps vs minutes asleep',              ROUND(CORR(total_steps, minutes_asleep), 2), COUNT(*) FROM daily_clean WHERE has_sleep_record;

-- 12) Sedentary time with and without overnight wear (shows why the raw number is misleading)
CREATE OR REPLACE TABLE b12_sedentary_split AS
SELECT CASE WHEN has_sleep_record THEN 'Sleep tracked (worn overnight)' ELSE 'No sleep record' END AS day_group,
       COUNT(*)                          AS user_days,
       ROUND(AVG(sedentary_min))         AS avg_sedentary_min,
       ROUND(AVG(activity_tracked_min))  AS avg_activity_tracked_min,
       ROUND(AVG(total_steps))           AS avg_steps
FROM daily_clean
GROUP BY day_group
ORDER BY day_group DESC;

-- 13) Sleep-tracking habit vs activity
CREATE OR REPLACE TABLE b13_sleep_habit_groups AS
SELECT sleep_tracking_habit,
       COUNT(*)                      AS users,
       ROUND(AVG(avg_steps))         AS avg_steps,
       ROUND(AVG(valid_days), 1)     AS avg_valid_days
FROM b02_user_profile
GROUP BY sleep_tracking_habit
ORDER BY users DESC;


-- 14) Engagement segments used for the marketing rules (see visio page 3)
CREATE OR REPLACE TABLE b14_engagement_segments AS
SELECT
    CASE
        WHEN valid_days < 25                               THEN '1 Drop-off risk (worn < 25 of 30 days)'
        WHEN 1.0 * nights_with_sleep / valid_days < 0.5    THEN '2 Daytime-only wearer (sleep on < 50% of days)'
        WHEN avg_steps < 7500                              THEN '3 Engaged, low activity (< 7,500 steps/day)'
        ELSE                                                    '4 Engaged and active'
    END                              AS segment,
    COUNT(*)                         AS users,
    ROUND(AVG(avg_steps))            AS avg_steps,
    ROUND(AVG(valid_days), 1)        AS avg_valid_days,
    ROUND(AVG(pct_days_with_sleep), 1) AS avg_pct_days_with_sleep
FROM b02_user_profile
GROUP BY segment
ORDER BY segment;

-- ---------------------------------------------------------------------
-- Export
-- ---------------------------------------------------------------------
COPY profile_raw              TO 'data/processed/00_profile_raw.csv'        (HEADER);
COPY cleaning_log             TO 'data/processed/00_cleaning_log.csv'       (HEADER);
COPY b01_feature_use          TO 'data/processed/01_feature_use.csv'        (HEADER);
COPY b02_user_profile         TO 'data/processed/02_user_profile.csv'       (HEADER);
COPY b03_step_categories      TO 'data/processed/03_step_categories.csv'    (HEADER);
COPY b04_guideline_scorecard  TO 'data/processed/04_guideline_scorecard.csv' (HEADER);
COPY b05_daily_averages       TO 'data/processed/05_daily_averages.csv'     (HEADER);
COPY b06_by_weekday           TO 'data/processed/06_by_weekday.csv'         (HEADER);
COPY b07_by_hour              TO 'data/processed/07_by_hour.csv'            (HEADER);
COPY b08_daily_engagement     TO 'data/processed/08_daily_engagement.csv'   (HEADER);
COPY b09_sleep_summary        TO 'data/processed/09_sleep_summary.csv'      (HEADER);
COPY b10_sleep_onset          TO 'data/processed/10_sleep_onset.csv'        (HEADER);
COPY b11_correlations         TO 'data/processed/11_correlations.csv'       (HEADER);
COPY b12_sedentary_split      TO 'data/processed/12_sedentary_split.csv'    (HEADER);
COPY b13_sleep_habit_groups   TO 'data/processed/13_sleep_habit_groups.csv' (HEADER);
COPY b14_engagement_segments  TO 'data/processed/14_engagement_segments.csv' (HEADER);
COPY daily_clean              TO 'data/processed/daily_clean.csv'           (HEADER);
COPY hourly_clean             TO 'data/processed/hourly_clean.csv'          (HEADER);
