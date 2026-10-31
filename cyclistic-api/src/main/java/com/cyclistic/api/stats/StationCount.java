package com.cyclistic.api.stats;

/** Number of trips that started at a given station. */
public record StationCount(String station, long trips) {

    /** Used by the JPQL constructor expression. */
    public StationCount(String station, Long trips) {
        this(station, trips == null ? 0L : trips.longValue());
    }
}
