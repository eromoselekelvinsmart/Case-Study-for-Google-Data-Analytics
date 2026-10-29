# Data Analytics Case Studies

**Eromosele Smart Ochie**

Two end-to-end case studies from the Google Data Analytics Professional Certificate capstone. Each one follows the full analysis process (Ask, Prepare, Process, Analyze, Share, Act) and ends with a written report and recommendations.

| Project | Question | Data | Tools |
|---|---|---|---|
| [Cyclistic bike-share](cyclistic-bike-share-analysis/) | How do annual members and casual riders use the bikes differently, and how can marketing convert casual riders? | Divvy trip data, Q1 2019 + Q1 2020 (783,799 cleaned rides) | Excel (Power Query, pivot tables), SQL, Visio |
| [Bellabeat smart devices](bellabeat-smart-device-analysis/) | What do Fitbit users' habits mean for marketing Bellabeat Leaf? | FitBit Fitness Tracker Data (33 users, 844 valid days) + public-health benchmarks | Excel (Power Query, pivot tables), SQL, Visio |

## How each project is organised

```
<project>/
├── report/        Word report (start here)
├── excel/         Workbook: dashboard, analysis formulas, pivot tables, cleaning log, business rules
├── sql/           DuckDB scripts: load -> clean -> analyse -> quality checks (run_all.sql runs everything)
├── power-query/   The same cleaning steps in Excel Power Query (M), one file per query
├── visio/         Data-flow and business-rule diagrams (.vsdx + PNG exports)
├── visuals/       Charts exported from the workbook
└── data/          raw/ (source files or download links), processed/ (SQL outputs), reference/
```

## Running the SQL

Both projects use [DuckDB](https://duckdb.org/docs/installation/), which reads the CSV files directly; no database server is needed. From inside a project folder:

```bash
duckdb analysis.duckdb -c ".read sql/run_all.sql"
```

The last script prints a list of quality checks; every line should say `PASS`.

## Licences

Code and documents in this repository: MIT (see [LICENSE](LICENSE)). Divvy trip data is provided by Motivate International Inc. under the Divvy Data License Agreement and is not redistributed here. The FitBit Fitness Tracker Data set is public domain (CC0). Cyclistic and Bellabeat are the scenarios used in the Google Data Analytics case studies.
