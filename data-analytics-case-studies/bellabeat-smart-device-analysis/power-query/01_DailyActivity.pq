// DailyActivity
// Author: Eromosele Smart Ochie
// dailyActivity_merged.csv: one row per user per day (940 rows, 33 users).
// dailySteps / dailyCalories / dailyIntensities are exact subsets of this file, so they are not loaded.
// Load setting: Connection only.
let
    Source = Csv.Document(
        File.Contents(DataFolder & "dailyActivity_merged.csv"),
        [Delimiter = ",", Columns = 15, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    // ActivityDate is text like 4/12/2016 - the en-US culture reads it as month/day/year
    ChangedTypes = Table.TransformColumnTypes(PromotedHeaders, {
        {"Id", Int64.Type},
        {"ActivityDate", type date},
        {"TotalSteps", Int64.Type},
        {"TotalDistance", type number},
        {"VeryActiveMinutes", Int64.Type},
        {"FairlyActiveMinutes", Int64.Type},
        {"LightlyActiveMinutes", Int64.Type},
        {"SedentaryMinutes", Int64.Type},
        {"Calories", Int64.Type}
    }, "en-US"),
    SelectedColumns = Table.SelectColumns(ChangedTypes, {
        "Id", "ActivityDate", "TotalSteps", "TotalDistance", "VeryActiveMinutes",
        "FairlyActiveMinutes", "LightlyActiveMinutes", "SedentaryMinutes", "Calories"
    }),
    Renamed = Table.RenameColumns(SelectedColumns, {
        {"Id", "user_id"}, {"ActivityDate", "activity_date"}, {"TotalSteps", "total_steps"},
        {"TotalDistance", "total_distance_km"}, {"VeryActiveMinutes", "very_active_min"},
        {"FairlyActiveMinutes", "fairly_active_min"}, {"LightlyActiveMinutes", "lightly_active_min"},
        {"SedentaryMinutes", "sedentary_min"}, {"Calories", "calories"}
    }),
    RoundedDistance = Table.TransformColumns(Renamed, {{"total_distance_km", each Number.Round(_, 2), type number}}),
    AddedTrackedMinutes = Table.AddColumn(RoundedDistance, "activity_tracked_min",
        each [very_active_min] + [fairly_active_min] + [lightly_active_min] + [sedentary_min], Int64.Type)
in
    AddedTrackedMinutes
