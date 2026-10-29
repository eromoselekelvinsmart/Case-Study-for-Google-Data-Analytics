// AllTrips_Clean
// Author: Eromosele Smart Ochie
// Keeps only rows that passed every rule and adds the columns used in the analysis.
// Expected row count: 783,799. Too big for a comfortable sheet, so
// Load setting: Connection only + Add this data to the Data Model.
let
    Kept = Table.SelectRows(AllTrips_Flagged, each [clean_flag] = "keep"),
    // Divvy marks some stations with "(*)" or "(Temp)" - strip them for display
    CleanStationNames = Table.TransformColumns(Kept, {
        {"start_station_name", each Text.Trim(Text.Replace(Text.Replace(_, "(*)", ""), "(Temp)", "")), type text},
        {"end_station_name", each Text.Trim(Text.Replace(Text.Replace(_, "(*)", ""), "(Temp)", "")), type text}
    }),
    AddedLengthMin = Table.AddColumn(CleanStationNames, "ride_length_min", each Number.Round([ride_length_sec] / 60, 2), type number),
    AddedDate = Table.AddColumn(AddedLengthMin, "ride_date", each DateTime.Date([started_at]), type date),
    AddedYear = Table.AddColumn(AddedDate, "ride_year", each Date.Year([ride_date]), Int64.Type),
    AddedMonth = Table.AddColumn(AddedYear, "ride_month", each Date.Month([ride_date]), Int64.Type),
    AddedMonthLabel = Table.AddColumn(AddedMonth, "month_label",
        each Text.PadStart(Text.From([ride_month]), 2, "0") & " " & Date.ToText([ride_date], "MMM", "en-US"), type text),
    // 1 = Sunday ... 7 = Saturday, the same numbering as =WEEKDAY(date, 1)
    AddedDayOfWeek = Table.AddColumn(AddedMonthLabel, "day_of_week", each Date.DayOfWeek([ride_date], Day.Sunday) + 1, Int64.Type),
    AddedDayLabel = Table.AddColumn(AddedDayOfWeek, "day_label",
        each Text.From([day_of_week]) & " " & Date.ToText([ride_date], "ddd", "en-US"), type text),
    AddedDayType = Table.AddColumn(AddedDayLabel, "day_type",
        each if [day_of_week] = 1 or [day_of_week] = 7 then "Weekend" else "Weekday", type text),
    AddedStartHour = Table.AddColumn(AddedDayType, "start_hour", each Time.Hour([started_at]), Int64.Type),
    AddedRoundTrip = Table.AddColumn(AddedStartHour, "is_round_trip", each [start_station_id] = [end_station_id], type logical),
    ProperRiderType = Table.TransformColumns(AddedRoundTrip, {{"member_casual", Text.Proper, type text}}),
    RemovedHelper = Table.RemoveColumns(ProperRiderType, {"clean_flag"})
in
    RemovedHelper
