package com.cyclistic.api.loader;

import com.cyclistic.api.trip.MemberType;
import com.cyclistic.api.trip.Trip;
import com.cyclistic.api.trip.TripRules;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;

import java.io.IOException;
import java.io.Reader;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.HashSet;
import java.util.Set;
import java.util.function.Consumer;

/**
 * Parses and cleans Divvy/Cyclistic trip CSVs. Pure Java (no Spring) so the cleaning rules
 * can be unit tested directly. Rows that fail a rule are counted in {@link LoadReport}, not loaded.
 */
public class TripCsvParser {

    static final String[] REQUIRED_COLUMNS = {
            "ride_id", "rideable_type", "started_at", "ended_at",
            "start_station_name", "end_station_name", "member_casual"
    };

    private static final DateTimeFormatter DIVVY_TIME = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final Set<String> seenRideIds = new HashSet<>();

    /** Reads every row from {@code reader}, passing each valid trip to {@code sink}. */
    public void parse(Reader reader, Consumer<Trip> sink, LoadReport report) throws IOException {
        CSVFormat format = CSVFormat.DEFAULT.builder()
                .setHeader()
                .setSkipHeaderRecord(true)
                .setIgnoreSurroundingSpaces(true)
                .build();

        try (CSVParser parser = format.parse(reader)) {
            for (String column : REQUIRED_COLUMNS) {
                if (!parser.getHeaderMap().containsKey(column)) {
                    throw new IllegalArgumentException("CSV is missing required column: " + column);
                }
            }
            for (CSVRecord row : parser) {
                report.rowRead();
                Trip trip = toTrip(row, report);
                if (trip != null) {
                    sink.accept(trip);
                    report.rowLoaded();
                }
            }
        }
    }

    private Trip toTrip(CSVRecord row, LoadReport report) {
        if (!row.isConsistent()) {
            report.skip("malformed row");
            return null;
        }
        String rideId = blankToNull(row.get("ride_id"));
        if (rideId == null) {
            report.skip("missing ride_id");
            return null;
        }
        if (!seenRideIds.add(rideId)) {
            report.skip("duplicate ride_id");
            return null;
        }
        MemberType memberType = MemberType.fromCsv(row.get("member_casual"));
        if (memberType == null) {
            report.skip("unknown member_casual");
            return null;
        }
        String rideableType = blankToNull(row.get("rideable_type"));
        if (rideableType == null) {
            report.skip("missing rideable_type");
            return null;
        }

        LocalDateTime startedAt;
        LocalDateTime endedAt;
        try {
            startedAt = parseTime(row.get("started_at"));
            endedAt = parseTime(row.get("ended_at"));
        } catch (DateTimeParseException ex) {
            report.skip("unparseable timestamp");
            return null;
        }

        String problem = TripRules.validateTimes(startedAt, endedAt);
        if (problem != null) {
            report.skip(problem);
            return null;
        }

        return new Trip(rideId, rideableType, startedAt, endedAt,
                blankToNull(row.get("start_station_name")),
                blankToNull(row.get("end_station_name")),
                memberType);
    }

    /** Accepts "2023-01-21 20:05:42" (Divvy) or ISO "2023-01-21T20:05:42". */
    static LocalDateTime parseTime(String value) {
        if (value == null || value.isBlank()) {
            throw new DateTimeParseException("blank timestamp", String.valueOf(value), 0);
        }
        String trimmed = value.trim();
        // Some exports include fractional seconds ("20:05:42.000"); drop them.
        int dot = trimmed.indexOf('.');
        if (dot > 0) {
            trimmed = trimmed.substring(0, dot);
        }
        return trimmed.contains("T") ? LocalDateTime.parse(trimmed) : LocalDateTime.parse(trimmed, DIVVY_TIME);
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
