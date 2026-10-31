package com.cyclistic.api.trip;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * One bike-share trip. Duration and day of week are derived once at creation time,
 * so statistics queries stay simple and database-agnostic.
 */
@Entity
@Table(name = "trips")
public class Trip {

    @Id
    @Column(length = 32)
    private String rideId;

    @Column(nullable = false, length = 32)
    private String rideableType;

    @Column(nullable = false)
    private LocalDateTime startedAt;

    @Column(nullable = false)
    private LocalDateTime endedAt;

    private String startStationName;

    private String endStationName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private MemberType memberType;

    /** Ride length in seconds (endedAt - startedAt). */
    @Column(nullable = false)
    private long durationSeconds;

    /** ISO day of week: 1 = Monday ... 7 = Sunday. */
    @Column(name = "start_weekday", nullable = false)
    private int dayOfWeek;

    protected Trip() {
        // required by JPA
    }

    public Trip(String rideId, String rideableType, LocalDateTime startedAt, LocalDateTime endedAt,
                String startStationName, String endStationName, MemberType memberType) {
        this.rideId = rideId;
        this.rideableType = rideableType;
        this.startedAt = startedAt;
        this.endedAt = endedAt;
        this.startStationName = startStationName;
        this.endStationName = endStationName;
        this.memberType = memberType;
        this.durationSeconds = Duration.between(startedAt, endedAt).getSeconds();
        this.dayOfWeek = startedAt.getDayOfWeek().getValue();
    }

    public String getRideId() { return rideId; }
    public String getRideableType() { return rideableType; }
    public LocalDateTime getStartedAt() { return startedAt; }
    public LocalDateTime getEndedAt() { return endedAt; }
    public String getStartStationName() { return startStationName; }
    public String getEndStationName() { return endStationName; }
    public MemberType getMemberType() { return memberType; }
    public long getDurationSeconds() { return durationSeconds; }
    public int getDayOfWeek() { return dayOfWeek; }
}
