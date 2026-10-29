-- Run the whole pipeline with the DuckDB CLI from the project folder:
--   duckdb cyclistic.duckdb -c ".read sql/run_all.sql"
.read sql/01_load_raw.sql
.read sql/02_standardize.sql
.read sql/03_clean.sql
.read sql/04_analysis.sql
.read sql/05_quality_checks.sql
