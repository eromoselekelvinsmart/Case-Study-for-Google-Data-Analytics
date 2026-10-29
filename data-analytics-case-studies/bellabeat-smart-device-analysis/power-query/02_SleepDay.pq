// SleepDay
// Author: Eromosele Smart Ochie
// sleepDay_merged.csv: 413 rows, 3 exact duplicates -> 410 user-nights, 24 users.
// Load setting: Connection only.
let
    Source = Csv.Document(
        File.Contents(DataFolder & "sleepDay_merged.csv"),
        [Delimiter = ",", Columns = 5, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    RemovedDuplicates = Table.Distinct(PromotedHeaders),
    ChangedTypes = Table.TransformColumnTypes(RemovedDuplicates, {
        {"Id", Int64.Type},
        {"SleepDay", type datetime},
        {"TotalSleepRecords", Int64.Type},
        {"TotalMinutesAsleep", Int64.Type},
        {"TotalTimeInBed", Int64.Type}
    }, "en-US"),
    AddedDate = Table.AddColumn(ChangedTypes, "activity_date", each DateTime.Date([SleepDay]), type date),
    Renamed = Table.RenameColumns(AddedDate, {
        {"Id", "user_id"}, {"TotalSleepRecords", "sleep_records"},
        {"TotalMinutesAsleep", "minutes_asleep"}, {"TotalTimeInBed", "minutes_in_bed"}
    }),
    SelectedColumns = Table.SelectColumns(Renamed, {"user_id", "activity_date", "sleep_records", "minutes_asleep", "minutes_in_bed"})
in
    SelectedColumns
