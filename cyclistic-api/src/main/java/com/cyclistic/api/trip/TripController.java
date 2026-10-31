package com.cyclistic.api.trip;

import com.cyclistic.api.common.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;

@RestController
@RequestMapping("/api/v1/trips")
@Validated
@Tag(name = "Trips", description = "Browse, create and delete individual trips")
public class TripController {

    private final TripService service;

    public TripController(TripService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List trips, newest first, with optional filters")
    public PageResponse<TripResponse> list(
            @RequestParam(required = false) MemberType memberType,
            @RequestParam(required = false) String rideableType,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size) {
        PageRequest pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "startedAt"));
        return PageResponse.from(service.list(memberType, rideableType, pageable));
    }

    @GetMapping("/{rideId}")
    @Operation(summary = "Get one trip by its ride ID")
    public TripResponse get(@PathVariable String rideId) {
        return service.get(rideId);
    }

    @PostMapping
    @Operation(summary = "Create a trip (validated against the same rules as the CSV loader)")
    public ResponseEntity<TripResponse> create(@Valid @RequestBody CreateTripRequest request) {
        TripResponse created = service.create(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{rideId}")
                .buildAndExpand(created.rideId())
                .toUri();
        return ResponseEntity.created(location).body(created);
    }

    @DeleteMapping("/{rideId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a trip")
    public void delete(@PathVariable String rideId) {
        service.delete(rideId);
    }
}
