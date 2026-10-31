package com.cyclistic.api.stats;

import com.cyclistic.api.trip.MemberType;
import com.cyclistic.api.trip.TripRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Answers the case-study question: how do annual members and casual riders use bikes differently? */
@Service
@Transactional(readOnly = true)
public class StatsService {

    private final TripRepository repository;

    public StatsService(TripRepository repository) {
        this.repository = repository;
    }

    public List<MemberSummary> summary() {
        return repository.summarizeByMemberType().stream().map(MemberSummary::from).toList();
    }

    public List<WeekdayCount> byWeekday(MemberType memberType) {
        return repository.countByWeekday(memberType);
    }

    public List<StationCount> topStartStations(MemberType memberType, int limit) {
        return repository.topStartStations(memberType, PageRequest.of(0, limit));
    }
}
