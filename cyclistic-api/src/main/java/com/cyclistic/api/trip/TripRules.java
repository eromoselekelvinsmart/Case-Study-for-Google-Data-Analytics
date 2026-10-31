package com.cyclistic.api.trip;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * Business rules for a valid trip, shared by the CSV loader and the POST endpoint
 * so data from both paths is cleaned the same way.
 */
public final class TripRules {

    /** Rides longer than this are treated as unreturned or faulty bikes. */
    public static final Duration MAX_RIDE_LENGTH = Duration.ofHours(24);

    /** Rides shorter than this are treated as false starts or re-docks. */
    public static final Duration MIN_RIDE_LENGTH = Duration.ofSeconds(60);

    private TripRules() {
    }

    /** Returns null when the times are valid, otherwise a human-readable reason. */
    public static String validateTimes(LocalDateTime startedAt, LocalDateTime endedAt) {
        if (startedAt == null || endedAt == null) {
            return "startedAt and endedAt are required";
        }
        if (!endedAt.isAfter(startedAt)) {
            return "endedAt must be after startedAt";
        }
        Duration length = Duration.between(startedAt, endedAt);
        if (length.compareTo(MIN_RIDE_LENGTH) < 0) {
            return "ride must last at least " + MIN_RIDE_LENGTH.toSeconds() + " seconds";
        }
        if (length.compareTo(MAX_RIDE_LENGTH) > 0) {
            return "ride must not exceed " + MAX_RIDE_LENGTH.toHours() + " hours";
        }
        return null;
    }
}
