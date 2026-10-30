#ifndef COAKKA_V2_EVENT_SERVICE_TYPES_H
#define COAKKA_V2_EVENT_SERVICE_TYPES_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Future public C ABI placeholder types for coakka-event-service.
 *
 * This header records only user-facing nouns and value types. It does not
 * promise that the current tree ships a runnable event-service implementation.
 */

typedef enum coakka_v2_event_service_status_t {
    COAKKA_V2_EVENT_SERVICE_OK = 0,
    COAKKA_V2_EVENT_SERVICE_ERR_INVALID_ARG = -1,
    COAKKA_V2_EVENT_SERVICE_ERR_NOMEM = -2,
    COAKKA_V2_EVENT_SERVICE_ERR_BAD_STATE = -3,
    COAKKA_V2_EVENT_SERVICE_ERR_NOT_IMPLEMENTED = -4,
    COAKKA_V2_EVENT_SERVICE_ERR_IO = -5,
    COAKKA_V2_EVENT_SERVICE_ERR_WOULD_BLOCK = -6,
    COAKKA_V2_EVENT_SERVICE_ERR_CLOSED = -7
} coakka_v2_event_service_status_t;

typedef enum coakka_v2_event_cursor_kind_t {
    COAKKA_V2_EVENT_CURSOR_LATEST = 0,
    COAKKA_V2_EVENT_CURSOR_BEGINNING = 1,
    COAKKA_V2_EVENT_CURSOR_EVENT_ID = 2,
    COAKKA_V2_EVENT_CURSOR_TIME_RANGE = 3,
    COAKKA_V2_EVENT_CURSOR_LOGICAL_TOKEN = 4
} coakka_v2_event_cursor_kind_t;

typedef enum coakka_v2_event_delivery_policy_t {
    COAKKA_V2_EVENT_DELIVERY_AT_LEAST_ONCE = 0,
    COAKKA_V2_EVENT_DELIVERY_SERIAL_PER_KEY = 1,
    COAKKA_V2_EVENT_DELIVERY_BEST_EFFORT_NOTIFY = 2
} coakka_v2_event_delivery_policy_t;

typedef enum coakka_v2_event_ack_policy_t {
    COAKKA_V2_EVENT_ACK_EXPLICIT = 0,
    COAKKA_V2_EVENT_ACK_ON_HANDLER_SUCCESS = 1,
    COAKKA_V2_EVENT_ACK_ON_DELIVERY_ACCEPT = 2
} coakka_v2_event_ack_policy_t;

typedef enum coakka_v2_event_subscription_mode_t {
    COAKKA_V2_EVENT_SUBSCRIPTION_EPHEMERAL = 0,
    COAKKA_V2_EVENT_SUBSCRIPTION_DURABLE = 1
} coakka_v2_event_subscription_mode_t;

typedef enum coakka_v2_event_replay_policy_t {
    COAKKA_V2_EVENT_REPLAY_NEVER = 0,
    COAKKA_V2_EVENT_REPLAY_IF_CURSOR_PRESENT = 1,
    COAKKA_V2_EVENT_REPLAY_ALWAYS = 2
} coakka_v2_event_replay_policy_t;

typedef struct coakka_v2_event_string_view_t {
    const char *data;
    size_t size;
} coakka_v2_event_string_view_t;

typedef struct coakka_v2_event_bytes_t {
    const uint8_t *data;
    size_t size;
} coakka_v2_event_bytes_t;

typedef struct coakka_v2_event_header_t {
    coakka_v2_event_string_view_t key;
    coakka_v2_event_bytes_t value;
} coakka_v2_event_header_t;

typedef struct coakka_v2_event_stream_id_t {
    size_t struct_size;
    coakka_v2_event_string_view_t namespace_name;
    coakka_v2_event_string_view_t stream_name;
} coakka_v2_event_stream_id_t;

typedef struct coakka_v2_event_publish_spec_t {
    size_t struct_size;
    coakka_v2_event_stream_id_t stream;
    coakka_v2_event_string_view_t event_type;
    coakka_v2_event_string_view_t entity_key;
    coakka_v2_event_string_view_t schema_name;
    coakka_v2_event_string_view_t producer_name;
    coakka_v2_event_string_view_t idempotency_key;
    coakka_v2_event_bytes_t payload;
    const coakka_v2_event_header_t *headers;
    size_t header_count;
    uint32_t delivery_policy;
    uint64_t event_time_unix_ms;
} coakka_v2_event_publish_spec_t;

typedef struct coakka_v2_event_selector_t {
    size_t struct_size;
    coakka_v2_event_stream_id_t stream;
    coakka_v2_event_string_view_t event_type;
    coakka_v2_event_string_view_t entity_key;
    coakka_v2_event_string_view_t consumer_name;
} coakka_v2_event_selector_t;

typedef struct coakka_v2_event_cursor_t {
    size_t struct_size;
    uint32_t kind;
    coakka_v2_event_string_view_t event_id;
    coakka_v2_event_string_view_t logical_token;
    uint64_t range_start_unix_ms;
    uint64_t range_end_unix_ms;
} coakka_v2_event_cursor_t;

typedef struct coakka_v2_event_subscription_spec_t {
    size_t struct_size;
    coakka_v2_event_selector_t selector;
    coakka_v2_event_cursor_t start_cursor;
    uint32_t ack_policy;
    uint32_t batch_limit;
    uint32_t delivery_policy;
    uint32_t subscription_mode;
    uint32_t replay_policy;
} coakka_v2_event_subscription_spec_t;

typedef struct coakka_v2_event_record_t {
    size_t struct_size;
    coakka_v2_event_stream_id_t stream;
    coakka_v2_event_string_view_t event_id;
    coakka_v2_event_string_view_t event_type;
    coakka_v2_event_string_view_t entity_key;
    coakka_v2_event_string_view_t schema_name;
    coakka_v2_event_string_view_t producer_name;
    coakka_v2_event_string_view_t idempotency_key;
    coakka_v2_event_string_view_t cursor_token;
    coakka_v2_event_bytes_t payload;
    const coakka_v2_event_header_t *headers;
    size_t header_count;
    uint64_t committed_unix_ms;
    uint64_t event_time_unix_ms;
} coakka_v2_event_record_t;

typedef struct coakka_v2_event_delivery_report_t {
    size_t struct_size;
    coakka_v2_event_string_view_t event_id;
    coakka_v2_event_string_view_t cursor_token;
    uint64_t delivered_unix_ms;
    uint64_t retry_count;
    uint32_t delivery_policy;
} coakka_v2_event_delivery_report_t;

typedef struct coakka_v2_event_service_open_options_t {
    size_t struct_size;
    const char *service_name;
    const char *node_id;
    const char *storage_profile;
    const char *operator_profile;
} coakka_v2_event_service_open_options_t;

void coakka_v2_event_service_default_stream_id(
    coakka_v2_event_stream_id_t *out_id);

void coakka_v2_event_service_default_publish_spec(
    coakka_v2_event_publish_spec_t *out_spec);

void coakka_v2_event_service_default_selector(
    coakka_v2_event_selector_t *out_selector);

void coakka_v2_event_service_default_cursor(
    coakka_v2_event_cursor_t *out_cursor);

void coakka_v2_event_service_default_subscription_spec(
    coakka_v2_event_subscription_spec_t *out_spec);

const char *coakka_v2_event_service_status_name(
    coakka_v2_event_service_status_t status);

const char *coakka_v2_event_cursor_kind_name(uint32_t kind);

const char *coakka_v2_event_delivery_policy_name(uint32_t policy);

const char *coakka_v2_event_ack_policy_name(uint32_t policy);

const char *coakka_v2_event_subscription_mode_name(uint32_t mode);

const char *coakka_v2_event_replay_policy_name(uint32_t policy);

#ifdef __cplusplus
}
#endif

#endif
