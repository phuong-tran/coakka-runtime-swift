#ifndef COAKKA_RUNTIME_BRIDGE_H
#define COAKKA_RUNTIME_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum {
    COAKKA_SWIFT_OK = 0,
    COAKKA_SWIFT_ERR_LOAD = -100,
    COAKKA_SWIFT_ERR_SYMBOL = -101
};

enum {
    COAKKA_SWIFT_STATUS_OK = 0,
    COAKKA_SWIFT_STATUS_INVALID_ARG = -1,
    COAKKA_SWIFT_STATUS_NOMEM = -2,
    COAKKA_SWIFT_STATUS_BAD_STATE = -3,
    COAKKA_SWIFT_STATUS_STALE_GENERATION = -4,
    COAKKA_SWIFT_STATUS_IO = -5,
    COAKKA_SWIFT_STATUS_WOULD_BLOCK = -6,
    COAKKA_SWIFT_STATUS_CLOSED = -7,
    COAKKA_SWIFT_STATUS_FEATURE_UNAVAILABLE = -8,
    COAKKA_SWIFT_STATUS_FEATURE_NOT_ENTITLED = -9
};

enum {
    COAKKA_SWIFT_CAPABILITY_TCP_BOUNDED_POOL = UINT64_C(1) << 0,
    COAKKA_SWIFT_CAPABILITY_TCP_POOL_TUNING = UINT64_C(1) << 1,
    COAKKA_SWIFT_CAPABILITY_TCP_TLS = UINT64_C(1) << 2,
    COAKKA_SWIFT_CAPABILITY_TCP_MUTUAL_TLS = UINT64_C(1) << 3,
    COAKKA_SWIFT_CAPABILITY_TLS_CREDENTIAL_RELOAD = UINT64_C(1) << 4,
    COAKKA_SWIFT_CAPABILITY_TLS_EXTERNAL_PROVIDER = UINT64_C(1) << 5,
    COAKKA_SWIFT_CAPABILITY_TCP_PERSISTENT_SINGLE_FLIGHT = UINT64_C(1) << 6,
    COAKKA_SWIFT_CAPABILITY_TCP_MULTIPLEXING = UINT64_C(1) << 7
};

enum {
    COAKKA_SWIFT_TCP_CONNECTION_PER_EXCHANGE = 0,
    COAKKA_SWIFT_TCP_CONNECTION_BOUNDED_POOL = 1,
    COAKKA_SWIFT_TCP_CONNECTION_PERSISTENT_SINGLE_FLIGHT = 2,
    COAKKA_SWIFT_TCP_CONNECTION_MULTIPLEXING = 3
};

enum {
    COAKKA_SWIFT_TCP_CONNECTION_FIELD_MODE = UINT64_C(1) << 0,
    COAKKA_SWIFT_TCP_CONNECTION_FIELD_MAX_CONNECTIONS = UINT64_C(1) << 1,
    COAKKA_SWIFT_TCP_CONNECTION_FIELD_MAX_REQUESTS_PER_CONNECTION = UINT64_C(1) << 2,
    COAKKA_SWIFT_TCP_CONNECTION_FIELD_IDLE_TIMEOUT_MS = UINT64_C(1) << 3
};

enum {
    COAKKA_SWIFT_TCP_SECURITY_PLAINTEXT = 0,
    COAKKA_SWIFT_TCP_SECURITY_TLS = 1,
    COAKKA_SWIFT_TCP_SECURITY_MUTUAL_TLS = 2,
    COAKKA_SWIFT_TLS_CREDENTIAL_SOURCE_FILE = 1,
    COAKKA_SWIFT_TLS_RELOAD_GRACEFUL = 0,
    COAKKA_SWIFT_TLS_RELOAD_DRAIN_EXISTING_CONNECTIONS = 1
};

enum {
    COAKKA_SWIFT_TCP_SECURITY_FIELD_MODE = UINT64_C(1) << 0,
    COAKKA_SWIFT_TCP_SECURITY_FIELD_CREDENTIAL_SOURCE = UINT64_C(1) << 1,
    COAKKA_SWIFT_TCP_SECURITY_FIELD_RELOAD_MODE = UINT64_C(1) << 2,
    COAKKA_SWIFT_TCP_SECURITY_FIELD_CREDENTIAL_GENERATION = UINT64_C(1) << 3,
    COAKKA_SWIFT_TCP_SECURITY_FIELD_CREDENTIAL_ID = UINT64_C(1) << 4,
    COAKKA_SWIFT_TCP_SECURITY_FIELD_CA_CERTIFICATE_FILE = UINT64_C(1) << 5,
    COAKKA_SWIFT_TCP_SECURITY_FIELD_IDENTITY_CERTIFICATE_FILE = UINT64_C(1) << 6,
    COAKKA_SWIFT_TCP_SECURITY_FIELD_PRIVATE_KEY_FILE = UINT64_C(1) << 7,
    COAKKA_SWIFT_TCP_SECURITY_ALL_FIELDS = (UINT64_C(1) << 8) - 1
};

enum {
    COAKKA_SWIFT_STATE_CREATED = 0,
    COAKKA_SWIFT_STATE_STARTED = 1,
    COAKKA_SWIFT_STATE_STOPPED = 2
};

enum {
    COAKKA_SWIFT_HOST_ENABLE_MONITOR = 1u << 0,
    COAKKA_SWIFT_HOST_SEPARATE_DELIVERED_REQUEST_LANE = 1u << 1
};

enum {
    COAKKA_SWIFT_ENDPOINT_LOCAL = 1u << 0
};

enum {
    COAKKA_SWIFT_NETWORK_EMBEDDED = 1,
    COAKKA_SWIFT_NETWORK_OUTBOUND_ONLY = 2,
    COAKKA_SWIFT_NETWORK_NODE = 3
};

enum {
    COAKKA_SWIFT_ROUTE_SINGLE_OWNER = 1
};

enum {
    COAKKA_SWIFT_CLIENT_RESULT_RESPONSE = 1,
    COAKKA_SWIFT_CLIENT_RESULT_DEADLETTER = 2
};

enum {
    COAKKA_SWIFT_DELIVERY_ROUTER_DEFAULT = 1,
    COAKKA_SWIFT_DELIVERY_REQUIRE_LOCAL = 3
};

typedef struct coakka_swift_runtime_library_t coakka_swift_runtime_library_t;
typedef struct coakka_swift_runtime_t coakka_swift_runtime_t;
typedef struct coakka_swift_ask_client_t coakka_swift_ask_client_t;
typedef struct coakka_swift_ask_ticket_t coakka_swift_ask_ticket_t;
typedef struct coakka_swift_frame_reader_t coakka_swift_frame_reader_t;
typedef struct coakka_swift_file_lane_t coakka_swift_file_lane_t;
typedef struct coakka_swift_stream_lane_t coakka_swift_stream_lane_t;

typedef struct coakka_swift_file_lane_security_config_t {
  size_t struct_size;
  uint32_t mode;
  uint32_t reserved;
  uint64_t credential_generation;
  const char *credential_id;
  const char *ca_certificate_file;
  const char *identity_certificate_file;
  const char *private_key_file;
} coakka_swift_file_lane_security_config_t;

typedef struct coakka_swift_file_lane_config_t {
  size_t struct_size;
  uint32_t flags;
  const char *bind_host;
  uint16_t bind_port;
  size_t queue_capacity;
  uint64_t max_file_size;
  uint32_t io_timeout_ms;
  uint64_t checkpoint_bytes;
  uint64_t progress_bytes;
  uint32_t progress_interval_ms;
  uint32_t sender_worker_count;
  uint32_t receiver_worker_count;
  const coakka_swift_file_lane_security_config_t *security;
} coakka_swift_file_lane_config_t;

typedef struct coakka_swift_lane_owner_config_t {
  size_t struct_size;
  const char *owner_instance_id;
  const char *advertised_host;
} coakka_swift_lane_owner_config_t;

typedef struct coakka_swift_lane_owner_endpoint_t {
  size_t struct_size;
  uint16_t port;
  uint16_t reserved;
  char owner_instance_id[128];
  char advertised_host[256];
} coakka_swift_lane_owner_endpoint_t;

typedef struct coakka_swift_file_lane_owned_config_t {
  size_t struct_size;
  coakka_swift_file_lane_config_t lane;
  coakka_swift_lane_owner_config_t owner;
} coakka_swift_file_lane_owned_config_t;

typedef struct coakka_swift_file_receive_grant_t {
  size_t struct_size;
  coakka_swift_lane_owner_endpoint_t owner;
  char transfer_id[65];
  char authorization_token[129];
  uint64_t expected_size;
  uint8_t expected_sha256[32];
} coakka_swift_file_receive_grant_t;

typedef struct coakka_swift_file_transfer_snapshot_t {
  size_t struct_size;
  uint32_t direction;
  uint32_t state;
  uint32_t result;
  uint64_t expected_size;
  uint64_t transferred_bytes;
  uint64_t committed_offset;
  uint32_t progress_milli;
  uint32_t cancel_requested;
  uint64_t update_sequence;
  uint64_t submitted_mono_ns;
  uint64_t started_mono_ns;
  uint64_t updated_mono_ns;
  uint64_t terminal_mono_ns;
  char detail[160];
} coakka_swift_file_transfer_snapshot_t;

typedef struct coakka_swift_file_lane_stats_t {
  size_t struct_size;
  size_t queue_capacity;
  size_t queued_sends;
  size_t prepared_receives;
  size_t active_sends;
  size_t active_receives;
  size_t retained_records;
  uint64_t submitted_sends;
  uint64_t prepared_receive_count;
  uint64_t completed_sends;
  uint64_t completed_receives;
  uint64_t failed_sends;
  uint64_t failed_receives;
  uint64_t canceled_transfers;
  uint64_t completed_send_bytes;
  uint64_t completed_receive_bytes;
} coakka_swift_file_lane_stats_t;

typedef struct coakka_swift_stream_frame_t {
  size_t struct_size;
  uint64_t sequence;
  uint64_t captured_mono_ns;
  uint64_t dropped_before;
  uint32_t flags;
  size_t size;
} coakka_swift_stream_frame_t;

typedef int32_t (*coakka_swift_stream_source_fn)(
    void *context, uint8_t *destination, size_t capacity,
    coakka_swift_stream_frame_t *out_frame);
typedef int32_t (*coakka_swift_stream_consumer_fn)(
    void *context, const uint8_t *data,
    const coakka_swift_stream_frame_t *frame);

typedef struct coakka_swift_stream_security_config_t {
  size_t struct_size;
  uint32_t mode;
  uint32_t reserved;
  uint64_t credential_generation;
  const char *credential_id;
  const char *ca_certificate_file;
  const char *identity_certificate_file;
  const char *private_key_file;
} coakka_swift_stream_security_config_t;

typedef struct coakka_swift_stream_config_t {
  size_t struct_size;
  uint32_t flags;
  const char *bind_host;
  uint16_t bind_port;
  size_t capacity;
  uint32_t max_frame_bytes;
  uint32_t max_window_bytes;
  uint32_t io_timeout_ms;
  uint32_t source_retry_ms;
  uint32_t progress_frames;
  uint32_t progress_interval_ms;
  uint32_t publisher_worker_count;
  uint32_t subscriber_worker_count;
  const coakka_swift_stream_security_config_t *security;
  uint32_t pressure_after_ms;
  uint32_t stalled_after_ms;
  uint32_t recovery_after_ms;
  uint32_t pressure_observation_ms;
} coakka_swift_stream_config_t;

typedef struct coakka_swift_stream_owned_config_t {
  size_t struct_size;
  coakka_swift_stream_config_t lane;
  coakka_swift_lane_owner_config_t owner;
} coakka_swift_stream_owned_config_t;

typedef struct coakka_swift_stream_publish_grant_t {
  size_t struct_size;
  coakka_swift_lane_owner_endpoint_t owner;
  char session_id[65];
  char authorization_token[129];
  uint64_t format_id;
  uint32_t max_frame_bytes;
  uint32_t reserved;
} coakka_swift_stream_publish_grant_t;

typedef struct coakka_swift_stream_session_snapshot_t {
  size_t struct_size;
  uint32_t direction;
  uint32_t state;
  uint32_t result;
  uint64_t format_id;
  uint64_t frames;
  uint64_t bytes;
  uint64_t dropped_frames;
  uint64_t last_sequence;
  uint32_t negotiated_max_frame_bytes;
  uint32_t window_bytes;
  uint32_t cancel_requested;
  uint64_t update_sequence;
  uint64_t submitted_mono_ns;
  uint64_t started_mono_ns;
  uint64_t updated_mono_ns;
  uint64_t terminal_mono_ns;
  char detail[160];
} coakka_swift_stream_session_snapshot_t;

typedef struct coakka_swift_stream_pressure_snapshot_t {
  size_t struct_size;
  uint32_t direction;
  uint32_t state;
  uint32_t reason_bits;
  uint32_t available_credit_bytes;
  uint32_t window_capacity_bytes;
  uint64_t update_sequence;
  uint64_t transition_count;
  uint64_t observed_mono_ns;
  uint64_t state_started_mono_ns;
  uint64_t pressure_started_mono_ns;
  uint64_t last_progress_mono_ns;
  uint64_t observed_delivery_bps;
  uint64_t current_operation_ns;
  uint64_t last_operation_ns;
  uint64_t total_pressured_ns;
  uint64_t max_pressured_ns;
} coakka_swift_stream_pressure_snapshot_t;

typedef struct coakka_swift_stream_stats_t {
  size_t struct_size;
  size_t capacity;
  size_t queued_subscribers;
  size_t prepared_publishers;
  size_t active_publishers;
  size_t active_subscribers;
  size_t retained_records;
  uint64_t submitted_subscribers;
  uint64_t prepared_publisher_count;
  uint64_t ended_publishers;
  uint64_t ended_subscribers;
  uint64_t failed_publishers;
  uint64_t failed_subscribers;
  uint64_t canceled_sessions;
  uint64_t published_frames;
  uint64_t published_bytes;
  uint64_t consumed_frames;
  uint64_t consumed_bytes;
  uint64_t source_reported_drops;
} coakka_swift_stream_stats_t;

typedef struct coakka_swift_host_handles_t {
    size_t struct_size;
    uint32_t flags;
    int request_write_fd;
    int response_read_fd;
    int deadletter_read_fd;
    int control_write_fd;
    int monitor_read_fd;
    int delivered_request_read_fd;
} coakka_swift_host_handles_t;

typedef struct coakka_swift_runtime_info_t {
    size_t struct_size;
    uint32_t abi_version;
    uint32_t feature_flags;
    const char *runtime_version;
    const char *git_commit;
    const char *backend;
} coakka_swift_runtime_info_t;

typedef struct coakka_swift_runtime_config_view_t {
    size_t struct_size;
    const char *system_name;
    const char *node_id;
    int strict_no_drop;
    int queue_capacity;
    int runtime_state;
    uint32_t snapshot_present;
    uint64_t applied_generation;
    size_t route_count;
} coakka_swift_runtime_config_view_t;

typedef struct coakka_swift_runtime_health_t {
    size_t struct_size;
    int runtime_state;
    uint32_t flags;
    uint64_t applied_generation;
} coakka_swift_runtime_health_t;

typedef struct coakka_swift_runtime_stats_t {
    size_t struct_size;
    uint64_t applied_generation;
    size_t route_count;
    int runtime_state;
    size_t ingress_queue_capacity;
    size_t ingress_queue_depth;
    size_t ingress_queue_high_watermark;
    uint64_t queue_rejected_count;
    uint64_t route_miss_count;
    uint64_t deadletter_count;
    uint64_t delivery_failed_count;
} coakka_swift_runtime_stats_t;

typedef struct coakka_swift_runtime_capabilities_t {
    size_t struct_size;
    uint32_t edition;
    uint32_t license_status;
    uint64_t compiled_capabilities;
    uint64_t entitled_capabilities;
    uint64_t effective_capabilities;
    uint32_t tcp_connection_defaults_revision;
    uint32_t reserved;
} coakka_swift_runtime_capabilities_t;

typedef struct coakka_swift_tcp_connection_options_t {
    size_t struct_size;
    uint64_t fields;
    uint32_t mode;
    uint32_t reserved;
    uint32_t max_connections;
    uint32_t reserved2;
    uint64_t max_requests_per_connection;
    uint64_t idle_timeout_ms;
} coakka_swift_tcp_connection_options_t;

typedef struct coakka_swift_tcp_connection_validation_t {
    size_t struct_size;
    uint32_t code;
    uint32_t reserved;
    uint64_t field;
    uint64_t minimum_value;
    uint64_t maximum_value;
} coakka_swift_tcp_connection_validation_t;

typedef struct coakka_swift_tcp_connection_config_t {
    size_t struct_size;
    uint32_t defaults_revision;
    uint32_t mode;
    uint64_t applicable_fields;
    uint64_t explicitly_configured_fields;
    uint64_t defaulted_fields;
    uint64_t configurable_fields;
    uint32_t max_connections;
    uint32_t reserved;
    uint64_t max_requests_per_connection;
    uint64_t idle_timeout_ms;
} coakka_swift_tcp_connection_config_t;

typedef struct coakka_swift_tcp_connection_apply_result_t {
    size_t struct_size;
    int32_t apply_status;
    uint32_t changed;
    uint32_t reason;
    uint32_t runtime_state;
    coakka_swift_tcp_connection_validation_t validation;
    coakka_swift_tcp_connection_config_t effective_config;
} coakka_swift_tcp_connection_apply_result_t;

typedef struct coakka_swift_tcp_security_options_t {
    size_t struct_size;
    uint64_t fields;
    uint32_t mode;
    uint32_t credential_source_kind;
    uint32_t reload_mode;
    uint32_t reserved;
    uint64_t credential_generation;
    const char *credential_id;
    const char *ca_certificate_file;
    const char *identity_certificate_file;
    const char *private_key_file;
} coakka_swift_tcp_security_options_t;

typedef struct coakka_swift_tcp_security_validation_t {
    size_t struct_size;
    uint32_t code;
    uint32_t reserved;
    uint64_t field;
} coakka_swift_tcp_security_validation_t;

typedef struct coakka_swift_tcp_security_config_t {
    size_t struct_size;
    uint32_t mode;
    uint32_t credential_source_kind;
    uint32_t reload_mode;
    uint32_t reload_status;
    uint64_t credential_generation;
    const char *credential_id;
} coakka_swift_tcp_security_config_t;

typedef struct coakka_swift_tcp_security_identity_t {
    size_t struct_size;
    uint32_t minimum_protocol_version;
    uint32_t maximum_protocol_version;
    uint64_t inbound_verification_flags;
    uint64_t outbound_verification_flags;
    int64_t identity_not_before_unix_seconds;
    int64_t identity_not_after_unix_seconds;
    char credential_id_value[128];
    char identity_fingerprint_sha256[65];
} coakka_swift_tcp_security_identity_t;

typedef struct coakka_swift_tcp_security_info_t {
    size_t struct_size;
    coakka_swift_tcp_security_config_t config;
    coakka_swift_tcp_security_identity_t identity;
} coakka_swift_tcp_security_info_t;

typedef struct coakka_swift_tcp_security_apply_result_t {
    size_t struct_size;
    int32_t apply_status;
    uint32_t changed;
    uint32_t reason;
    uint32_t runtime_state;
    coakka_swift_tcp_security_validation_t validation;
    coakka_swift_tcp_security_info_t active_security;
} coakka_swift_tcp_security_apply_result_t;

typedef struct coakka_swift_endpoint_spec_t {
    const char *host;
    uint16_t port;
    uint32_t weight;
    uint32_t flags;
} coakka_swift_endpoint_spec_t;

typedef struct coakka_swift_route_spec_t {
    const char *target;
    uint32_t strategy;
    const char *route_key_hint;
    uint32_t flags;
    const coakka_swift_endpoint_spec_t *endpoints;
    size_t endpoint_count;
} coakka_swift_route_spec_t;

typedef struct coakka_swift_raw_request_spec_t {
    size_t struct_size;
    const char *message_id;
    const char *source;
    const char *target;
    const char *reply_to;
    const uint8_t *payload;
    size_t payload_len;
    uint32_t timeout_ms;
    uint32_t delivery_hint;
    uint32_t one_way;
} coakka_swift_raw_request_spec_t;

typedef struct coakka_swift_raw_reply_spec_t {
    size_t struct_size;
    const uint8_t *request_buf;
    size_t request_len;
    const char *source;
    const uint8_t *payload;
    size_t payload_len;
} coakka_swift_raw_reply_spec_t;

/**
 * Common contract for this C bridge.
 *
 * `library` arguments are borrowed. The library must remain open until every
 * runtime, ask client, ticket, frame reader, and native buffer created through
 * it has been released. The bridge does not serialize close/destroy against
 * concurrent calls; the Swift owner must do so. Calls are synchronous unless a
 * function explicitly documents a bounded wait. Runtime status values are
 * forwarded unchanged; bridge loader failures use COAKKA_SWIFT_ERR_LOAD or
 * COAKKA_SWIFT_ERR_SYMBOL. Capability-gated APIs remain present in every
 * edition and report FEATURE_UNAVAILABLE or FEATURE_NOT_ENTITLED at runtime.
 */

/**
 * Opens one runtime shared library and resolves the complete bridge symbol set.
 * `path` is borrowed for this potentially blocking loader call. On success,
 * the caller owns `*out_library`; close it after all dependent objects. When
 * provided, `error_buf` receives a truncated NUL-terminated diagnostic.
 */
int32_t coakka_swift_runtime_library_open(const char *path,
                                          coakka_swift_runtime_library_t **out_library,
                                          char *error_buf,
                                          size_t error_buf_len);

/**
 * Closes a library opened by coakka_swift_runtime_library_open(). This may run
 * platform loader finalizers. NULL is ignored; concurrent use is invalid.
 */
void coakka_swift_runtime_library_close(coakka_swift_runtime_library_t *library);

/**
 * Returns the loaded runtime's ABI version, or 0 for NULL. The returned scalar
 * has no lifetime dependency beyond the call and the function does not block.
 */
uint32_t coakka_swift_runtime_get_abi_version(coakka_swift_runtime_library_t *library);

/**
 * Reads immutable build/runtime metadata. String pointers in `out_info` are
 * borrowed from the loaded module and remain valid only while `library` is
 * open. Returns INVALID_ARG for NULL input and otherwise forwards status.
 */
int32_t coakka_swift_runtime_get_info(coakka_swift_runtime_library_t *library,
                                      coakka_swift_runtime_info_t *out_info);

/**
 * Creates a runtime in CREATED state. Names are borrowed only for this call;
 * the runtime copies them. `strict_no_drop` defaults at the Swift layer and
 * `queue_capacity` must be positive. The caller owns the returned runtime and
 * receives NULL on validation/allocation failure.
 */
coakka_swift_runtime_t *coakka_swift_runtime_create(coakka_swift_runtime_library_t *library,
                                                    const char *system_name,
                                                    const char *node_id,
                                                    int strict_no_drop,
                                                    int queue_capacity);

/**
 * Destroys one runtime after stop, or after a startup failure. Destruction is
 * synchronous and may wait for runtime-owned cleanup. NULL is ignored; no
 * other thread may use `runtime` during or after this call.
 */
void coakka_swift_runtime_destroy(coakka_swift_runtime_library_t *library,
                                  coakka_swift_runtime_t *runtime);

/** Applies an explicit startup-only listener participation policy. */
int32_t coakka_swift_runtime_apply_network(coakka_swift_runtime_library_t *library,
                                           coakka_swift_runtime_t *runtime,
                                           uint32_t mode,
                                           const char *bind_host,
                                           uint16_t bind_port,
                                           const char *advertise_host,
                                           uint16_t advertise_port);

/**
 * Exports host-owned descriptor lanes exactly once while runtime is CREATED.
 * `flags` selects optional lanes; `out_handles` is initialized by the bridge.
 * Close every returned descriptor with coakka_swift_host_handles_close().
 */
int32_t coakka_swift_runtime_get_host_handles(coakka_swift_runtime_library_t *library,
                                              coakka_swift_runtime_t *runtime,
                                              uint32_t flags,
                                              coakka_swift_host_handles_t *out_handles);

/**
 * Closes each distinct non-negative descriptor in `handles` exactly once and
 * replaces all descriptor fields with -1. The call is idempotent but must not
 * race readers, writers, frame readers, or ask clients using those lanes.
 */
void coakka_swift_host_handles_close(coakka_swift_host_handles_t *handles);

/**
 * Starts a CREATED runtime after handles and a control snapshot are installed.
 * Startup is synchronous and may initialize threads/listeners. Returns
 * BAD_STATE for an incomplete or already-used lifecycle.
 */
int32_t coakka_swift_runtime_start(coakka_swift_runtime_library_t *library,
                                   coakka_swift_runtime_t *runtime);

/**
 * Stops a STARTED runtime and waits for its workers to terminate. Stop is a
 * terminal transition for this runtime instance; restart returns BAD_STATE.
 */
int32_t coakka_swift_runtime_stop(coakka_swift_runtime_library_t *library,
                                  coakka_swift_runtime_t *runtime);

/**
 * Atomically replaces route state with one strictly newer `generation`.
 * Route strings and endpoint arrays are borrowed only for this synchronous
 * call and copied before return. `routes` may be NULL only when count is zero.
 * Invalid/stale/allocation failures preserve the active snapshot.
 */
int32_t coakka_swift_runtime_apply_snapshot(coakka_swift_runtime_library_t *library,
                                            coakka_swift_runtime_t *runtime,
                                            uint64_t generation,
                                            const coakka_swift_route_spec_t *routes,
                                            size_t route_count);

/**
 * Submits one serialized envelope to a STARTED runtime without retaining
 * `buf`. The call is non-blocking with respect to bounded admission and returns
 * WOULD_BLOCK when capacity is unavailable, plus BAD_STATE/CLOSED by lifecycle.
 */
int32_t coakka_swift_runtime_submit_envelope(coakka_swift_runtime_library_t *library,
                                             coakka_swift_runtime_t *runtime,
                                             const uint8_t *buf,
                                             size_t len);

/**
 * Reads one coherent runtime configuration snapshot. Returned name pointers
 * are runtime-owned and valid until runtime destruction; Swift callers should
 * copy them before releasing their serialized access to the runtime.
 */
int32_t coakka_swift_runtime_get_config(coakka_swift_runtime_library_t *library,
                                        coakka_swift_runtime_t *runtime,
                                        coakka_swift_runtime_config_view_t *out_config);

/** Reads a coherent, non-blocking health snapshot into bridge-initialized storage. */
int32_t coakka_swift_runtime_get_health(coakka_swift_runtime_library_t *library,
                                        coakka_swift_runtime_t *runtime,
                                        coakka_swift_runtime_health_t *out_health);

/** Reads coherent counters and queue depths into bridge-initialized storage. */
int32_t coakka_swift_runtime_get_stats(coakka_swift_runtime_library_t *library,
                                       coakka_swift_runtime_t *runtime,
                                       coakka_swift_runtime_stats_t *out_stats);

/**
 * Reads process-wide compiled, entitled, and effective capability masks. This
 * query is edition-independent, does not require a runtime instance, and does
 * not expose license secrets.
 */
int32_t coakka_swift_runtime_get_capabilities(coakka_swift_runtime_library_t *library,
                                              coakka_swift_runtime_capabilities_t *out_capabilities);

/**
 * Validates and atomically applies startup-only TCP connection options.
 * Caller-owned `options` strings/storage are borrowed for the call; both
 * structs must advertise `struct_size`. `out_result` always describes the
 * effective config when the core can project it. Failed apply preserves state.
 */
int32_t coakka_swift_runtime_apply_tcp_connection_options(
    coakka_swift_runtime_library_t *library,
    coakka_swift_runtime_t *runtime,
    const coakka_swift_tcp_connection_options_t *options,
    coakka_swift_tcp_connection_apply_result_t *out_result);

/** Reads the runtime's effective connection policy into caller-owned storage. */
int32_t coakka_swift_runtime_get_tcp_connection_config(
    coakka_swift_runtime_library_t *library,
    coakka_swift_runtime_t *runtime,
    coakka_swift_tcp_connection_config_t *out_config);

/**
 * Applies initial TLS policy or reloads a newer credential generation.
 * Credential paths and ids are borrowed only during this synchronous,
 * potentially file-I/O-blocking call. Failure preserves the active immutable
 * security context and `out_result` exposes non-secret active state only.
 */
int32_t coakka_swift_runtime_apply_tcp_security_options(
    coakka_swift_runtime_library_t *library,
    coakka_swift_runtime_t *runtime,
    const coakka_swift_tcp_security_options_t *options,
    coakka_swift_tcp_security_apply_result_t *out_result);

/**
 * Reads non-secret active TCP security metadata. Any pointer fields are
 * runtime-owned and must be copied before a concurrent reload or destroy.
 */
int32_t coakka_swift_runtime_get_tcp_security_info(
    coakka_swift_runtime_library_t *library,
    coakka_swift_runtime_t *runtime,
    coakka_swift_tcp_security_info_t *out_info);

/**
 * Returns a module-owned static name for a structured transport apply reason.
 * The pointer remains valid while `library` is open; NULL library yields
 * "UNKNOWN". This helper is non-blocking and available in every edition.
 */
const char *coakka_swift_transport_apply_reason_name(coakka_swift_runtime_library_t *library,
                                                     uint32_t reason);

/**
 * Creates connector-side request/reply matching over exported terminal lanes.
 * `runtime` and `handles` are borrowed and must outlive the client. Creation
 * may allocate/start reader state and returns NULL on invalid input/failure.
 */
coakka_swift_ask_client_t *coakka_swift_ask_client_create(coakka_swift_runtime_library_t *library,
                                                          coakka_swift_runtime_t *runtime,
                                                          const coakka_swift_host_handles_t *handles);

/**
 * Destroys ask matching state after all tickets are destroyed. The call may
 * join connector-side reader work and must not race begin/await operations.
 */
void coakka_swift_ask_client_destroy(coakka_swift_runtime_library_t *library,
                                     coakka_swift_ask_client_t *client);

/**
 * Submits one request frame and returns a caller-owned ticket. `request_buf` is
 * borrowed for this call. On failure `*out_ticket` is NULL; CLOSED means the
 * terminal lanes are no longer usable.
 */
int32_t coakka_swift_ask_client_begin(coakka_swift_runtime_library_t *library,
                                      coakka_swift_ask_client_t *client,
                                      const uint8_t *request_buf,
                                      size_t request_len,
                                      coakka_swift_ask_ticket_t **out_ticket);

/**
 * Waits at most `timeout_ms` for a matched response or deadletter. OK transfers
 * `*out_buf` to the caller for release with coakka_swift_client_bytes_release().
 * WOULD_BLOCK leaves the ticket pending; CLOSED reports terminal lane closure.
 * A ticket must not be awaited concurrently by multiple threads.
 */
int32_t coakka_swift_ask_ticket_await(coakka_swift_runtime_library_t *library,
                                      coakka_swift_ask_ticket_t *ticket,
                                      uint32_t timeout_ms,
                                      uint32_t *out_result_kind,
                                      uint8_t **out_buf,
                                      size_t *out_len);

/**
 * Returns a ticket-owned message-id pointer, valid until ticket destruction.
 * Invalid input returns an empty static string. Do not race with destroy.
 */
const char *coakka_swift_ask_ticket_message_id(coakka_swift_runtime_library_t *library,
                                               const coakka_swift_ask_ticket_t *ticket);

/** Releases one ticket and any still-pending connector state; NULL is ignored. */
void coakka_swift_ask_ticket_destroy(coakka_swift_runtime_library_t *library,
                                     coakka_swift_ask_ticket_t *ticket);

/**
 * Builds one serialized request. Spec strings/payload are borrowed during the
 * synchronous build. OK transfers `*out_buf` to the caller; release it with
 * coakka_swift_client_bytes_release(). Validation/allocation failures return a
 * status and no usable buffer.
 */
int32_t coakka_swift_build_raw_request(coakka_swift_runtime_library_t *library,
                                       const coakka_swift_raw_request_spec_t *spec,
                                       uint8_t **out_buf,
                                       size_t *out_len);

/**
 * Builds a reply to one delivered request frame. Request and payload spans are
 * borrowed for the synchronous build. The caller owns a successful output and
 * releases it with coakka_swift_client_bytes_release().
 */
int32_t coakka_swift_build_raw_reply(coakka_swift_runtime_library_t *library,
                                     const coakka_swift_raw_reply_spec_t *spec,
                                     uint8_t **out_buf,
                                     size_t *out_len);

/** Releases a buffer returned by bridge request/reply or ask-ticket APIs. */
void coakka_swift_client_bytes_release(coakka_swift_runtime_library_t *library,
                                       uint8_t *buf);

/**
 * Creates a bounded, non-owning reader over `fd`; `max_frame_size` must be
 * positive. The caller owns the reader and remains responsible for closing the
 * descriptor after reader destruction.
 */
coakka_swift_frame_reader_t *coakka_swift_frame_reader_create(coakka_swift_runtime_library_t *library,
                                                              int fd,
                                                              size_t max_frame_size);

/** Destroys a frame reader without closing its borrowed descriptor. */
void coakka_swift_frame_reader_destroy(coakka_swift_runtime_library_t *library,
                                       coakka_swift_frame_reader_t *reader);

/**
 * Attempts one incremental frame read without waiting for future bytes.
 * WOULD_BLOCK means no complete frame is ready. OK transfers `*out_buf` to the
 * caller for release with coakka_swift_frame_release(). Serialize access to a
 * given reader; it owns mutable partial-frame state.
 */
int32_t coakka_swift_frame_read_try(coakka_swift_runtime_library_t *library,
                                    coakka_swift_frame_reader_t *reader,
                                    uint8_t **out_buf,
                                    size_t *out_len);

/** Releases a frame buffer returned by coakka_swift_frame_read_try(). */
void coakka_swift_frame_release(coakka_swift_runtime_library_t *library,
                                uint8_t *buf);

int32_t coakka_swift_file_lane_available(coakka_swift_runtime_library_t *library);
int32_t coakka_swift_lane_owner_grants_available(coakka_swift_runtime_library_t *library);
int32_t coakka_swift_file_lane_create(coakka_swift_runtime_library_t *library, const coakka_swift_file_lane_config_t *config, coakka_swift_file_lane_t **out_lane);
int32_t coakka_swift_file_lane_create_owned(coakka_swift_runtime_library_t *library, const coakka_swift_file_lane_owned_config_t *config, coakka_swift_file_lane_t **out_lane);
void coakka_swift_file_lane_destroy(coakka_swift_runtime_library_t *library, coakka_swift_file_lane_t *lane);
int32_t coakka_swift_file_lane_start(coakka_swift_runtime_library_t *library, coakka_swift_file_lane_t *lane);
int32_t coakka_swift_file_lane_stop(coakka_swift_runtime_library_t *library, coakka_swift_file_lane_t *lane);
int32_t coakka_swift_file_lane_get_bound_port(coakka_swift_runtime_library_t *library, coakka_swift_file_lane_t *lane, uint16_t *out_port);
int32_t coakka_swift_file_lane_prepare_receive(coakka_swift_runtime_library_t *library, coakka_swift_file_lane_t *lane, const char *transfer_id, const char *token, const char *path, uint64_t size, const uint8_t sha256[32]);
int32_t coakka_swift_file_lane_prepare_receive_grant(coakka_swift_runtime_library_t *library, coakka_swift_file_lane_t *lane, const char *transfer_id, const char *token, const char *path, uint64_t size, const uint8_t sha256[32], coakka_swift_file_receive_grant_t *out_grant);
int32_t coakka_swift_file_lane_submit_send(coakka_swift_runtime_library_t *library, coakka_swift_file_lane_t *lane, const char *transfer_id, const char *token, const char *host, uint16_t port, const char *path, uint64_t size, const uint8_t sha256[32], uint32_t timeout_ms);
int32_t coakka_swift_file_lane_get_transfer(coakka_swift_runtime_library_t *library, coakka_swift_file_lane_t *lane, const char *transfer_id, uint32_t direction, coakka_swift_file_transfer_snapshot_t *out_snapshot);
int32_t coakka_swift_file_lane_wait_transfer(coakka_swift_runtime_library_t *library, coakka_swift_file_lane_t *lane, const char *transfer_id, uint32_t direction, uint64_t after_sequence, uint32_t timeout_ms, coakka_swift_file_transfer_snapshot_t *out_snapshot);
int32_t coakka_swift_file_lane_cancel(coakka_swift_runtime_library_t *library, coakka_swift_file_lane_t *lane, const char *transfer_id, uint32_t direction);
int32_t coakka_swift_file_lane_forget(coakka_swift_runtime_library_t *library, coakka_swift_file_lane_t *lane, const char *transfer_id, uint32_t direction);
int32_t coakka_swift_file_lane_get_stats(coakka_swift_runtime_library_t *library, coakka_swift_file_lane_t *lane, coakka_swift_file_lane_stats_t *out_stats);
int32_t coakka_swift_file_sha256_path(coakka_swift_runtime_library_t *library, const char *path, uint8_t out_sha256[32], uint64_t *out_size);

int32_t coakka_swift_stream_available(coakka_swift_runtime_library_t *library);
int32_t coakka_swift_stream_create(coakka_swift_runtime_library_t *library,
                                   const coakka_swift_stream_config_t *config,
                                   coakka_swift_stream_lane_t **out_lane);
int32_t coakka_swift_stream_create_owned(coakka_swift_runtime_library_t *library,
                                         const coakka_swift_stream_owned_config_t *config,
                                         coakka_swift_stream_lane_t **out_lane);
void coakka_swift_stream_destroy(coakka_swift_runtime_library_t *library,
                                 coakka_swift_stream_lane_t *lane);
int32_t coakka_swift_stream_start(coakka_swift_runtime_library_t *library,
                                  coakka_swift_stream_lane_t *lane);
int32_t coakka_swift_stream_stop(coakka_swift_runtime_library_t *library,
                                 coakka_swift_stream_lane_t *lane);
int32_t coakka_swift_stream_bound_port(coakka_swift_runtime_library_t *library,
                                       coakka_swift_stream_lane_t *lane,
                                       uint16_t *out_port);
int32_t coakka_swift_stream_prepare_publish(
    coakka_swift_runtime_library_t *library, coakka_swift_stream_lane_t *lane,
    const char *session_id, const char *token, uint64_t format_id,
    uint32_t max_frame_bytes, coakka_swift_stream_source_fn source,
    void *context);
int32_t coakka_swift_stream_prepare_publish_grant(
    coakka_swift_runtime_library_t *library, coakka_swift_stream_lane_t *lane,
    const char *session_id, const char *token, uint64_t format_id,
    uint32_t max_frame_bytes, coakka_swift_stream_source_fn source,
    void *context, coakka_swift_stream_publish_grant_t *out_grant);
int32_t coakka_swift_stream_subscribe(
    coakka_swift_runtime_library_t *library, coakka_swift_stream_lane_t *lane,
    const char *session_id, const char *token, const char *host, uint16_t port,
    uint64_t format_id, uint32_t max_frame_bytes, uint32_t window_bytes,
    uint32_t timeout_ms, coakka_swift_stream_consumer_fn consumer,
    void *context);
int32_t coakka_swift_stream_get_session(
    coakka_swift_runtime_library_t *library, coakka_swift_stream_lane_t *lane,
    const char *session_id, uint32_t direction,
    coakka_swift_stream_session_snapshot_t *out_snapshot);
int32_t coakka_swift_stream_wait_session(
    coakka_swift_runtime_library_t *library, coakka_swift_stream_lane_t *lane,
    const char *session_id, uint32_t direction, uint64_t after_sequence,
    uint32_t timeout_ms, coakka_swift_stream_session_snapshot_t *out_snapshot);
int32_t coakka_swift_stream_get_pressure(
    coakka_swift_runtime_library_t *library, coakka_swift_stream_lane_t *lane,
    const char *session_id, uint32_t direction,
    coakka_swift_stream_pressure_snapshot_t *out_snapshot);
int32_t coakka_swift_stream_wait_pressure(
    coakka_swift_runtime_library_t *library, coakka_swift_stream_lane_t *lane,
    const char *session_id, uint32_t direction, uint64_t after_sequence,
    uint32_t timeout_ms, coakka_swift_stream_pressure_snapshot_t *out_snapshot);
int32_t coakka_swift_stream_cancel(coakka_swift_runtime_library_t *library,
                                   coakka_swift_stream_lane_t *lane,
                                   const char *session_id, uint32_t direction);
int32_t coakka_swift_stream_forget(coakka_swift_runtime_library_t *library,
                                   coakka_swift_stream_lane_t *lane,
                                   const char *session_id, uint32_t direction);
int32_t coakka_swift_stream_stats(coakka_swift_runtime_library_t *library,
                                  coakka_swift_stream_lane_t *lane,
                                  coakka_swift_stream_stats_t *out_stats);

#ifdef __cplusplus
}
#endif

#endif
