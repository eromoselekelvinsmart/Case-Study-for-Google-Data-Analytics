-- =====================================================================
-- Bellabeat case study | 04_quality_checks.sql
-- Author: Eromosele Smart Ochie
-- Every check should return PASS.
-- =====================================================================

CREATE OR REPLACE TABLE quality_checks AS
SELECT 'Every raw daily row was flagged (none lost)' AS check_name,
       (SELECT COUNT(*) FROM raw_daily_activity) AS expected,
       (SELECT COUNT(*) FROM daily_flagged)      AS actual
UNION ALL
SELECT 'Valid days in log = rows in daily_clean',
       (SELECT user_days FROM cleaning_log WHERE day_flag = 'valid'),
       (SELECT COUNT(*) FROM daily_clean)
UNION ALL
SELECT 'One row per user per day',
       (SELECT COUNT(*) FROM daily_clean),
       (SELECT COUNT(*) FROM (SELECT DISTINCT user_id, activity_date FROM daily_clean))
UNION ALL
SELECT 'One sleep row per user per night',
       (SELECT COUNT(*) FROM sleep_day),
       (SELECT COUNT(*) FROM (SELECT DISTINCT user_id, activity_date FROM sleep_day))
UNION ALL
SELECT 'No zero-step days left',
       0,
       (SELECT COUNT(*) FROM daily_clean WHERE total_steps = 0)
UNION ALL
SELECT 'Minutes asleep never exceed time in bed',
       0,
       (SELECT COUNT(*) FROM daily_clean WHERE minutes_asleep > minutes_in_bed)
UNION ALL
SELECT 'Hourly rows only from valid days',
       0,
       (SELECT COUNT(*) FROM hourly_clean h
         WHERE NOT EXISTS (SELECT 1 FROM daily_clean d
                            WHERE d.user_id = h.user_id AND d.activity_date = h.activity_date))
UNION ALL
-- Fitbit's daily total and the sum of its hourly steps do not always agree exactly
-- (sync timing, logged activities). I accept the data if 95%+ of days agree within 5%.
SELECT 'At least 95% of days: hourly steps sum to daily total within 5%',
       1,
       (SELECT CASE WHEN AVG(CASE WHEN ABS(h.s - d.total_steps) <= 0.05 * d.total_steps THEN 1.0 ELSE 0 END) >= 0.95
                    THEN 1 ELSE 0 END
          FROM daily_clean d
          JOIN (SELECT user_id, activity_date, SUM(steps) AS s FROM hourly_clean GROUP BY ALL) h
            USING (user_id, activity_date));

SELECT check_name, expected, actual,
       CASE WHEN expected = actual THEN 'PASS' ELSE 'FAIL' END AS result
FROM quality_checks;
