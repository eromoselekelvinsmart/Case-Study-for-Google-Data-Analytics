# Raw data (not committed)

The two Divvy trip files are too large for GitHub, so they are not in the repository. Download and unzip them into this folder:

| File | Download | Rows | SHA-256 of the zip |
|---|---|---|---|
| `Divvy_Trips_2019_Q1.csv` | https://divvy-tripdata.s3.amazonaws.com/Divvy_Trips_2019_Q1.zip | 365,069 | `1f7973129797afd62b75da3ae2075145aa7c18226ef2a2a22892b6c388477d64` |
| `Divvy_Trips_2020_Q1.csv` | https://divvy-tripdata.s3.amazonaws.com/Divvy_Trips_2020_Q1.zip | 426,887 | `6b23117771218d1f11830535bb2544939c7fc3ad27499aff2318e4e72a98da64` |

Index of all Divvy files: https://divvy-tripdata.s3.amazonaws.com/index.html

Check a download with `sha256sum Divvy_Trips_2019_Q1.zip` (macOS: `shasum -a 256`, Windows PowerShell: `Get-FileHash`).

The data is provided by Motivate International Inc. under the Divvy Data License Agreement (https://divvybikes.com/data-license-agreement). The files are never edited; every change happens in `power-query/` or `sql/`.
