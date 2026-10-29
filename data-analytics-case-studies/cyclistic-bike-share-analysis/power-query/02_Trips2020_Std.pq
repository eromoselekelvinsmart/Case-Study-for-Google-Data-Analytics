// Trips2020_Std
// Author: Eromosele Smart Ochie
// Loads Divvy_Trips_2020_Q1.csv (already in the target layout).
// Load setting: Connection only.
let
    Source = Csv.Document(
        File.Contents(DataFolder & "Divvy_Trips_2020_Q1.csv"),
        [Delimiter = ",", Columns = 13, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    BlanksToNull = Table.ReplaceValue(PromotedHeaders, "", null, Replacer.ReplaceValue, Table.ColumnNames(PromotedHeaders)),
    AddedSourceYear = Table.AddColumn(BlanksToNull, "source_year", each 2020, Int64.Type),
    // latitude / longitude are not needed for this question
    SelectedColumns = Table.SelectColumns(AddedSourceYear, {
        "ride_id", "rideable_type", "started_at", "ended_at",
        "start_station_id", "start_station_name", "end_station_id", "end_station_name",
        "member_casual", "source_year"
    }),
    ChangedTypes = Table.TransformColumnTypes(SelectedColumns, {
        {"ride_id", type text},
        {"rideable_type", type text},
        {"started_at", type datetime},
        {"ended_at", type datetime},
        {"start_station_id", Int64.Type},
        {"end_station_id", Int64.Type},
        {"start_station_name", type text},
        {"end_station_name", type text},
        {"member_casual", type text}
    }, "en-US"),
    TrimmedNames = Table.TransformColumns(ChangedTypes, {
        {"start_station_name", Text.Trim, type text},
        {"end_station_name", Text.Trim, type text}
    })
in
    TrimmedNames
