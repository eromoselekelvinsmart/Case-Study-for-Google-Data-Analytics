# Cyclistic Trip API

A Spring Boot REST API over Chicago's Divvy/Cyclistic bike-share trip data. It answers the Cyclistic case-study question: **how do annual members and casual riders use bikes differently?**

This project extends my [SQL / Power Query case study](#) (link your repo here) into a tested Java service. The same cleaning rules are now enforced in application code, exposed through a documented API, and checked by automated tests in CI.

**Stack:** Java 21 · Spring Boot 3.3 · Spring Web · Spring Data JPA · Bean Validation · H2 · springdoc-openapi (Swagger UI) · JUnit 5 · Mockito · MockMvc · Docker · GitHub Actions

## Features

- **REST endpoints** for browsing, creating and deleting trips, with paging and filters.
- **Statistics endpoints** comparing members and casual riders: average ride length, trips by weekday, and top start stations.
- **One set of cleaning rules for both inputs.** The CSV loader and the `POST` endpoint share `TripRules`. Rows are rejected when they are duplicated, end before they start, last under 1 minute or over 24 hours, or have an unknown rider type.
- **Row-count reconciliation.** Every load logs rows read, loaded and skipped by reason. Startup fails if `read != loaded + skipped`.
- **Fast bulk load.** JDBC batch inserts handle about 800K rows across the 12 monthly Divvy files.
- **Consistent error responses.** A global exception handler returns the same JSON error shape for 400, 404 and 409, including field-level validation details.
- **Interactive API docs** in Swagger UI, generated from the code.
- **Tests at three levels:**
  - Unit tests for parsing and cleaning, and for the service layer using Mockito.
  - Web-layer slice tests (`@WebMvcTest`).
  - End-to-end integration tests (`@SpringBootTest`).
- **CI.** Every push runs the full test suite and builds the Docker image.

## Run it

You need Java 21 and Maven 3.9+. IntelliJ IDEA Community also works: open the folder and run `CyclisticApiApplication`.

```bash
mvn spring-boot:run
```

Then open:

| URL | What |
|---|---|
| http://localhost:8080/swagger-ui.html | Interactive API docs (try every endpoint here) |
| http://localhost:8080/api/v1/stats/summary | Members vs casual riders |
| http://localhost:8080/h2-console | Browse the database (JDBC URL `jdbc:h2:mem:cyclistic`, user `sa`) |

By default, the app loads `src/main/resources/data/sample-trips.csv`. This is a **synthetic** 2,004-row sample in the Divvy format, so the app runs with no download. Four rows are deliberately dirty so you can watch the cleaning rules work in the startup log.

### Use the real Divvy data

Download the monthly trip CSVs from https://divvy-tripdata.s3.amazonaws.com/index.html. Unzip them into one folder, then run:

```bash
mvn spring-boot:run -Dspring-boot.run.arguments=--cyclistic.data.location=/path/to/divvy-folder
```

For the full year (~800K+ rows), give the JVM more memory, because the database is in memory:

```bash
export MAVEN_OPTS="-Xmx2g"
```

### Docker

```bash
docker build -t cyclistic-api .
docker run -p 8080:8080 cyclistic-api
# with real data:
docker run -p 8080:8080 -v /path/to/divvy-folder:/data cyclistic-api --cyclistic.data.location=/data
```

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/trips?memberType=&rideableType=&page=&size=` | Paged trips, newest first (`size` ≤ 100) |
| GET | `/api/v1/trips/{rideId}` | One trip (404 if missing) |
| POST | `/api/v1/trips` | Create a trip: 201 + `Location` header; 400 if invalid; 409 if the ID exists |
| DELETE | `/api/v1/trips/{rideId}` | Delete a trip (204) |
| GET | `/api/v1/stats/summary` | Trips and average/longest ride minutes per rider type |
| GET | `/api/v1/stats/weekday?memberType=` | Trips per day of week |
| GET | `/api/v1/stats/top-stations?memberType=&limit=` | Most popular start stations |

Example error:

```json
{
  "timestamp": "2026-10-30T18:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Request body is invalid",
  "path": "/api/v1/trips",
  "details": ["endedAt: must not be null", "memberType: must not be null"]
}
```

## Tests

```bash
mvn test
```

| Test class | Type | Covers |
|---|---|---|
| `TripCsvParserTest` | Unit | Each cleaning rule, timestamp formats, reconciliation, missing columns |
| `TripServiceTest` | Unit (Mockito) | Business logic, 404/409/400 paths, filter routing |
| `TripControllerTest` | Web slice (`@WebMvcTest`) | Status codes, JSON shape, validation, error bodies |
| `ApiIntegrationTest` | Integration (`@SpringBootTest`) | Full app with sample data: load counts, stats, create/read/delete, OpenAPI |

## Project structure

```
src/main/java/com/cyclistic/api/
├── trip/      Trip entity, repository, service, controller, request/response DTOs, TripRules
├── stats/     Aggregate queries and endpoints
├── loader/    CSV parsing, cleaning and batch loading (LoadReport for reconciliation)
└── common/    Error handling, exceptions, paging DTO
```

## Next steps

- Vue.js dashboard that consumes the stats endpoints.
- PostgreSQL via Docker Compose instead of in-memory H2.
- A GenAI endpoint that turns plain-English questions ("Which stations do casual riders use on weekends?") into calls to the stats API.
