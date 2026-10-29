// Daily_Flagged
// Author: Eromosele Smart Ochie
// Attaches last night's sleep to each day and tags every user-day with the first rule it breaks.
// Same rules, same order as sql/02_clean.sql.
// Load setting: Connection only.
let
    JoinedSleep = Table.NestedJoin(DailyActivity, {"user_id", "activity_date"}, SleepDay, {"user_id", "activity_date"}, "sleep", JoinKind.LeftOuter),
    ExpandedSleep = Table.ExpandTableColumn(JoinedSleep, "sleep", {"minutes_asleep", "minutes_in_bed"}),
    AddedHasSleep = Table.AddColumn(ExpandedSleep, "has_sleep_record", each [minutes_asleep] <> null, type logical),
    // Fitbit stops counting activity minutes while you sleep, so tracked time = activity minutes + minutes asleep
    AddedTotalTracked = Table.AddColumn(AddedHasSleep, "total_tracked_min",
        each [activity_tracked_min] + (if [minutes_asleep] = null then 0 else [minutes_asleep]), Int64.Type),
    AddedDayFlag = Table.AddColumn(AddedTotalTracked, "day_flag", each
        if [activity_date] = #date(2016, 5, 12) then "D1_export_cutoff_day"
        else if [total_steps] = 0 then "D2_not_worn"
        else if [total_tracked_min] < 600 then "D3_under_10h_tracked"
        else "valid",
        type text)
in
    AddedDayFlag
