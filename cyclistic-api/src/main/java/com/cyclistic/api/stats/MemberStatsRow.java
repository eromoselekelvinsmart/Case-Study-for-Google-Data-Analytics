package com.cyclistic.api.stats;

import com.cyclistic.api.trip.MemberType;

/** Raw aggregate row produced by the repository query (durations in seconds). */
public record MemberStatsRow(MemberType memberType, Long trips, Double avgSeconds, Long maxSeconds) {
}
