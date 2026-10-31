package com.cyclistic.api.trip;

import com.cyclistic.api.common.ConflictException;
import com.cyclistic.api.common.InvalidRequestException;
import com.cyclistic.api.common.NotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TripServiceTest {

    private static final LocalDateTime START = LocalDateTime.of(2024, 3, 1, 8, 0);

    @Mock
    private TripRepository repository;

    @InjectMocks
    private TripService service;

    private static CreateTripRequest request(LocalDateTime end) {
        return new CreateTripRequest("NEW1", "classic_bike", START, end, "A", "B", MemberType.CASUAL);
    }

    @Test
    void getReturnsTripWithRideMinutes() {
        Trip trip = new Trip("R1", "classic_bike", START, START.plusMinutes(12).plusSeconds(30), "A", "B",
                MemberType.MEMBER);
        when(repository.findById("R1")).thenReturn(Optional.of(trip));

        TripResponse response = service.get("R1");

        assertThat(response.rideId()).isEqualTo("R1");
        assertThat(response.rideMinutes()).isEqualTo(12.5);
    }

    @Test
    void getThrowsNotFoundForUnknownId() {
        when(repository.findById("NOPE")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.get("NOPE")).isInstanceOf(NotFoundException.class);
    }

    @Test
    void listUsesCombinedFilterWhenBothFiltersGiven() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<Trip> empty = new PageImpl<>(List.of(), pageable, 0);
        when(repository.findByMemberTypeAndRideableType(MemberType.MEMBER, "electric_bike", pageable))
                .thenReturn(empty);

        Page<TripResponse> result = service.list(MemberType.MEMBER, "electric_bike", pageable);

        assertThat(result.getTotalElements()).isZero();
        verify(repository, never()).findAll(any(Pageable.class));
    }

    @Test
    void createSavesValidTrip() {
        when(repository.existsById("NEW1")).thenReturn(false);
        when(repository.save(any(Trip.class))).thenAnswer(inv -> inv.getArgument(0));

        TripResponse created = service.create(request(START.plusMinutes(20)));

        assertThat(created.rideMinutes()).isEqualTo(20.0);
        assertThat(created.memberType()).isEqualTo(MemberType.CASUAL);
    }

    @Test
    void createRejectsEndBeforeStart() {
        assertThatThrownBy(() -> service.create(request(START.minusMinutes(5))))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessageContaining("after");
        verify(repository, never()).save(any());
    }

    @Test
    void createRejectsDuplicateId() {
        when(repository.existsById("NEW1")).thenReturn(true);

        assertThatThrownBy(() -> service.create(request(START.plusMinutes(20))))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void deleteThrowsNotFoundForUnknownId() {
        when(repository.existsById("NOPE")).thenReturn(false);

        assertThatThrownBy(() -> service.delete("NOPE")).isInstanceOf(NotFoundException.class);
        verify(repository, never()).deleteById(any());
    }
}
