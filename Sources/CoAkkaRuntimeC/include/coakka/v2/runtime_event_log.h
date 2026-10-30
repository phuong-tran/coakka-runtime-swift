#ifndef COAKKA_V2_RUNTIME_EVENT_LOG_H
#define COAKKA_V2_RUNTIME_EVENT_LOG_H

#include "coakka/v2/runtime.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * One bounded runtime-owned recent event entry.
 *
 * `event_sequence` is monotonic for the lifetime of the runtime instance and
 * advances only for entries retained by the recent-event log. `change_sequence`
 * mirrors the monitor snapshot freshness sequence that was current when this
 * event was recorded. `kind` and `queue_scope` reuse the existing monitor
 * event/category enums, but this contract is pull-based; no monitor fd ever
 * emits serialized event records.
 *
 * `code` and `value` are event-specific scalar details. Today the runtime uses
 * `code` for status-style reasons such as `CONTROL_REJECTED`, queue-reject
 * detail on `QUEUE_REJECTED`, or the forwarded terminal deadletter reason on
 * `REMOTE_DEADLETTER_FORWARDED`; `value` carries small bounded metadata such
 * as accepted route count on `CONTROL_APPLIED` or observed endpoint attempt
 * count on remote transport/forward/timeout events.
 *
 * Remote failover events use queue scope `REMOTE_OUTBOUND`. `ATTEMPT` stores
 * the stable deadletter reason that triggered failover in `code` and the
 * one-based endpoint ordinal about to be attempted in `value`. `SUCCEEDED`
 * stores code zero and the total endpoint attempt count. `EXHAUSTED` stores
 * the stable terminal reason in `code` and the number of endpoint attempts
 * consumed before the terminal outcome. Endpoint identity and transport
 * diagnostic text are deliberately not retained in this bounded log.
 *
 * An inbound TLS handshake failure uses kind `REMOTE_TRANSPORT_FAILED`, queue
 * scope `INGRESS`, and stores its transport-failure code in `code`. `value`
 * packs the remaining typed dimensions into one bounded scalar using the
 * shifts below. No certificate, credential location, or provider diagnostic
 * is retained by this event.
 */
typedef struct coakka_v2_runtime_event_log_entry_t {
    uint64_t event_sequence;
    uint64_t change_sequence;
    uint64_t observed_mono_ns;
    uint64_t applied_generation;
    uint32_t kind;
    uint32_t queue_scope;
    int64_t code;
    uint64_t value;
} coakka_v2_runtime_event_log_entry_t;

enum {
    COAKKA_V2_RUNTIME_EVENT_TRANSPORT_FAILURE_DOMAIN_SHIFT = 0u,
    COAKKA_V2_RUNTIME_EVENT_TRANSPORT_FAILURE_PHASE_SHIFT = 8u,
    COAKKA_V2_RUNTIME_EVENT_TRANSPORT_FAILURE_CERTAINTY_SHIFT = 16u,
    COAKKA_V2_RUNTIME_EVENT_TRANSPORT_FAILURE_SCOPE_SHIFT = 24u,
    COAKKA_V2_RUNTIME_EVENT_TRANSPORT_FAILURE_DIMENSION_MASK = 0xffu
};

/**
 * Deep-copied bounded recent-event snapshot.
 *
 * `requested_after_event_sequence` echoes the caller cursor.
 * `latest_event_sequence` is the newest event sequence retained at read time.
 * `missed_event_count` reports how many matching events newer than the caller
 * cursor were already evicted from the bounded runtime ring.
 * `remaining_event_count` reports retained matching events not copied into this
 * snapshot because `max_events` limited the result size; callers may continue
 * paging with the last returned `event_sequence`.
 */
typedef struct coakka_v2_runtime_event_log_snapshot_t {
    uint64_t requested_after_event_sequence;
    uint64_t latest_event_sequence;
    uint64_t missed_event_count;
    size_t remaining_event_count;
    size_t event_count;
    const coakka_v2_runtime_event_log_entry_t *events;
} coakka_v2_runtime_event_log_snapshot_t;

enum {
    COAKKA_V2_RUNTIME_EVENT_LOG_SNAPSHOT_HAS_EVENTS = 1u << 0,
    COAKKA_V2_RUNTIME_EVENT_LOG_SNAPSHOT_MISSED_EVENTS = 1u << 1,
    COAKKA_V2_RUNTIME_EVENT_LOG_SNAPSHOT_HAS_MORE = 1u << 2,
    COAKKA_V2_RUNTIME_EVENT_LOG_SNAPSHOT_CURSOR_ADVANCED = 1u << 3
};

/**
 * Returns derived cursor-state flags for one event-log snapshot.
 *
 * This helper does not inspect runtime state and does not own memory. It only
 * normalizes the snapshot fields that pull clients otherwise tend to interpret
 * differently while paging the bounded event log.
 */
uint32_t coakka_v2_runtime_event_log_snapshot_flags(
    const coakka_v2_runtime_event_log_snapshot_t *snapshot
);

/**
 * Reads a bounded runtime-owned recent-event snapshot.
 *
 * Results are ordered oldest-first by `event_sequence`. `after_event_sequence`
 * is an exclusive cursor. `max_events = 0` means "return every retained event
 * newer than the cursor".
 */
coakka_v2_status_t coakka_v2_runtime_get_event_log_snapshot(
    coakka_v2_runtime_t *rt,
    uint64_t after_event_sequence,
    size_t max_events,
    coakka_v2_runtime_event_log_snapshot_t *out_snapshot
);

/**
 * Reads one event-log snapshot only after the caller-owned auth context
 * satisfies the runtime-owned observe access policy.
 *
 * Unauthorized or forbidden callers receive COAKKA_V2_OK with out_result set
 * accordingly, and out_snapshot is cleared to an empty page.
 */
coakka_v2_status_t coakka_v2_runtime_get_event_log_snapshot_with_auth_context(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_context_t *context,
    uint64_t after_event_sequence,
    size_t max_events,
    coakka_v2_runtime_event_log_snapshot_t *out_snapshot,
    coakka_v2_runtime_auth_result_t *out_result
);

/** Releases memory returned by coakka_v2_runtime_get_event_log_snapshot(...). */
void coakka_v2_runtime_free_event_log_snapshot(
    coakka_v2_runtime_event_log_snapshot_t *snapshot
);

#ifdef __cplusplus
}
#endif

#endif
