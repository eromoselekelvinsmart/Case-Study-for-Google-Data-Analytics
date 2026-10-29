// AllTrips_Flagged
// Author: Eromosele Smart Ochie
// Stacks both quarters and tags every row with the first cleaning rule it breaks.
// Same rules, same order as sql/03_clean.sql. Nothing is deleted here.
// Load setting: Connection only.
let
    Combined = Table.Combine({Trips2019_Std, Trips2020_Std}),
    AddedLengthSec = Table.AddColumn(Combined, "ride_length_sec",
        each if [started_at] = null or [ended_at] = null then null
             else Duration.TotalSeconds([ended_at] - [started_at]),
        type number),
    AddedCleanFlag = Table.AddColumn(AddedLengthSec, "clean_flag", each
        if [start_station_name] = "HQ QR" or [end_station_name] = "HQ QR" then "R1_hq_test_ride"
        else if [ended_at] = null or [end_station_id] = null then "R2_missing_end"
        else if [ride_length_sec] <= 0 then "R3_non_positive_length"
        else if [ride_length_sec] < 60 then "R4_under_60_seconds"
        else if [ride_length_sec] > 86400 then "R5_over_24_hours"
        else "keep",
        type text)
in
    AddedCleanFlag
