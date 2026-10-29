// Trips2019_Std
// Author: Eromosele Smart Ochie
// Loads Divvy_Trips_2019_Q1.csv and maps it onto the 2020 column layout.
// Load setting: Connection only.
let
    Source = Csv.Document(
        File.Contents(DataFolder & "Divvy_Trips_2019_Q1.csv"),
        [Delimiter = ",", Columns = 12, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    BlanksToNull = Table.ReplaceValue(PromotedHeaders, "", null, Replacer.ReplaceValue, Table.ColumnNames(PromotedHeaders)),
    RenamedTo2020 = Table.RenameColumns(BlanksToNull, {
        {"trip_id", "ride_id"},
        {"start_time", "started_at"},
        {"end_time", "ended_at"},
        {"from_station_id", "start_station_id"},
        {"from_station_name", "start_station_name"},
        {"to_station_id", "end_station_id"},
        {"to_station_name", "end_station_name"},
        {"usertype", "member_casual"}
    }),
    RiderLabels = Table.TransformColumns(RenamedTo2020, {
        {"member_casual", each if _ = "Subscriber" then "member" else if _ = "Customer" then "casual" else _, type text}
    }),
    // 2019 only had docked bikes; the file has bike IDs, not bike types
    AddedBikeType = Table.AddColumn(RiderLabels, "rideable_type", each "docked_bike", type text),
    AddedSourceYear = Table.AddColumn(AddedBikeType, "source_year", each 2019, Int64.Type),
    // tripduration, bikeid, gender and birthyear are dropped: ride length is recalculated from the timestamps
    SelectedColumns = Table.SelectColumns(AddedSourceYear, {
        "ride_id", "rideable_type", "started_at", "ended_at",
        "start_station_id", "start_station_name", "end_station_id", "end_station_name",
        "member_casual", "source_year"
    }),
    ChangedTypes = Table.TransformColumnTypes(SelectedColumns, {
        {"ride_id", type text},
        {"started_at", type datetime},
        {"ended_at", type datetime},
        {"start_station_id", Int64.Type},
        {"end_station_id", Int64.Type},
        {"start_station_name", type text},
        {"end_station_name", type text}
    }, "en-US"),
    TrimmedNames = Table.TransformColumns(ChangedTypes, {
        {"start_station_name", Text.Trim, type text},
        {"end_station_name", Text.Trim, type text}
    })
in
    TrimmedNames
