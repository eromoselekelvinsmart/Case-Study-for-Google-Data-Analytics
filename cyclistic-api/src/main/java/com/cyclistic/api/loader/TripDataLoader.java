package com.cyclistic.api.loader;

import com.cyclistic.api.trip.Trip;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

/**
 * Loads trip CSVs at startup. {@code cyclistic.data.location} may be a classpath resource,
 * a single CSV file, or a folder of monthly CSVs (e.g. the 12 Divvy files for the case study).
 * Uses JDBC batch inserts so ~800K rows load in seconds rather than minutes.
 */
@Component
@ConditionalOnProperty(name = "cyclistic.data.load", havingValue = "true", matchIfMissing = true)
public class TripDataLoader implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(TripDataLoader.class);

    private static final String INSERT_SQL = """
            INSERT INTO trips (ride_id, rideable_type, started_at, ended_at, start_station_name,
                               end_station_name, member_type, duration_seconds, start_weekday)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """;

    private final JdbcTemplate jdbc;
    private final ResourceLoader resourceLoader;
    private final String location;
    private final int batchSize;

    public TripDataLoader(JdbcTemplate jdbc, ResourceLoader resourceLoader,
                          @Value("${cyclistic.data.location}") String location,
                          @Value("${cyclistic.data.batch-size:5000}") int batchSize) {
        this.jdbc = jdbc;
        this.resourceLoader = resourceLoader;
        this.location = location;
        this.batchSize = batchSize;
    }

    @Override
    public void run(ApplicationArguments args) throws IOException {
        long start = System.currentTimeMillis();
        TripCsvParser parser = new TripCsvParser();
        LoadReport report = new LoadReport();
        List<Trip> buffer = new ArrayList<>(batchSize);

        for (Resource resource : resolve(location)) {
            log.info("Loading trips from {}", resource.getDescription());
            try (Reader reader = new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8)) {
                parser.parse(reader, trip -> {
                    buffer.add(trip);
                    if (buffer.size() >= batchSize) {
                        flush(buffer);
                    }
                }, report);
            }
        }
        flush(buffer);

        log.info("Trip load finished in {} ms: {}", System.currentTimeMillis() - start, report);
        if (!report.reconciles()) {
            throw new IllegalStateException("Row counts do not reconcile: " + report);
        }
    }

    private void flush(List<Trip> buffer) {
        if (buffer.isEmpty()) {
            return;
        }
        jdbc.batchUpdate(INSERT_SQL, buffer, buffer.size(), (ps, t) -> {
            ps.setString(1, t.getRideId());
            ps.setString(2, t.getRideableType());
            ps.setTimestamp(3, Timestamp.valueOf(t.getStartedAt()));
            ps.setTimestamp(4, Timestamp.valueOf(t.getEndedAt()));
            ps.setString(5, t.getStartStationName());
            ps.setString(6, t.getEndStationName());
            ps.setString(7, t.getMemberType().name());
            ps.setLong(8, t.getDurationSeconds());
            ps.setInt(9, t.getDayOfWeek());
        });
        buffer.clear();
    }

    /** A classpath:/file: resource, a CSV file path, or a directory of CSVs (sorted by name). */
    private List<Resource> resolve(String location) throws IOException {
        if (!location.startsWith("classpath:")) {
            Path path = Path.of(location.replaceFirst("^file:", ""));
            if (Files.isDirectory(path)) {
                try (Stream<Path> files = Files.list(path)) {
                    List<Resource> csvs = files
                            .filter(p -> p.getFileName().toString().toLowerCase().endsWith(".csv"))
                            .sorted()
                            .map(p -> resourceLoader.getResource("file:" + p.toAbsolutePath()))
                            .toList();
                    if (csvs.isEmpty()) {
                        throw new IllegalArgumentException("No .csv files found in " + path);
                    }
                    return csvs;
                }
            }
            return List.of(resourceLoader.getResource("file:" + path.toAbsolutePath()));
        }
        return List.of(resourceLoader.getResource(location));
    }
}
