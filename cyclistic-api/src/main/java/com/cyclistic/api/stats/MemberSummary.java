package com.cyclistic.api.stats;

import com.cyclistic.api.trip.MemberType;

/** Trip count and ride-length statistics (in minutes) for one rider type. */
public record MemberSummary(MemberType memberType, long trips, double avgRideMinutes, double maxRideMinutes) {

    static MemberSummary from(MemberStatsRow row) {
        return new MemberSummary(
                row.memberType(),
                row.trips() == null ? 0 : row.trips(),
                toMinutes(row.avgSeconds() == null ? 0 : row.avgSeconds()),
                toMinutes(row.maxSeconds() == null ? 0 : row.maxSeconds()));
    }

    private static double toMinutes(double seconds) {
        return Math.round(seconds / 60.0 * 100.0) / 100.0;
    }
}
