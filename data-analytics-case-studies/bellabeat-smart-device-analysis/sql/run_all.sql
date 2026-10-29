-- Run the whole pipeline with the DuckDB CLI from the project folder:
--   duckdb bellabeat.duckdb -c ".read sql/run_all.sql"
.read sql/01_load_raw.sql
.read sql/02_clean.sql
.read sql/03_analysis.sql
.read sql/04_quality_checks.sql
