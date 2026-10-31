package com.cyclistic.api.stats;

import com.cyclistic.api.trip.MemberType;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/stats")
@Validated
@Tag(name = "Stats", description = "Aggregate statistics comparing members and casual riders")
public class StatsController {

    private final StatsService service;

    public StatsController(StatsService service) {
        this.service = service;
    }

    @GetMapping("/summary")
    @Operation(summary = "Trip count and average / longest ride length per rider type")
    public List<MemberSummary> summary() {
        return service.summary();
    }

    @GetMapping("/weekday")
    @Operation(summary = "Trips per day of week, optionally for one rider type")
    public List<WeekdayCount> byWeekday(@RequestParam(required = false) MemberType memberType) {
        return service.byWeekday(memberType);
    }

    @GetMapping("/top-stations")
    @Operation(summary = "Most popular start stations, optionally for one rider type")
    public List<StationCount> topStations(
            @RequestParam(required = false) MemberType memberType,
            @RequestParam(defaultValue = "10") @Min(1) @Max(50) int limit) {
        return service.topStartStations(memberType, limit);
    }
}
