package com.cyclistic.api.loader;

import com.cyclistic.api.trip.MemberType;
import com.cyclistic.api.trip.Trip;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.StringReader;
import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class TripCsvParserTest {

    private static final String HEADER =
            "ride_id,rideable_type,started_at,ended_at,start_station_name,end_station_name,member_casual\n";

    private final List<Trip> loaded = new ArrayList<>();
    private final LoadReport report = new LoadReport();

    private void parse(String rows) throws IOException {
        new TripCsvParser().parse(new StringReader(HEADER + rows), loaded::add, report);
    }

    @Test
    void loadsValidRowAndDerivesDurationAndWeekday() throws IOException {
        parse("A1,classic_bike,2024-03-01 08:00:00,2024-03-01 08:15:30,Clark St & Elm St,Millennium Park,member\n");

        assertThat(loaded).hasSize(1);
        Trip trip = loaded.get(0);
        assertThat(trip.getMemberType()).isEqualTo(MemberType.MEMBER);
        assertThat(trip.getDurationSeconds()).isEqualTo(930);
        assertThat(trip.getDayOfWeek()).isEqualTo(DayOfWeek.FRIDAY.getValue());
        assertThat(report.reconciles()).isTrue();
    }

    @Test
    void blankStationBecomesNull() throws IOException {
        parse("A1,electric_bike,2024-03-01 08:00:00,2024-03-01 08:10:00,,,casual\n");

        assertThat(loaded.get(0).getStartStationName()).isNull();
    }

    @Test
    void skipsDuplicateRideIds() throws IOException {
        parse("""
                A1,classic_bike,2024-03-01 08:00:00,2024-03-01 08:10:00,,,member
                A1,classic_bike,2024-03-02 08:00:00,2024-03-02 08:10:00,,,member
                """);

        assertThat(loaded).hasSize(1);
        assertThat(report.skippedByReason()).containsEntry("duplicate ride_id", 1L);
    }

    @Test
    void skipsRidesThatEndBeforeTheyStart() throws IOException {
        parse("A1,classic_bike,2024-03-01 09:00:00,2024-03-01 08:00:00,,,member\n");

        assertThat(loaded).isEmpty();
        assertThat(report.skippedByReason()).containsEntry("endedAt must be after startedAt", 1L);
    }

    @Test
    void skipsRidesShorterThanOneMinuteOrLongerThanOneDay() throws IOException {
        parse("""
                A1,classic_bike,2024-03-01 08:00:00,2024-03-01 08:00:30,,,member
                A2,classic_bike,2024-03-01 08:00:00,2024-03-02 08:00:01,,,member
                """);

        assertThat(loaded).isEmpty();
        assertThat(report.rowsSkipped()).isEqualTo(2);
    }

    @Test
    void skipsUnknownMemberTypeAndBadTimestamps() throws IOException {
        parse("""
                A1,classic_bike,2024-03-01 08:00:00,2024-03-01 08:10:00,,,tourist
                A2,classic_bike,not-a-date,2024-03-01 08:10:00,,,member
                """);

        assertThat(loaded).isEmpty();
        assertThat(report.skippedByReason())
                .containsEntry("unknown member_casual", 1L)
                .containsEntry("unparseable timestamp", 1L);
    }

    @Test
    void everyRowIsEitherLoadedOrSkipped() throws IOException {
        parse("""
                A1,classic_bike,2024-03-01 08:00:00,2024-03-01 08:10:00,,,member
                A1,classic_bike,2024-03-01 08:00:00,2024-03-01 08:10:00,,,member
                A3,classic_bike,2024-03-01 08:00:00,2024-03-01 08:10:00,,,casual
                """);

        assertThat(report.rowsRead()).isEqualTo(3);
        assertThat(report.rowsLoaded()).isEqualTo(2);
        assertThat(report.reconciles()).isTrue();
    }

    @Test
    void rejectsFilesMissingRequiredColumns() {
        String csv = "ride_id,started_at\nA1,2024-03-01 08:00:00\n";

        assertThatThrownBy(() -> new TripCsvParser().parse(new StringReader(csv), loaded::add, report))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("rideable_type");
    }

    @Test
    void parsesDivvyAndIsoTimestamps() {
        LocalDateTime expected = LocalDateTime.of(2024, 3, 1, 8, 5, 42);

        assertThat(TripCsvParser.parseTime("2024-03-01 08:05:42")).isEqualTo(expected);
        assertThat(TripCsvParser.parseTime("2024-03-01T08:05:42")).isEqualTo(expected);
        assertThat(TripCsvParser.parseTime("2024-03-01 08:05:42.000")).isEqualTo(expected);
    }
}
