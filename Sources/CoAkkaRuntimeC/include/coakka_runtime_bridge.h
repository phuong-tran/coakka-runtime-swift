#ifndef COAKKA_RUNTIME_BRIDGE_H
#define COAKKA_RUNTIME_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

/* Generated public SDK, sealed by core-abi-manifest.json. Core owns the types. */
#include "coakka/v2/client.h"
#include "coakka/v2/control.h"
#include "coakka/v2/runtime_startup.h"
#include "coakka/v2/transport.h"
#include "coakka/v2/utils.h"
#include "coakka/v2/file_lane.h"
#include "coakka/v2/stream_lane.h"

/* The fixed-symbol bridge belongs inside the Swift module, not its public
 * dynamic export surface. Core SDK declarations above retain their own ABI.
 * PE exports are opt-in and these functions deliberately have no dllexport. */
#if !defined(_WIN32) && (defined(__GNUC__) || defined(__clang__))
#pragma GCC visibility push(hidden)
#endif

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
typedef coakka_v2_runtime_t coakka_swift_runtime_t;
typedef coakka_v2_ask_client_t coakka_swift_ask_client_t;
typedef coakka_v2_ask_ticket_t coakka_swift_ask_ticket_t;
typedef coakka_v2_file_lane_t coakka_swift_file_lane_t;
typedef coakka_v2_stream_lane_t coakka_swift_stream_lane_t;

typedef coakka_v2_file_lane_security_config_t coakka_swift_file_lane_security_config_t;

typedef coakka_v2_file_lane_config_t coakka_swift_file_lane_config_t;

typedef coakka_v2_lane_owner_config_t coakka_swift_lane_owner_config_t;

typedef coakka_v2_lane_owner_endpoint_t coakka_swift_lane_owner_endpoint_t;

typedef coakka_v2_file_lane_owned_config_t coakka_swift_file_lane_owned_config_t;

typedef coakka_v2_file_receive_grant_t coakka_swift_file_receive_grant_t;

typedef coakka_v2_file_transfer_snapshot_t coakka_swift_file_transfer_snapshot_t;

typedef coakka_v2_file_lane_stats_t coakka_swift_file_lane_stats_t;

typedef coakka_v2_stream_frame_t coakka_swift_stream_frame_t;

typedef coakka_v2_stream_source_next_fn coakka_swift_stream_source_fn;
typedef coakka_v2_stream_consumer_fn coakka_swift_stream_consumer_fn;

typedef coakka_v2_stream_lane_security_config_t coakka_swift_stream_security_config_t;

typedef coakka_v2_stream_lane_config_t coakka_swift_stream_config_t;

typedef coakka_v2_stream_lane_owned_config_t coakka_swift_stream_owned_config_t;

typedef coakka_v2_stream_publish_grant_t coakka_swift_stream_publish_grant_t;

typedef coakka_v2_stream_session_snapshot_t coakka_swift_stream_session_snapshot_t;

typedef coakka_v2_stream_pressure_snapshot_t coakka_swift_stream_pressure_snapshot_t;

typedef coakka_v2_stream_lane_stats_t coakka_swift_stream_stats_t;

typedef coakka_v2_host_handles_t coakka_swift_host_handles_t;

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

typedef coakka_v2_runtime_health_t coakka_swift_runtime_health_t;

typedef coakka_v2_runtime_stats_t coakka_swift_runtime_stats_t;

typedef coakka_v2_runtime_capability_snapshot_t coakka_swift_runtime_capabilities_t;

typedef coakka_v2_tcp_connection_options_t coakka_swift_tcp_connection_options_t;

typedef coakka_v2_tcp_connection_validation_t coakka_swift_tcp_connection_validation_t;

typedef coakka_v2_tcp_connection_config_snapshot_t coakka_swift_tcp_connection_config_t;

typedef coakka_v2_tcp_connection_apply_result_t coakka_swift_tcp_connection_apply_result_t;

typedef coakka_v2_tcp_security_options_t coakka_swift_tcp_security_options_t;

typedef coakka_v2_tcp_security_validation_t coakka_swift_tcp_security_validation_t;

typedef coakka_v2_tcp_security_config_snapshot_t coakka_swift_tcp_security_config_t;

typedef coakka_v2_tcp_security_identity_info_t coakka_swift_tcp_security_identity_t;

typedef coakka_v2_tcp_security_info_t coakka_swift_tcp_security_info_t;

typedef coakka_v2_tcp_security_apply_result_t coakka_swift_tcp_security_apply_result_t;

typedef coakka_v2_endpoint_t coakka_swift_endpoint_spec_t;

typedef coakka_v2_route_t coakka_swift_route_spec_t;

typedef coakka_v2_client_raw_request_spec_t coakka_swift_raw_request_spec_t;

typedef coakka_v2_client_raw_reply_spec_t coakka_swift_raw_reply_spec_t;

/* Exact ABI1 projections. Optional groups are synchronous borrows; NULL means
 * Core default. These records do not implement configuration or OS policy. */
typedef coakka_v2_startup_execution_options_t coakka_swift_startup_execution_options_t;
typedef coakka_v2_startup_io_options_t coakka_swift_startup_io_options_t;
typedef coakka_v2_startup_monitor_options_t coakka_swift_startup_monitor_options_t;

typedef coakka_v2_runtime_startup_options_t coakka_swift_startup_options_t;

typedef coakka_v2_startup_cpu_info_t coakka_swift_startup_cpu_info_t;

typedef coakka_v2_startup_io_info_t coakka_swift_startup_io_info_t;

typedef coakka_v2_runtime_startup_config_t coakka_swift_startup_config_t;

typedef coakka_v2_runtime_delivery_config_t coakka_swift_delivery_config_t;

typedef coakka_v2_request_reader_t coakka_swift_request_reader_t;
typedef coakka_v2_owned_frame_t coakka_swift_owned_frame_t;

/* Fixed-symbol Core client surface. Runtime lifecycle and one reader's calls
 * must be serialized. Destroy its reader before stopping Runtime. Each ticket
 * has one await/cancel/destroy owner; cancellation is not concurrent-safe.
 * Returned buffers use client_bytes_release; owned frames use frame_release.
 * Every output record needs its current struct_size. Core status is unchanged. */
int32_t coakka_swift_runtime_create_native(coakka_swift_runtime_library_t *,
    const char *, const char *, int, int, const coakka_swift_startup_options_t *,
    coakka_swift_runtime_t **);
int32_t coakka_swift_runtime_get_startup_config(coakka_swift_runtime_library_t *,
    coakka_swift_runtime_t *, coakka_swift_startup_config_t *);
int32_t coakka_swift_runtime_get_delivery_config(coakka_swift_runtime_library_t *,
    coakka_swift_runtime_t *, coakka_swift_delivery_config_t *);
int32_t coakka_swift_runtime_request_reader_create(coakka_swift_runtime_library_t *,
    coakka_swift_runtime_t *, const coakka_swift_host_handles_t *, coakka_swift_request_reader_t **);
int32_t coakka_swift_request_reader_read(coakka_swift_runtime_library_t *,
    coakka_swift_request_reader_t *, uint32_t, coakka_swift_owned_frame_t **);
const uint8_t *coakka_swift_owned_frame_data(coakka_swift_runtime_library_t *,
    const coakka_swift_owned_frame_t *);
size_t coakka_swift_owned_frame_size(coakka_swift_runtime_library_t *,
    const coakka_swift_owned_frame_t *);
void coakka_swift_owned_frame_release(coakka_swift_runtime_library_t *, coakka_swift_owned_frame_t *);
void coakka_swift_request_reader_destroy(coakka_swift_runtime_library_t *, coakka_swift_request_reader_t *);
void coakka_swift_ask_ticket_cancel(coakka_swift_runtime_library_t *, coakka_swift_ask_ticket_t *);
int32_t coakka_swift_copy_envelope_payload(coakka_swift_runtime_library_t *, const uint8_t *, size_t,
    uint32_t, uint8_t **, size_t *);
int32_t coakka_swift_copy_request_dispatch(coakka_swift_runtime_library_t *, const uint8_t *, size_t,
    uint8_t **, size_t *, uint8_t **, size_t *, uint32_t *);

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
 * the runtime copies them. Drop policy and queue capacity are caller intent,
 * validated by Core. The caller owns the returned runtime and
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
void coakka_swift_host_handles_close(coakka_swift_runtime_library_t *library,
    coakka_swift_host_handles_t *handles);

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

/* Core-owned immutable UTF-8, borrowed from the process-retained module.
 * NULL means no module/inspection; callers must not fabricate a reason name. */
const char *coakka_swift_deadletter_reason_name(coakka_swift_runtime_library_t *library,
                                               uint32_t reason);

/**
 * Creates Core-owned request/reply matching over exported terminal lanes.
 * `runtime` and `handles` are borrowed and must outlive the client. Creation
 * may allocate/start reader state and returns NULL on invalid input/failure.
 */
coakka_swift_ask_client_t *coakka_swift_ask_client_create(coakka_swift_runtime_library_t *library,
                                                          coakka_swift_runtime_t *runtime,
                                                          const coakka_swift_host_handles_t *handles);

/**
 * Destroys ask matching state after all tickets are destroyed. The call may
 * join Core-owned reader work and must not race begin/await operations.
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


/* Compiled Core feature queries. On OK, out_available is exactly0/1; on a
 * query failure the status is preserved and the output is not a fact.
 * Creation still owns entitlement, configuration and lifecycle refusal. */
int32_t coakka_swift_file_lane_available(coakka_swift_runtime_library_t *library, uint32_t *out_available);
int32_t coakka_swift_lane_owner_grants_available(coakka_swift_runtime_library_t *library, uint32_t *out_available);
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

int32_t coakka_swift_stream_available(coakka_swift_runtime_library_t *library, uint32_t *out_available);
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

#if !defined(_WIN32) && (defined(__GNUC__) || defined(__clang__))
#pragma GCC visibility pop
#endif

#endif
