package com.cyclistic.api.trip;

import com.cyclistic.api.common.ConflictException;
import com.cyclistic.api.common.InvalidRequestException;
import com.cyclistic.api.common.NotFoundException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TripService {

    private final TripRepository repository;

    public TripService(TripRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public Page<TripResponse> list(MemberType memberType, String rideableType, Pageable pageable) {
        boolean hasRideable = rideableType != null && !rideableType.isBlank();
        Page<Trip> page;
        if (memberType != null && hasRideable) {
            page = repository.findByMemberTypeAndRideableType(memberType, rideableType, pageable);
        } else if (memberType != null) {
            page = repository.findByMemberType(memberType, pageable);
        } else if (hasRideable) {
            page = repository.findByRideableType(rideableType, pageable);
        } else {
            page = repository.findAll(pageable);
        }
        return page.map(TripResponse::from);
    }

    @Transactional(readOnly = true)
    public TripResponse get(String rideId) {
        return repository.findById(rideId)
                .map(TripResponse::from)
                .orElseThrow(() -> new NotFoundException("Trip not found: " + rideId));
    }

    @Transactional
    public TripResponse create(CreateTripRequest request) {
        String problem = TripRules.validateTimes(request.startedAt(), request.endedAt());
        if (problem != null) {
            throw new InvalidRequestException(problem);
        }
        if (repository.existsById(request.rideId())) {
            throw new ConflictException("Trip already exists: " + request.rideId());
        }
        Trip trip = new Trip(
                request.rideId(),
                request.rideableType(),
                request.startedAt(),
                request.endedAt(),
                request.startStationName(),
                request.endStationName(),
                request.memberType());
        return TripResponse.from(repository.save(trip));
    }

    @Transactional
    public void delete(String rideId) {
        if (!repository.existsById(rideId)) {
            throw new NotFoundException("Trip not found: " + rideId);
        }
        repository.deleteById(rideId);
    }
}
