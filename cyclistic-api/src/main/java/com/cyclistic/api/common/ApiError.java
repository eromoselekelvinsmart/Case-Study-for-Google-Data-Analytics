package com.cyclistic.api.common;

import java.time.Instant;
import java.util.List;

/** Consistent error body returned by every endpoint. */
public record ApiError(Instant timestamp, int status, String error, String message, String path,
                       List<String> details) {

    public static ApiError of(int status, String error, String message, String path, List<String> details) {
        return new ApiError(Instant.now(), status, error, message, path, details == null ? List.of() : details);
    }
}
