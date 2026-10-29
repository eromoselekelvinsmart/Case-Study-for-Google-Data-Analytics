// CleaningLog
// Author: Eromosele Smart Ochie
// Expected: D1 21 | D2 73 | D3 2 | valid 844  (total 940)
// Load setting: Table on a new sheet.
let
    Grouped = Table.Group(Daily_Flagged, {"day_flag"}, {
        {"user_days", each Table.RowCount(_), Int64.Type},
        {"users", each List.Count(List.Distinct([user_id])), Int64.Type}
    }),
    Sorted = Table.Sort(Grouped, {{"day_flag", Order.Ascending}})
in
    Sorted
