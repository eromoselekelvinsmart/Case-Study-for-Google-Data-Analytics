package com.cyclistic.api.common;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.List;

/** Turns exceptions into consistent {@link ApiError} responses with the right HTTP status. */
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ApiError> notFound(NotFoundException ex, HttpServletRequest request) {
        return build(HttpStatus.NOT_FOUND, ex.getMessage(), request, null);
    }

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<ApiError> conflict(ConflictException ex, HttpServletRequest request) {
        return build(HttpStatus.CONFLICT, ex.getMessage(), request, null);
    }

    @ExceptionHandler(InvalidRequestException.class)
    public ResponseEntity<ApiError> invalid(InvalidRequestException ex, HttpServletRequest request) {
        return build(HttpStatus.BAD_REQUEST, ex.getMessage(), request, null);
    }

    /** @Valid request body failed Bean Validation. */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> bodyValidation(MethodArgumentNotValidException ex, HttpServletRequest request) {
        List<String> details = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> e.getField() + ": " + e.getDefaultMessage())
                .sorted()
                .toList();
        return build(HttpStatus.BAD_REQUEST, "Request body is invalid", request, details);
    }

    /** Constraint on a query or path parameter failed (e.g. size > 100). */
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiError> paramValidation(ConstraintViolationException ex, HttpServletRequest request) {
        List<String> details = ex.getConstraintViolations().stream()
                .map(v -> lastSegment(v.getPropertyPath().toString()) + ": " + v.getMessage())
                .sorted()
                .toList();
        return build(HttpStatus.BAD_REQUEST, "Request parameters are invalid", request, details);
    }

    /** Spring 6.1+ built-in method validation (raised instead of the above in some setups). */
    @ExceptionHandler(HandlerMethodValidationException.class)
    public ResponseEntity<ApiError> handlerValidation(HandlerMethodValidationException ex, HttpServletRequest request) {
        List<String> details = ex.getAllErrors().stream()
                .map(e -> e.getDefaultMessage())
                .sorted()
                .toList();
        return build(HttpStatus.BAD_REQUEST, "Request parameters are invalid", request, details);
    }

    /** Wrong type for a parameter, e.g. memberType=SOMETIMES. */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiError> typeMismatch(MethodArgumentTypeMismatchException ex, HttpServletRequest request) {
        String message = "Invalid value '" + ex.getValue() + "' for parameter '" + ex.getName() + "'";
        return build(HttpStatus.BAD_REQUEST, message, request, null);
    }

    /** Malformed JSON, or a body value that cannot be converted (bad date or enum). */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiError> unreadable(HttpMessageNotReadableException ex, HttpServletRequest request) {
        return build(HttpStatus.BAD_REQUEST, "Request body is malformed or has invalid values", request, null);
    }

    private static ResponseEntity<ApiError> build(HttpStatus status, String message, HttpServletRequest request,
                                                  List<String> details) {
        ApiError body = ApiError.of(status.value(), status.getReasonPhrase(), message,
                request.getRequestURI(), details);
        return ResponseEntity.status(status).body(body);
    }

    private static String lastSegment(String path) {
        int dot = path.lastIndexOf('.');
        return dot >= 0 ? path.substring(dot + 1) : path;
    }
}
