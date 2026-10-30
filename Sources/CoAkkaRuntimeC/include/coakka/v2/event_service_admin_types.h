#ifndef COAKKA_V2_EVENT_SERVICE_ADMIN_TYPES_H
#define COAKKA_V2_EVENT_SERVICE_ADMIN_TYPES_H

#include <stddef.h>
#include <stdint.h>

#include "coakka/v2/event_service_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Future admin/provisioning placeholder types for coakka-event-service.
 *
 * These declarations intentionally define durable resource configuration and
 * checkpoint-authority mutations outside the normal data-plane and operator
 * read/replay surfaces.
 */

typedef enum coakka_v2_event_admin_apply_action_t {
    COAKKA_V2_EVENT_ADMIN_APPLY_UPSERT = 0,
    COAKKA_V2_EVENT_ADMIN_APPLY_DELETE = 1
} coakka_v2_event_admin_apply_action_t;

typedef enum coakka_v2_event_admin_apply_disposition_t {
    COAKKA_V2_EVENT_ADMIN_APPLY_ACCEPTED = 0,
    COAKKA_V2_EVENT_ADMIN_APPLY_REJECTED = 1,
    COAKKA_V2_EVENT_ADMIN_APPLY_APPLIED = 2,
    COAKKA_V2_EVENT_ADMIN_APPLY_FAILED = 3
} coakka_v2_event_admin_apply_disposition_t;

typedef enum coakka_v2_event_checkpoint_replace_mode_t {
    COAKKA_V2_EVENT_CHECKPOINT_REPLACE_DRY_RUN_ONLY = 0,
    COAKKA_V2_EVENT_CHECKPOINT_REPLACE_REQUIRE_FORWARD_CONTIGUOUS = 1,
    COAKKA_V2_EVENT_CHECKPOINT_REPLACE_REQUIRE_FORWARD_EXPLICIT = 2,
    COAKKA_V2_EVENT_CHECKPOINT_REPLACE_ALLOW_NON_MONOTONIC_REWIND = 3
} coakka_v2_event_checkpoint_replace_mode_t;

typedef struct coakka_v2_event_stream_config_t {
    size_t struct_size;
    coakka_v2_event_stream_id_t stream;
    coakka_v2_event_string_view_t retention_profile;
    coakka_v2_event_string_view_t archive_profile;
    coakka_v2_event_string_view_t deadletter_stream;
    uint32_t default_delivery_policy;
} coakka_v2_event_stream_config_t;

typedef struct coakka_v2_event_subscription_config_t {
    size_t struct_size;
    coakka_v2_event_selector_t selector;
    coakka_v2_event_string_view_t subscription_name;
    coakka_v2_event_string_view_t retry_policy_name;
    uint32_t ack_policy;
    uint32_t delivery_policy;
    uint32_t subscription_mode;
    uint32_t replay_policy;
    uint32_t deadletter_enabled;
    uint32_t paused;
    uint32_t max_inflight;
} coakka_v2_event_subscription_config_t;

typedef struct coakka_v2_event_checkpoint_snapshot_t {
    size_t struct_size;
    coakka_v2_event_string_view_t subscription_name;
    coakka_v2_event_string_view_t acked_event_id;
    coakka_v2_event_string_view_t acked_cursor_token;
    uint64_t acked_event_seq;
    uint64_t updated_unix_ms;
} coakka_v2_event_checkpoint_snapshot_t;

typedef struct coakka_v2_event_checkpoint_replace_request_t {
    size_t struct_size;
    coakka_v2_event_string_view_t subscription_name;
    coakka_v2_event_cursor_t target_cursor;
    coakka_v2_event_string_view_t requested_by;
    coakka_v2_event_string_view_t reason_text;
    uint64_t expected_current_event_seq;
    uint32_t dry_run;
    uint32_t replace_mode;
} coakka_v2_event_checkpoint_replace_request_t;

typedef struct coakka_v2_event_admin_apply_result_t {
    size_t struct_size;
    coakka_v2_event_string_view_t resource_kind;
    coakka_v2_event_string_view_t resource_name;
    coakka_v2_event_string_view_t reason_text;
    uint32_t action;
    uint32_t disposition;
    uint64_t applied_unix_ms;
} coakka_v2_event_admin_apply_result_t;

void coakka_v2_event_service_default_stream_config(
    coakka_v2_event_stream_config_t *out_config);

void coakka_v2_event_service_default_subscription_config(
    coakka_v2_event_subscription_config_t *out_config);

void coakka_v2_event_service_default_checkpoint_replace_request(
    coakka_v2_event_checkpoint_replace_request_t *out_request);

const char *coakka_v2_event_admin_apply_action_name(uint32_t action);

const char *coakka_v2_event_admin_apply_disposition_name(uint32_t disposition);

const char *coakka_v2_event_checkpoint_replace_mode_name(uint32_t mode);

#ifdef __cplusplus
}
#endif

#endif
