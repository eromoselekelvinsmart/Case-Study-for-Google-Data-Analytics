// Hourly_Clean
// Author: Eromosele Smart Ochie
// hourlySteps + hourlyIntensities + hourlyCalories (22,099 rows each), joined on user + hour,
// then limited to valid days. Expected: 20,177 rows.
// Load setting: Table -> sheet "hourly_clean" (table name tblHourly).
let
    LoadCsv = (fileName as text) as table =>
        let
            Src = Csv.Document(File.Contents(DataFolder & fileName), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
            Promoted = Table.PromoteHeaders(Src, [PromoteAllScalars = true])
        in
            Promoted,
    Steps = LoadCsv("hourlySteps_merged.csv"),
    Intensities = LoadCsv("hourlyIntensities_merged.csv"),
    Calories = LoadCsv("hourlyCalories_merged.csv"),
    JoinedIntensity = Table.NestedJoin(Steps, {"Id", "ActivityHour"}, Intensities, {"Id", "ActivityHour"}, "i", JoinKind.Inner),
    ExpandedIntensity = Table.ExpandTableColumn(JoinedIntensity, "i", {"TotalIntensity"}),
    JoinedCalories = Table.NestedJoin(ExpandedIntensity, {"Id", "ActivityHour"}, Calories, {"Id", "ActivityHour"}, "c", JoinKind.Inner),
    ExpandedCalories = Table.ExpandTableColumn(JoinedCalories, "c", {"Calories"}),
    ChangedTypes = Table.TransformColumnTypes(ExpandedCalories, {
        {"Id", Int64.Type}, {"ActivityHour", type datetime}, {"StepTotal", Int64.Type},
        {"TotalIntensity", Int64.Type}, {"Calories", Int64.Type}
    }, "en-US"),
    Renamed = Table.RenameColumns(ChangedTypes, {
        {"Id", "user_id"}, {"ActivityHour", "activity_hour"}, {"StepTotal", "steps"},
        {"TotalIntensity", "total_intensity"}, {"Calories", "calories"}
    }),
    AddedDate = Table.AddColumn(Renamed, "activity_date", each DateTime.Date([activity_hour]), type date),
    AddedHour = Table.AddColumn(AddedDate, "hour_of_day", each Time.Hour([activity_hour]), Int64.Type),
    // keep only hours that belong to a valid day
    ValidDays = Table.SelectColumns(Daily_Clean, {"user_id", "activity_date", "day_of_week", "day_type"}),
    JoinedValidDays = Table.NestedJoin(AddedHour, {"user_id", "activity_date"}, ValidDays, {"user_id", "activity_date"}, "d", JoinKind.Inner),
    ExpandedValidDays = Table.ExpandTableColumn(JoinedValidDays, "d", {"day_of_week", "day_type"}),
    AddedDayName = Table.AddColumn(ExpandedValidDays, "day_name", each Date.ToText([activity_date], "dddd", "en-US"), type text),
    Reordered = Table.SelectColumns(AddedDayName, {
        "user_id", "activity_hour", "activity_date", "hour_of_day", "day_of_week", "day_name",
        "day_type", "steps", "total_intensity", "calories"
    })
in
    Reordered
