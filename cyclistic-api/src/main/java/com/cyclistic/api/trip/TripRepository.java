package com.cyclistic.api.trip;

import com.cyclistic.api.stats.MemberStatsRow;
import com.cyclistic.api.stats.StationCount;
import com.cyclistic.api.stats.WeekdayCount;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface TripRepository extends JpaRepository<Trip, String> {

    Page<Trip> findByMemberType(MemberType memberType, Pageable pageable);

    Page<Trip> findByRideableType(String rideableType, Pageable pageable);

    Page<Trip> findByMemberTypeAndRideableType(MemberType memberType, String rideableType, Pageable pageable);

    @Query("""
            SELECT new com.cyclistic.api.stats.MemberStatsRow(
                t.memberType, COUNT(t), AVG(t.durationSeconds), MAX(t.durationSeconds))
            FROM Trip t
            GROUP BY t.memberType
            ORDER BY t.memberType
            """)
    List<MemberStatsRow> summarizeByMemberType();

    @Query("""
            SELECT new com.cyclistic.api.stats.WeekdayCount(t.dayOfWeek, COUNT(t))
            FROM Trip t
            WHERE (:memberType IS NULL OR t.memberType = :memberType)
            GROUP BY t.dayOfWeek
            ORDER BY t.dayOfWeek
            """)
    List<WeekdayCount> countByWeekday(@Param("memberType") MemberType memberType);

    @Query("""
            SELECT new com.cyclistic.api.stats.StationCount(t.startStationName, COUNT(t))
            FROM Trip t
            WHERE t.startStationName IS NOT NULL
              AND (:memberType IS NULL OR t.memberType = :memberType)
            GROUP BY t.startStationName
            ORDER BY COUNT(t) DESC, t.startStationName
            """)
    List<StationCount> topStartStations(@Param("memberType") MemberType memberType, Pageable pageable);
}
