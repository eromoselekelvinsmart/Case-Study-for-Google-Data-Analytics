package com.cyclistic.api.trip;

import com.cyclistic.api.common.NotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Web-layer slice test: HTTP status codes, JSON shape and validation, with the service mocked. */
@WebMvcTest(TripController.class)
class TripControllerTest {

    @Autowired
    private MockMvc mvc;

    @MockBean
    private TripService service;

    private static final TripResponse SAMPLE = new TripResponse("R1", "classic_bike",
            LocalDateTime.of(2024, 3, 1, 8, 0), LocalDateTime.of(2024, 3, 1, 8, 20),
            "A", "B", MemberType.MEMBER, 20.0);

    @Test
    void getReturnsTripJson() throws Exception {
        when(service.get("R1")).thenReturn(SAMPLE);

        mvc.perform(get("/api/v1/trips/R1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rideId").value("R1"))
                .andExpect(jsonPath("$.memberType").value("MEMBER"))
                .andExpect(jsonPath("$.startedAt").value("2024-03-01T08:00:00"));
    }

    @Test
    void getUnknownTripReturns404WithErrorBody() throws Exception {
        when(service.get("NOPE")).thenThrow(new NotFoundException("Trip not found: NOPE"));

        mvc.perform(get("/api/v1/trips/NOPE"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.message").value("Trip not found: NOPE"))
                .andExpect(jsonPath("$.path").value("/api/v1/trips/NOPE"));
    }

    @Test
    void postValidTripReturns201WithLocation() throws Exception {
        when(service.create(any())).thenReturn(SAMPLE);

        mvc.perform(post("/api/v1/trips")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"rideId":"R1","rideableType":"classic_bike",
                                 "startedAt":"2024-03-01T08:00:00","endedAt":"2024-03-01T08:20:00",
                                 "memberType":"MEMBER"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", "http://localhost/api/v1/trips/R1"));
    }

    @Test
    void postMissingFieldsReturns400WithFieldDetails() throws Exception {
        mvc.perform(post("/api/v1/trips")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"rideableType\":\"classic_bike\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.details.length()").value(4));
        verifyNoInteractions(service);
    }

    @Test
    void postMalformedJsonReturns400() throws Exception {
        mvc.perform(post("/api/v1/trips")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{not json"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void invalidEnumFilterReturns400() throws Exception {
        mvc.perform(get("/api/v1/trips").param("memberType", "SOMETIMES"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Invalid value 'SOMETIMES' for parameter 'memberType'"));
    }

    @Test
    void pageSizeAboveLimitReturns400() throws Exception {
        mvc.perform(get("/api/v1/trips").param("size", "500"))
                .andExpect(status().isBadRequest());
    }
}
