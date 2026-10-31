package com.cyclistic.api.stats;

import java.time.DayOfWeek;

/** Number of trips that started on a given day of the week. */
public record WeekdayCount(DayOfWeek day, long trips) {

    /** Used by the JPQL constructor expression (ISO day number 1-7). */
    public WeekdayCount(Integer isoDay, Long trips) {
        this(DayOfWeek.of(isoDay), trips == null ? 0 : trips);
    }
}
