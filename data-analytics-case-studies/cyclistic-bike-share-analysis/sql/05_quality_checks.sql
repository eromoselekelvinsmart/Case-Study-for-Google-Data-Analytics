-- =====================================================================
-- Cyclistic case study | 05_quality_checks.sql
-- Author: Eromosele Smart Ochie
--
-- Every check should return PASS. I re-run this after any change.
-- =====================================================================

CREATE OR REPLACE TABLE quality_checks AS
SELECT 'Raw rows = flagged rows (nothing lost when stacking)' AS check_name,
       (SELECT COUNT(*) FROM raw_trips_2019_q1) + (SELECT COUNT(*) FROM raw_trips_2020_q1) AS expected,
       (SELECT COUNT(*) FROM trips_flagged)                                              AS actual
UNION ALL
SELECT 'Kept rows in log = rows in trips_clean',
       (SELECT SUM(rows_affected) FROM cleaning_log WHERE clean_flag = 'keep'),
       (SELECT COUNT(*) FROM trips_clean)
UNION ALL
SELECT 'Hourly fact table sums back to trips_clean',
       (SELECT COUNT(*) FROM trips_clean),
       (SELECT SUM(rides) FROM fact_rides_hourly)
UNION ALL
SELECT 'No duplicate ride IDs',
       0,
       (SELECT COUNT(*) FROM check_duplicates)
UNION ALL
SELECT 'No missing rider type',
       0,
       (SELECT COUNT(*) FROM trips_clean WHERE member_casual IS NULL)
UNION ALL
SELECT 'All rides between 60 seconds and 24 hours',
       0,
       (SELECT COUNT(*) FROM trips_clean WHERE ride_length_sec < 60 OR ride_length_sec > 86400)
UNION ALL
SELECT 'No HQ QR test rides left',
       0,
       (SELECT COUNT(*) FROM trips_clean WHERE start_station_name = 'HQ QR' OR end_station_name = 'HQ QR')
UNION ALL
SELECT 'Every ride falls in Q1',
       0,
       (SELECT COUNT(*) FROM trips_clean WHERE ride_month NOT IN (1, 2, 3));

SELECT check_name, expected, actual,
       CASE WHEN expected = actual THEN 'PASS' ELSE 'FAIL' END AS result
FROM quality_checks;
