package com.cyclistic.api.stats;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.greaterThan;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * End-to-end test: starts the full application, loads the bundled sample CSV
 * (2,004 rows; 4 deliberately dirty, so 2,000 load) and calls the real endpoints.
 */
@SpringBootTest
@AutoConfigureMockMvc
@DirtiesContext
class ApiIntegrationTest {

    @Autowired
    private MockMvc mvc;

    @Test
    void sampleDataLoadsAndCleaningRulesApply() throws Exception {
        mvc.perform(get("/api/v1/trips").param("size", "5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(2000))
                .andExpect(jsonPath("$.content", hasSize(5)));

        // Rows the loader should have rejected are not in the database.
        mvc.perform(get("/api/v1/trips/NEGDUR000000001")).andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/trips/LONGRIDE0000001")).andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/trips/BADTYPE00000001")).andExpect(status().isNotFound());
    }

    @Test
    void summarySplitsMembersAndCasualRiders() throws Exception {
        mvc.perform(get("/api/v1/stats/summary"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].memberType").value("CASUAL"))
                .andExpect(jsonPath("$[0].trips").value(777))
                .andExpect(jsonPath("$[1].memberType").value("MEMBER"))
                .andExpect(jsonPath("$[1].trips").value(1223))
                .andExpect(jsonPath("$[1].avgRideMinutes").value(greaterThan(0.0)));
    }

    @Test
    void weekdayReturnsSevenDays() throws Exception {
        mvc.perform(get("/api/v1/stats/weekday").param("memberType", "CASUAL"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(7)))
                .andExpect(jsonPath("$[0].day").value("MONDAY"));
    }

    @Test
    void topStationsRespectsLimit() throws Exception {
        mvc.perform(get("/api/v1/stats/top-stations").param("limit", "3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(3)))
                .andExpect(jsonPath("$[0].station").value("Shedd Aquarium"))
                .andExpect(jsonPath("$[0].trips").value(152));
    }

    @Test
    void createReadAndDeleteTrip() throws Exception {
        mvc.perform(post("/api/v1/trips")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"rideId":"IT-TEST-1","rideableType":"electric_bike",
                                 "startedAt":"2024-06-01T10:00:00","endedAt":"2024-06-01T10:45:00",
                                 "startStationName":"Millennium Park","memberType":"CASUAL"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.rideMinutes").value(45.0));

        mvc.perform(get("/api/v1/trips/IT-TEST-1")).andExpect(status().isOk());

        mvc.perform(post("/api/v1/trips")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"rideId":"IT-TEST-1","rideableType":"electric_bike",
                                 "startedAt":"2024-06-01T10:00:00","endedAt":"2024-06-01T10:45:00",
                                 "memberType":"CASUAL"}
                                """))
                .andExpect(status().isConflict());

        mvc.perform(delete("/api/v1/trips/IT-TEST-1")).andExpect(status().isNoContent());
        mvc.perform(get("/api/v1/trips/IT-TEST-1")).andExpect(status().isNotFound());
    }

    @Test
    void openApiDocsArePublished() throws Exception {
        mvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/trips']").exists());
    }
}
