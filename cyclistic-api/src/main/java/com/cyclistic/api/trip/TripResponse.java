package com.cyclistic.api.trip;

import java.time.LocalDateTime;

/** API representation of a trip. Keeps the JPA entity out of the HTTP contract. */
public record TripResponse(
        String rideId,
        String rideableType,
        LocalDateTime startedAt,
        LocalDateTime endedAt,
        String startStationName,
        String endStationName,
        MemberType memberType,
        double rideMinutes) {

    public static TripResponse from(Trip trip) {
        return new TripResponse(
                trip.getRideId(),
                trip.getRideableType(),
                trip.getStartedAt(),
                trip.getEndedAt(),
                trip.getStartStationName(),
                trip.getEndStationName(),
                trip.getMemberType(),
                Math.round(trip.getDurationSeconds() / 60.0 * 100.0) / 100.0);
    }
}
