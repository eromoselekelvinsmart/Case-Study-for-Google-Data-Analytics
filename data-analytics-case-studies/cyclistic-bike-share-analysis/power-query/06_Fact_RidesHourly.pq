// Fact_RidesHourly
// Author: Eromosele Smart Ochie
// One row per date x start hour x rider type. This is the table behind every
// pivot table and SUMIFS formula in excel/Cyclistic_Rider_Analysis.xlsx.
// Expected: 7,854 rows; SUM(rides) = 783,799.
// Load setting: Table -> sheet "fact_rides_hourly" (table name tblRidesHourly).
let
    Grouped = Table.Group(AllTrips_Clean,
        {"ride_date", "ride_year", "ride_month", "month_label", "day_of_week", "day_label", "day_type", "start_hour", "member_casual"},
        {
            {"rides", each Table.RowCount(_), Int64.Type},
            {"total_ride_min", each List.Sum([ride_length_min]), type number},
            {"round_trips", each List.Count(List.Select([is_round_trip], each _ = true)), Int64.Type},
            {"rides_over_30_min", each List.Count(List.Select([ride_length_min], each _ > 30)), Int64.Type}
        }),
    Sorted = Table.Sort(Grouped, {{"ride_date", Order.Ascending}, {"start_hour", Order.Ascending}, {"member_casual", Order.Ascending}})
in
    Sorted
