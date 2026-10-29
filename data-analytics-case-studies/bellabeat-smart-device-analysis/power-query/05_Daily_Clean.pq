// Daily_Clean
// Author: Eromosele Smart Ochie
// Valid user-days only, with the columns used in the analysis.
// Expected: 844 rows, 33 users. Load setting: Table -> sheet "daily_clean" (table name tblDaily).
let
    Valid = Table.SelectRows(Daily_Flagged, each [day_flag] = "valid"),
    // 1 = Sunday ... 7 = Saturday, the same numbering as =WEEKDAY(date, 1)
    AddedDayOfWeek = Table.AddColumn(Valid, "day_of_week", each Date.DayOfWeek([activity_date], Day.Sunday) + 1, Int64.Type),
    AddedDayLabel = Table.AddColumn(AddedDayOfWeek, "day_label",
        each Text.From([day_of_week]) & " " & Date.ToText([activity_date], "ddd", "en-US"), type text),
    AddedDayType = Table.AddColumn(AddedDayLabel, "day_type",
        each if [day_of_week] = 1 or [day_of_week] = 7 then "Weekend" else "Weekday", type text),
    AddedStudyDay = Table.AddColumn(AddedDayType, "study_day",
        each Duration.Days([activity_date] - #date(2016, 4, 12)) + 1, Int64.Type),
    AddedMVPA = Table.AddColumn(AddedStudyDay, "mvpa_min", each [very_active_min] + [fairly_active_min], Int64.Type),
    // CDC: one vigorous minute counts as two moderate minutes
    AddedMVPAEquivalent = Table.AddColumn(AddedMVPA, "mvpa_equivalent_min", each [fairly_active_min] + 2 * [very_active_min], Int64.Type),
    AddedSleepEfficiency = Table.AddColumn(AddedMVPAEquivalent, "sleep_efficiency",
        each if [minutes_in_bed] = null or [minutes_in_bed] = 0 then null else Number.Round([minutes_asleep] / [minutes_in_bed], 3),
        type number),
    Reordered = Table.SelectColumns(AddedSleepEfficiency, {
        "user_id", "activity_date", "study_day", "day_of_week", "day_label", "day_type", "total_steps",
        "total_distance_km", "very_active_min", "fairly_active_min", "lightly_active_min", "sedentary_min",
        "mvpa_min", "mvpa_equivalent_min", "calories", "activity_tracked_min", "has_sleep_record",
        "minutes_asleep", "minutes_in_bed", "sleep_efficiency", "total_tracked_min"
    })
in
    Reordered
