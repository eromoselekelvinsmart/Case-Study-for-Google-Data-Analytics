package com.cyclistic.api.common;

/** Mapped to HTTP 400 by {@link GlobalExceptionHandler}. */
public class InvalidRequestException extends RuntimeException {

    public InvalidRequestException(String message) {
        super(message);
    }
}
