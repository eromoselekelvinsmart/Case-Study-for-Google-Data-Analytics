package com.cyclistic.api.loader;

import java.util.Collections;
import java.util.Map;
import java.util.TreeMap;

/** Counts rows read, loaded and skipped (by reason) so every load can be reconciled. */
public class LoadReport {

    private long rowsRead;
    private long rowsLoaded;
    private final Map<String, Long> skipped = new TreeMap<>();

    void rowRead() {
        rowsRead++;
    }

    void rowLoaded() {
        rowsLoaded++;
    }

    void skip(String reason) {
        skipped.merge(reason, 1L, Long::sum);
    }

    public long rowsRead() {
        return rowsRead;
    }

    public long rowsLoaded() {
        return rowsLoaded;
    }

    public long rowsSkipped() {
        return skipped.values().stream().mapToLong(Long::longValue).sum();
    }

    public Map<String, Long> skippedByReason() {
        return Collections.unmodifiableMap(skipped);
    }

    /** Reconciliation check: every row read is either loaded or skipped for a recorded reason. */
    public boolean reconciles() {
        return rowsRead == rowsLoaded + rowsSkipped();
    }

    @Override
    public String toString() {
        return "read=" + rowsRead + ", loaded=" + rowsLoaded + ", skipped=" + rowsSkipped() + " " + skipped;
    }
}
