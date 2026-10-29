// Guidelines
// Author: Eromosele Smart Ochie
// The extra data source: public-health benchmarks (CDC, AASM/SRS, Tudor-Locke & Bassett, Paluch et al.).
// File lives in data/reference/, one folder up from DataFolder.
// Load setting: Table -> sheet "Guidelines".
let
    Source = Csv.Document(
        File.Contents(DataFolder & "..\reference\health_guidelines.csv"),
        [Delimiter = ",", Columns = 7, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    ChangedTypes = Table.TransformColumnTypes(PromotedHeaders, {
        {"lower_bound", Int64.Type}, {"upper_bound", Int64.Type}
    }, "en-US")
in
    ChangedTypes
