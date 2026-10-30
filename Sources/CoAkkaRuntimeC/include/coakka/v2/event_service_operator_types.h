#ifndef COAKKA_V2_EVENT_SERVICE_OPERATOR_TYPES_H
#define COAKKA_V2_EVENT_SERVICE_OPERATOR_TYPES_H

#include <stddef.h>
#include <stdint.h>

#include "coakka/v2/event_service_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Future operator/control placeholder types for coakka-event-service.
 *
 * These declarations intentionally live outside the normal publish/subscribe
 * API surface so operational controls do not leak into the default data path.
 */

typedef enum coakka_v2_event_operator_job_state_t {
    COAKKA_V2_EVENT_OPERATOR_JOB_CREATED = 0,
    COAKKA_V2_EVENT_OPERATOR_JOB_RUNNING = 1,
    COAKKA_V2_EVENT_OPERATOR_JOB_SUCCEEDED = 2,
    COAKKA_V2_EVENT_OPERATOR_JOB_FAILED = 3,
    COAKKA_V2_EVENT_OPERATOR_JOB_CANCELLED = 4
} coakka_v2_event_operator_job_state_t;

typedef enum coakka_v2_event_replay_target_kind_t {
    COAKKA_V2_EVENT_REPLAY_TARGET_DURABLE_SUBSCRIPTION = 0,
    COAKKA_V2_EVENT_REPLAY_TARGET_EPHEMERAL_SUBSCRIPTION = 1,
    COAKKA_V2_EVENT_REPLAY_TARGET_PROJECTION_HANDLER = 2,
    COAKKA_V2_EVENT_REPLAY_TARGET_DEADLETTER_EXPORT = 3
} coakka_v2_event_replay_target_kind_t;

typedef enum coakka_v2_event_operator_audit_action_t {
    COAKKA_V2_EVENT_OPERATOR_AUDIT_REPLAY_BEGIN = 0,
    COAKKA_V2_EVENT_OPERATOR_AUDIT_REPLAY_CANCEL = 1,
    COAKKA_V2_EVENT_OPERATOR_AUDIT_SUBSCRIPTION_PAUSE = 2,
    COAKKA_V2_EVENT_OPERATOR_AUDIT_SUBSCRIPTION_RESUME = 3,
    COAKKA_V2_EVENT_OPERATOR_AUDIT_CHECKPOINT_REPLACE = 4,
    COAKKA_V2_EVENT_OPERATOR_AUDIT_DEADLETTER_EXPORT = 5
} coakka_v2_event_operator_audit_action_t;

typedef enum coakka_v2_event_operator_audit_disposition_t {
    COAKKA_V2_EVENT_OPERATOR_AUDIT_ALLOWED = 0,
    COAKKA_V2_EVENT_OPERATOR_AUDIT_REJECTED = 1,
    COAKKA_V2_EVENT_OPERATOR_AUDIT_APPLIED = 2,
    COAKKA_V2_EVENT_OPERATOR_AUDIT_FAILED = 3
} coakka_v2_event_operator_audit_disposition_t;

typedef struct coakka_v2_event_subscription_lag_snapshot_t {
    size_t struct_size;
    coakka_v2_event_selector_t selector;
    coakka_v2_event_string_view_t subscription_name;
    coakka_v2_event_string_view_t last_acked_event_id;
    coakka_v2_event_string_view_t last_acked_cursor_token;
    uint32_t ack_policy;
    uint32_t delivery_policy;
    uint32_t subscription_mode;
    uint64_t pending_event_count;
    uint64_t retry_queue_count;
    uint64_t deadletter_count;
    uint64_t oldest_pending_age_ms;
    uint64_t last_delivery_unix_ms;
} coakka_v2_event_subscription_lag_snapshot_t;

typedef struct coakka_v2_event_replay_request_t {
    size_t struct_size;
    coakka_v2_event_selector_t selector;
    coakka_v2_event_cursor_t start_cursor;
    coakka_v2_event_cursor_t end_cursor;
    coakka_v2_event_string_view_t target_name;
    coakka_v2_event_string_view_t requested_by;
    uint32_t target_kind;
    uint32_t preserve_checkpoint;
    uint32_t dry_run;
} coakka_v2_event_replay_request_t;

typedef struct coakka_v2_event_replay_job_snapshot_t {
    size_t struct_size;
    coakka_v2_event_string_view_t replay_job_id;
    coakka_v2_event_string_view_t target_name;
    coakka_v2_event_string_view_t requested_by;
    uint32_t target_kind;
    uint32_t job_state;
    uint64_t matched_event_count;
    uint64_t delivered_event_count;
    uint64_t failed_event_count;
    uint64_t deadlettered_event_count;
    uint64_t created_unix_ms;
    uint64_t updated_unix_ms;
} coakka_v2_event_replay_job_snapshot_t;

typedef struct coakka_v2_event_operator_audit_record_t {
    size_t struct_size;
    coakka_v2_event_string_view_t audit_id;
    coakka_v2_event_string_view_t principal_name;
    coakka_v2_event_string_view_t subject_name;
    coakka_v2_event_string_view_t reason_text;
    uint32_t action;
    uint32_t disposition;
    uint64_t created_unix_ms;
} coakka_v2_event_operator_audit_record_t;

void coakka_v2_event_service_default_replay_request(
    coakka_v2_event_replay_request_t *out_request);

const char *coakka_v2_event_operator_job_state_name(uint32_t state);

const char *coakka_v2_event_replay_target_kind_name(uint32_t kind);

const char *coakka_v2_event_operator_audit_action_name(uint32_t action);

const char *coakka_v2_event_operator_audit_disposition_name(uint32_t disposition);

#ifdef __cplusplus
}
#endif

#endif
