// CleaningLog
// Author: Eromosele Smart Ochie
// Rows per rule per year. Expected (matches sql/03_clean.sql):
//   2019: keep 364,877 | R5 192
//   2020: keep 418,922 | R1 3,768 | R4 3,908 | R5 289
// Load setting: Table on a new sheet.
let
    Grouped = Table.Group(AllTrips_Flagged, {"source_year", "clean_flag"},
        {{"rows_affected", each Table.RowCount(_), Int64.Type}}),
    Sorted = Table.Sort(Grouped, {{"source_year", Order.Ascending}, {"clean_flag", Order.Ascending}})
in
    Sorted
