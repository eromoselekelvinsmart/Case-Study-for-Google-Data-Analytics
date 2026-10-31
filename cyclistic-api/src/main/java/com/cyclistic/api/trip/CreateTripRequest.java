package com.cyclistic.api.trip;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

/** Request body for POST /api/v1/trips. Field rules are enforced by Bean Validation. */
public record CreateTripRequest(
        @NotBlank @Size(max = 32) String rideId,
        @NotBlank @Size(max = 32) String rideableType,
        @NotNull LocalDateTime startedAt,
        @NotNull LocalDateTime endedAt,
        @Size(max = 255) String startStationName,
        @Size(max = 255) String endStationName,
        @NotNull MemberType memberType) {
}
