package com.cyclistic.api.trip;

/** Rider type, matching the "member_casual" column in the Divvy/Cyclistic CSVs. */
public enum MemberType {
    MEMBER,
    CASUAL;

    /** Parses "member" / "casual" (any case). Returns null when the value is blank or unknown. */
    public static MemberType fromCsv(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return switch (value.trim().toLowerCase()) {
            case "member" -> MEMBER;
            case "casual" -> CASUAL;
            default -> null;
        };
    }
}
