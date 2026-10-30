#ifndef COAKKA_V2_RUNTIME_H
#define COAKKA_V2_RUNTIME_H

#include <stddef.h>
#include <stdint.h>

#include "coakka/v2/runtime_auth.h"
#include "coakka/v2/runtime_distribution.h"
#include "coakka/v2/runtime_transport_config.h"

/**
 * Native image lifetime is distinct from Runtime instance lifetime. Stop and
 * destroy every instance normally; shared process state may outlive them.
 * Keep one Core image for the process lifetime, not unload/reload generations.
 * Linux shared images remain mapped after the last loader reference closes.
 * On other platforms the host loader must retain its process image reference.
 * Loading arbitrarily many distinct images is not a bounded deployment model.
 */

#ifdef __cplusplus
extern "C" {
#endif

/** Status codes returned by the public runtime C ABI. */
typedef enum coakka_v2_status_t {
    COAKKA_V2_OK = 0,
    COAKKA_V2_ERR_INVALID_ARG = -1,
    COAKKA_V2_ERR_NOMEM = -2,
    COAKKA_V2_ERR_BAD_STATE = -3,
    COAKKA_V2_ERR_STALE_GENERATION = -4,
    COAKKA_V2_ERR_IO = -5,
    COAKKA_V2_ERR_WOULD_BLOCK = -6,
    COAKKA_V2_ERR_CLOSED = -7,
    COAKKA_V2_ERR_FEATURE_UNAVAILABLE = -8,
    COAKKA_V2_ERR_FEATURE_NOT_ENTITLED = -9
} coakka_v2_status_t;

/** Native runtime lifecycle state. */
typedef enum coakka_v2_runtime_state_t {
    COAKKA_V2_STATE_CREATED = 0,
    COAKKA_V2_STATE_STARTED = 1,
    COAKKA_V2_STATE_STOPPED = 2
} coakka_v2_runtime_state_t;

enum {
    COAKKA_V2_HEALTH_PROCESS_ALIVE = 1u << 0,
    COAKKA_V2_HEALTH_RUNTIME_STARTED = 1u << 1,
    COAKKA_V2_HEALTH_CONTROL_SNAPSHOT_PRESENT = 1u << 2,
    COAKKA_V2_HEALTH_DATAPLANE_READY = 1u << 3,
    COAKKA_V2_HEALTH_SOUTHBOUND_PROBE_ONLY = 1u << 4,
    COAKKA_V2_HEALTH_REMOTE_OUTBOUND_SATURATED = 1u << 5,
    COAKKA_V2_HEALTH_DRAINED_ROUTE_PRESENT = 1u << 6
};

/**
 * Runtime creation config.
 *
 * The caller owns all strings for the duration of coakka_v2_runtime_create().
 * The runtime copies the values it needs before the function returns.
 * queue_capacity is a requested bound, not an exact allocation contract: the
 * runtime rounds it to a power of two and clamps extreme values to an internal
 * production safety cap.
 */
typedef struct coakka_v2_runtime_config_t {
    const char *system_name;
    const char *node_id;
    int strict_no_drop;
    int queue_capacity;
} coakka_v2_runtime_config_t;

/** Queue overload policy mode. */
typedef enum coakka_v2_overload_mode_t {
    COAKKA_V2_OVERLOAD_MODE_REJECT = 0,
    COAKKA_V2_OVERLOAD_MODE_DROP_EXPIRED_FIRST = 1,
    COAKKA_V2_OVERLOAD_MODE_DROP_ONE_WAY_FIRST = 2
} coakka_v2_overload_mode_t;

/**
 * Bounded queue overload policy.
 *
 * Set struct_size to sizeof(coakka_v2_overload_policy_t). Smaller legacy
 * struct sizes are accepted only for source compatibility; fields outside the
 * advertised byte span use conservative runtime defaults.
 */
typedef struct coakka_v2_overload_policy_t {
    size_t struct_size;
    size_t remote_outbound_reply_reserve_slots;
    uint32_t ingress_mode;
    uint32_t local_delivery_mode;
    uint32_t remote_outbound_mode;
} coakka_v2_overload_policy_t;

/**
 * Runtime counters and queue evidence.
 *
 * Set struct_size to sizeof(coakka_v2_runtime_stats_t). The runtime fills only
 * fields that fit within the caller-provided struct size, allowing older hosts
 * to remain source-compatible with newer runtimes.
 */
typedef struct coakka_v2_runtime_stats_t {
    size_t struct_size;
    uint64_t applied_generation;
    size_t route_count;
    coakka_v2_runtime_state_t runtime_state;
    size_t ingress_queue_capacity;
    size_t ingress_queue_depth;
    size_t ingress_queue_high_watermark;
    uint64_t queue_rejected_count;
    uint64_t route_miss_count;
    uint64_t deadletter_count;
    uint64_t delivery_failed_count;
    uint64_t remote_transport_failed_count;
    uint64_t southbound_submit_attempt_count;
    uint64_t southbound_probe_connect_success_count;
    uint64_t southbound_probe_connect_failure_count;
    size_t request_max_frame_size;
    /* Legacy adapter field; current runtimes report 0 (not applicable). */
    size_t local_dispatch_batch_limit;
    size_t delivered_request_outbound_queue_capacity;
    size_t delivered_request_outbound_queue_depth;
    size_t delivered_request_outbound_queue_high_watermark;
    uint64_t delivered_request_outbound_enqueue_block_count;
    size_t response_outbound_queue_capacity;
    size_t response_outbound_queue_depth;
    size_t response_outbound_queue_high_watermark;
    uint64_t response_outbound_enqueue_block_count;
    size_t deadletter_outbound_queue_capacity;
    size_t deadletter_outbound_queue_depth;
    size_t deadletter_outbound_queue_high_watermark;
    uint64_t deadletter_outbound_enqueue_block_count;
    uint64_t remote_reply_timeout_count;
    uint64_t late_remote_reply_drop_count;
    size_t remote_outbound_queue_capacity;
    size_t remote_outbound_queue_depth;
    size_t remote_outbound_queue_high_watermark;
    uint64_t remote_outbound_queue_rejected_count;
    uint64_t remote_outbound_expired_drop_count;
    uint64_t endpoint_unavailable_count;
    uint64_t remote_response_forwarded_count;
    uint64_t remote_deadletter_forwarded_count;
    size_t drained_route_count;
    uint64_t control_rejected_count;
    uint64_t control_invalid_count;
    uint64_t control_stale_generation_count;
    uint64_t control_bad_state_count;
    uint64_t control_io_count;
    size_t remote_outbound_reply_reserve_slots;
    uint64_t remote_outbound_reply_reservation_reject_count;
    uint32_t ingress_overload_mode;
    uint32_t local_delivery_overload_mode;
    uint32_t remote_outbound_overload_mode;
    uint64_t monitor_event_emitted_count;
    uint64_t monitor_event_dropped_count;
    uint64_t monitor_event_emitted_lifetime_count;
    uint64_t monitor_event_dropped_lifetime_count;
    size_t local_work_queue_capacity;
    /* Local depth/HWM are sampled together at the queue owner. Other fields
     * may describe different instants; this is not a global admission lease. */
    size_t local_work_queue_depth;
    size_t local_work_queue_high_watermark;
    uint64_t delivered_request_outbound_direct_write_count;
    uint64_t response_outbound_direct_write_count;
    uint64_t deadletter_outbound_direct_write_count;
    uint64_t remote_outbound_one_way_drop_count;
    uint64_t remote_failover_attempt_count;
    uint64_t remote_failover_success_count;
    uint64_t remote_failover_exhausted_count;
} coakka_v2_runtime_stats_t;

/**
 * File-descriptor lanes exported to the host.
 *
 * The host owns the returned fds and must close each non-negative fd exactly
 * once, or pass the complete block to coakka_v2_host_handles_close(). The
 * runtime does not create a background host loop; callers decide when to invoke
 * the bounded Core wait/read/write operations on these lanes.
 * Native-startup instances select the separate delivered-request lane in Core,
 * including framed-only targets. Legacy construction retains explicit opt-in.
 */
typedef struct coakka_v2_host_handles_t {
    size_t struct_size;
    uint32_t flags;
    int request_write_fd;
    int response_read_fd;
    int deadletter_read_fd;
    int control_write_fd;
    int monitor_read_fd;
    int delivered_request_read_fd;
} coakka_v2_host_handles_t;

enum {
    COAKKA_V2_HOST_HANDLES_FLAG_ENABLE_MONITOR = 1u << 0,
    COAKKA_V2_HOST_HANDLES_FLAG_SEPARATE_DELIVERED_REQUEST_LANE = 1u << 1
};

/*
 * Monitor event/category names reused by runtime observability surfaces.
 *
 * The phase-2 monitor lane is a doorbell: runtime rings monitor_read_fd, the
 * host calls coakka_v2_monitor_consume(...), then refreshes stats/health through
 * direct ABI calls. monitor_read_fd never emits serialized
 * coakka_v2_monitor_event_t frames, and connectors must not treat these enum
 * values as an fd wire contract. The same enums may still be reused by
 * pull-based snapshot contracts such as the bounded recent event log.
 */
typedef enum coakka_v2_monitor_event_kind_t {
    COAKKA_V2_MONITOR_EVENT_KIND_STARTED = 1,
    COAKKA_V2_MONITOR_EVENT_KIND_STOPPED = 2,
    COAKKA_V2_MONITOR_EVENT_KIND_CONTROL_APPLIED = 3,
    COAKKA_V2_MONITOR_EVENT_KIND_CONTROL_REJECTED = 4,
    COAKKA_V2_MONITOR_EVENT_KIND_QUEUE_REJECTED = 5,
    COAKKA_V2_MONITOR_EVENT_KIND_ENDPOINT_UNAVAILABLE = 6,
    COAKKA_V2_MONITOR_EVENT_KIND_REMOTE_RESPONSE_FORWARDED = 7,
    COAKKA_V2_MONITOR_EVENT_KIND_REMOTE_DEADLETTER_FORWARDED = 8,
    COAKKA_V2_MONITOR_EVENT_KIND_REMOTE_REPLY_TIMEOUT = 9,
    COAKKA_V2_MONITOR_EVENT_KIND_LATE_REMOTE_REPLY_DROPPED = 10,
    COAKKA_V2_MONITOR_EVENT_KIND_REMOTE_TRANSPORT_FAILED = 11,
    COAKKA_V2_MONITOR_EVENT_KIND_AUTH_CONFIG_APPLIED = 12,
    COAKKA_V2_MONITOR_EVENT_KIND_AUTHENTICATION_ACCEPTED = 13,
    COAKKA_V2_MONITOR_EVENT_KIND_AUTHENTICATION_DENIED = 14,
    COAKKA_V2_MONITOR_EVENT_KIND_AUTHORIZATION_ACCEPTED = 15,
    COAKKA_V2_MONITOR_EVENT_KIND_AUTHORIZATION_DENIED = 16,
    COAKKA_V2_MONITOR_EVENT_KIND_AUTH_POLICY_APPLIED = 17,
    COAKKA_V2_MONITOR_EVENT_KIND_REMOTE_FAILOVER_ATTEMPT = 18,
    COAKKA_V2_MONITOR_EVENT_KIND_REMOTE_FAILOVER_SUCCEEDED = 19,
    COAKKA_V2_MONITOR_EVENT_KIND_REMOTE_FAILOVER_EXHAUSTED = 20
} coakka_v2_monitor_event_kind_t;

typedef enum coakka_v2_monitor_queue_scope_t {
    COAKKA_V2_MONITOR_QUEUE_SCOPE_INGRESS = 1,
    COAKKA_V2_MONITOR_QUEUE_SCOPE_LOCAL_DELIVERY = 2,
    COAKKA_V2_MONITOR_QUEUE_SCOPE_REMOTE_OUTBOUND = 3
} coakka_v2_monitor_queue_scope_t;

typedef enum coakka_v2_monitor_queue_reject_detail_t {
    COAKKA_V2_MONITOR_QUEUE_REJECT_DETAIL_NONE = 0,
    COAKKA_V2_MONITOR_QUEUE_REJECT_DETAIL_QUEUE_FULL = 1,
    COAKKA_V2_MONITOR_QUEUE_REJECT_DETAIL_REMOTE_REPLY_RESERVE = 2
} coakka_v2_monitor_queue_reject_detail_t;

/*
 * Reserved legacy event payload shape. Kept in the public header so older
 * source that referenced it still compiles, but monitor_read_fd carries only a
 * doorbell signal, not serialized coakka_v2_monitor_event_t records.
 */
typedef struct coakka_v2_monitor_event_t {
    size_t struct_size;
    uint32_t kind;
    uint32_t flags;
    uint64_t monotonic_time_ns;
    uint64_t generation;
    int64_t code;
    uint64_t value;
} coakka_v2_monitor_event_t;

/** Lightweight health snapshot for monitor/status paths. */
typedef struct coakka_v2_runtime_health_t {
    size_t struct_size;
    coakka_v2_runtime_state_t runtime_state;
    uint32_t flags;
    uint64_t applied_generation;
} coakka_v2_runtime_health_t;

enum {
    COAKKA_V2_RUNTIME_FEATURE_REQUEST_PIPE = 1u << 0,
    COAKKA_V2_RUNTIME_FEATURE_CONTROL_PIPE = 1u << 1,
    COAKKA_V2_RUNTIME_FEATURE_MONITOR = 1u << 2,
    COAKKA_V2_RUNTIME_FEATURE_NATIVE_SUBMIT = 1u << 3,
    COAKKA_V2_RUNTIME_FEATURE_CONTROL_JSON = 1u << 4,
    COAKKA_V2_RUNTIME_FEATURE_REMOTE_TRANSPORT = 1u << 5,
    /* Core was built with a custom allocator rather than the system allocator. */
    COAKKA_V2_RUNTIME_FEATURE_CUSTOM_ALLOCATOR = 1u << 6,
    COAKKA_V2_RUNTIME_FEATURE_DELIVERED_REQUEST_PIPE = 1u << 7,
    COAKKA_V2_RUNTIME_FEATURE_DUBBING_JOBS = 1u << 8,
    COAKKA_V2_RUNTIME_FEATURE_TOPOLOGY_SNAPSHOT = 1u << 9,
    COAKKA_V2_RUNTIME_FEATURE_MONITOR_SNAPSHOT = 1u << 10,
    COAKKA_V2_RUNTIME_FEATURE_EVENT_LOG = 1u << 11,
    COAKKA_V2_RUNTIME_FEATURE_AUTH_TYPES = 1u << 12,
    COAKKA_V2_RUNTIME_FEATURE_AUTH_CONFIG = 1u << 13,
    COAKKA_V2_RUNTIME_FEATURE_AUTH_GATE = 1u << 14,
    COAKKA_V2_RUNTIME_FEATURE_AUTH_POLICY = 1u << 15,
    COAKKA_V2_RUNTIME_FEATURE_AUTH_CONTEXT = 1u << 16,
    COAKKA_V2_RUNTIME_FEATURE_ROUTE_CATALOG = 1u << 17,
    COAKKA_V2_RUNTIME_FEATURE_AUTH_CONTROL_APPLY = 1u << 18,
    COAKKA_V2_RUNTIME_FEATURE_AUTH_OBSERVE_READ = 1u << 19,
    COAKKA_V2_RUNTIME_FEATURE_AUTH_DISCOVERY_READ = 1u << 20,
    COAKKA_V2_RUNTIME_FEATURE_AUTH_STATUS_READ = 1u << 21,
    COAKKA_V2_RUNTIME_FEATURE_AUTH_SECURITY_READ = 1u << 22,
    COAKKA_V2_RUNTIME_FEATURE_FILE_LANE = 1u << 23,
    COAKKA_V2_RUNTIME_FEATURE_STREAM_LANE = 1u << 24,
    COAKKA_V2_RUNTIME_FEATURE_LANE_OWNER_GRANTS = 1u << 25
};

typedef enum coakka_v2_runtime_surface_profile_t {
    COAKKA_V2_RUNTIME_SURFACE_PROFILE_DISCOVERY = 1u,
    COAKKA_V2_RUNTIME_SURFACE_PROFILE_OBSERVE = 2u,
    COAKKA_V2_RUNTIME_SURFACE_PROFILE_EVENT_LOG = 3u,
    COAKKA_V2_RUNTIME_SURFACE_PROFILE_CONTROL = 4u,
    COAKKA_V2_RUNTIME_SURFACE_PROFILE_REQUEST_DRIVER = 5u
} coakka_v2_runtime_surface_profile_t;

/**
 * Immutable runtime build and feature information.
 *
 * String pointers are runtime-owned static storage and must not be freed.
 * The allocator provider is a compiled fact: "custom" or "system". Provider
 * labels describe capabilities, not implementation identities; use feature
 * bits for programmatic decisions rather than matching presentation strings.
 */
typedef struct coakka_v2_runtime_info_t {
    size_t struct_size;
    uint32_t abi_version;
    uint32_t feature_flags;
    const char *runtime_version;
    const char *git_commit;
    const char *southbound_backend;
    const char *allocator_backend;
    const char *docs_hint;
    const char *remote_wire_profile;
    uint32_t remote_wire_profile_version;
    uint32_t edition;
    const char *build_id;
} coakka_v2_runtime_info_t;

/*
 * Additive core metadata aggregates frozen ABI blocks. Later contracts append
 * another complete block instead of extending an older block.
 */
typedef struct coakka_v2_runtime_core_info_t {
    size_t struct_size;
    coakka_v2_runtime_info_t runtime;
    coakka_v2_runtime_distribution_info_t distribution;
    coakka_v2_runtime_capability_snapshot_t capabilities;
    coakka_v2_runtime_license_snapshot_t license;
} coakka_v2_runtime_core_info_t;

#define COAKKA_V2_RUNTIME_CORE_INFO_V1_SIZE                                  \
    (offsetof(coakka_v2_runtime_core_info_t, license) +                       \
     sizeof(((coakka_v2_runtime_core_info_t *)0)->license))

/**
 * Runtime configuration/status view.
 *
 * String pointers are runtime-owned and valid until the runtime instance is
 * destroyed or a newer config view is requested.
 */
typedef struct coakka_v2_runtime_config_view_t {
    size_t struct_size;
    const char *system_name;
    const char *node_id;
    int strict_no_drop;
    int queue_capacity;
    size_t request_max_frame_size;
    /* Legacy adapter field; current runtimes report 0 (not applicable). */
    size_t local_dispatch_batch_limit;
    coakka_v2_runtime_state_t runtime_state;
    uint32_t snapshot_present;
    uint64_t applied_generation;
    size_t route_count;
    const char *southbound_bind_host;
    uint16_t southbound_bind_port;
    uint32_t configured_ingress_overload_mode;
    uint32_t configured_local_delivery_overload_mode;
    uint32_t configured_remote_outbound_overload_mode;
    size_t configured_remote_outbound_reply_reserve_slots;
    uint32_t effective_ingress_overload_mode;
    uint32_t effective_local_delivery_overload_mode;
    uint32_t effective_remote_outbound_overload_mode;
    size_t effective_remote_outbound_reply_reserve_slots;
} coakka_v2_runtime_config_view_t;

/** Opaque native runtime instance owned by the host process. */
typedef struct coakka_v2_runtime_t coakka_v2_runtime_t;
typedef struct coakka_v2_request_reader_t coakka_v2_request_reader_t;
typedef struct coakka_v2_owned_frame_t coakka_v2_owned_frame_t;

/** Returns the runtime ABI version supported by this library. */
uint32_t coakka_v2_runtime_get_abi_version(void);

/** Creates the sole delivered-request reader for a started native Runtime.
 * Core selects its owned-queue or framed backend; the caller neither receives
 * a descriptor nor probes platform capability. Destroy the reader before
 * Runtime stop/destroy. Calls on one reader and Runtime lifecycle operations
 * must be serialized. Failure leaves out_reader NULL. */
coakka_v2_status_t coakka_v2_runtime_request_reader_create(
    coakka_v2_runtime_t *runtime,
    const coakka_v2_host_handles_t *handles,
    coakka_v2_request_reader_t **out_reader);

/** Reads one complete delivered request under one original monotonic deadline.
 * timeout_ms=0 is one nonblocking attempt. OK returns one owned opaque frame;
 * WOULD_BLOCK is timeout/no data, CLOSED is a clean terminal, and IO includes
 * partial framed close or an unexpected wait/read failure. */
coakka_v2_status_t coakka_v2_request_reader_read(
    coakka_v2_request_reader_t *reader,
    uint32_t timeout_ms,
    coakka_v2_owned_frame_t **out_frame);

/** Immutable frame bytes, valid until coakka_v2_owned_frame_release(). */
const uint8_t *coakka_v2_owned_frame_data(
    const coakka_v2_owned_frame_t *frame);
size_t coakka_v2_owned_frame_size(const coakka_v2_owned_frame_t *frame);
void coakka_v2_owned_frame_release(coakka_v2_owned_frame_t *frame);

/** Retires the sole reader attachment, any outstanding owned frame and partial
 * framed state. NULL is a no-op. No read/release may be active. */
void coakka_v2_request_reader_destroy(coakka_v2_request_reader_t *reader);

/** Reads immutable runtime build and feature information. */
coakka_v2_status_t coakka_v2_runtime_get_info(coakka_v2_runtime_info_t *out_info);

/**
 * Returns one coherent immutable core/build/distribution metadata view.
 * Nested blocks are populated only when each complete block fits struct_size.
 */
coakka_v2_status_t coakka_v2_runtime_get_core_info(
    coakka_v2_runtime_core_info_t *out_info);

/** Reads compiled, entitled, and effective runtime capability truth. */
coakka_v2_status_t coakka_v2_runtime_get_capabilities(
    coakka_v2_runtime_capability_snapshot_t *out_capabilities
);

/** Reads non-secret license status; Community builds report NOT_REQUIRED. */
coakka_v2_status_t coakka_v2_runtime_get_license_status(
    coakka_v2_runtime_license_snapshot_t *out_license
);

/** Returns a stable diagnostic name for one runtime surface profile. */
const char *coakka_v2_runtime_surface_profile_name(uint32_t profile);

/** Returns the runtime feature bits required by one surface profile. */
uint32_t coakka_v2_runtime_surface_required_features(uint32_t profile);

/**
 * Checks whether a runtime feature bitset supports one surface profile.
 *
 * Returns 1 when supported, 0 when unsupported. If out_missing_features is not
 * NULL, it receives the missing feature bits for known profiles, or 0 for
 * unknown profiles.
 */
int coakka_v2_runtime_surface_check_features(uint32_t feature_flags,
                                             uint32_t profile,
                                             uint32_t *out_missing_features);

/** Reads the current configuration/status view for one runtime instance. */
coakka_v2_status_t coakka_v2_runtime_get_config(coakka_v2_runtime_t *rt,
                                                coakka_v2_runtime_config_view_t *out_config);

/**
 * Validates one TCP connection policy shape and compiled capability without
 * consulting a runtime handle or its lifecycle state.
 */
coakka_v2_status_t coakka_v2_runtime_validate_tcp_connection_options(
    const coakka_v2_tcp_connection_options_t *options,
    coakka_v2_tcp_connection_validation_t *out_validation
);

/**
 * Applies one immutable TCP connection policy while the runtime is CREATED.
 * Repeated successful calls in CREATED are allowed; the last one is selected.
 * STARTED and STOPPED return COAKKA_V2_ERR_BAD_STATE without changing it.
 *
 * Community builds allow PER_EXCHANGE and BOUNDED_POOL but reject pool tuning
 * fields with COAKKA_V2_ERR_FEATURE_UNAVAILABLE.
 */
coakka_v2_status_t coakka_v2_runtime_apply_tcp_connection_options(
    coakka_v2_runtime_t *rt,
    const coakka_v2_tcp_connection_options_t *options
);

/**
 * Applies one connection policy and reports whether effective state changed.
 *
 * out_result is required. Zero-initialize it and set struct_size to the
 * allocated byte count; zero requests the current full structure. A nonzero
 * size smaller than COAKKA_V2_TCP_CONNECTION_APPLY_RESULT_V1_HEADER_SIZE is
 * rejected before apply. A valid result prefix is filled on success and
 * rejection. The return value always equals out_result->apply_status.
 */
coakka_v2_status_t coakka_v2_runtime_apply_tcp_connection_options_ex(
    coakka_v2_runtime_t *rt,
    const coakka_v2_tcp_connection_options_t *options,
    coakka_v2_tcp_connection_apply_result_t *out_result
);

/** Reads the effective TCP connection configuration for one runtime. */
coakka_v2_status_t coakka_v2_runtime_get_tcp_connection_config(
    coakka_v2_runtime_t *rt,
    coakka_v2_tcp_connection_config_snapshot_t *out_config
);

/** Validates one startup network policy without mutating runtime state. */
coakka_v2_status_t coakka_v2_runtime_validate_network_options(
    const coakka_v2_network_options_t *options,
    coakka_v2_network_validation_t *out_validation
);

/**
 * Applies one explicit network participation policy while runtime is CREATED
 * and before the initial control snapshot is installed. Repeated successful
 * calls in that window are allowed; the last policy is selected.
 */
coakka_v2_status_t coakka_v2_runtime_apply_network_options(
    coakka_v2_runtime_t *rt,
    const coakka_v2_network_options_t *options
);

/** Reads the current effective network policy for one runtime instance. */
coakka_v2_status_t coakka_v2_runtime_get_network_config(
    coakka_v2_runtime_t *rt,
    coakka_v2_network_config_snapshot_t *out_config
);

/**
 * Validates one TCP security policy shape and compiled capability without
 * loading credentials or consulting runtime lifecycle/generation state.
 */
coakka_v2_status_t coakka_v2_runtime_validate_tcp_security_options(
    const coakka_v2_tcp_security_options_t *options,
    coakka_v2_tcp_security_validation_t *out_validation
);

/**
 * Loads and atomically applies one TCP security credential generation.
 *
 * The first call may occur in CREATED. A strictly later generation of the same
 * active TLS/mTLS mode may be applied in STARTED. GRACEFUL keeps established
 * sessions on their captured generation; DRAIN_EXISTING_CONNECTIONS marks old
 * sessions for bounded retirement. STOPPED returns COAKKA_V2_ERR_BAD_STATE.
 * Any rejected apply leaves the published config and identity unchanged.
 */
coakka_v2_status_t coakka_v2_runtime_apply_tcp_security_options(
    coakka_v2_runtime_t *rt,
    const coakka_v2_tcp_security_options_t *options
);

/**
 * Applies one security policy/generation and reports the resulting active
 * non-secret state. changed is 1 only after successful atomic publication.
 * Rejection leaves active_security on the previously published generation.
 *
 * out_result is required. Zero-initialize it and set struct_size to the
 * allocated byte count; zero requests the current full structure. A nonzero
 * size smaller than COAKKA_V2_TCP_SECURITY_APPLY_RESULT_V1_HEADER_SIZE is
 * rejected before apply. A valid result prefix is filled on success and
 * rejection. The return value always equals out_result->apply_status.
 */
coakka_v2_status_t coakka_v2_runtime_apply_tcp_security_options_ex(
    coakka_v2_runtime_t *rt,
    const coakka_v2_tcp_security_options_t *options,
    coakka_v2_tcp_security_apply_result_t *out_result
);

/**
 * Reads the non-secret TCP security view. Credential bytes, source paths, and
 * provider diagnostics are never projected through this API.
 */
coakka_v2_status_t coakka_v2_runtime_get_tcp_security_config(
    coakka_v2_runtime_t *rt,
    coakka_v2_tcp_security_config_snapshot_t *out_config
);

/**
 * Returns frozen security config plus additive non-secret identity metadata.
 * Nested blocks are populated only when each complete block fits struct_size.
 */
coakka_v2_status_t coakka_v2_runtime_get_tcp_security_info(
    coakka_v2_runtime_t *rt,
    coakka_v2_tcp_security_info_t *out_info
);

/**
 * Reads the current configuration/status view only after the caller-owned auth
 * context satisfies the runtime-owned observe access policy.
 *
 * Unauthorized or forbidden callers receive COAKKA_V2_OK with out_result set
 * accordingly, and out_config is projected as an empty value while preserving
 * the caller's struct_size compatibility boundary.
 */
coakka_v2_status_t coakka_v2_runtime_get_config_with_auth_context(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_context_t *context,
    coakka_v2_runtime_config_view_t *out_config,
    coakka_v2_runtime_auth_result_t *out_result
);

/** Validates one future runtime-side auth config shape without mutating runtime state. */
coakka_v2_status_t coakka_v2_runtime_validate_auth_config(
    const coakka_v2_runtime_auth_config_t *config
);

/** Applies or clears the active runtime-owned auth config summary truth. */
coakka_v2_status_t coakka_v2_runtime_apply_auth_config(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_config_t *config
);

/** Reads the current runtime-owned auth config summary without exposing secrets. */
coakka_v2_status_t coakka_v2_runtime_get_auth_config_summary(
    coakka_v2_runtime_t *rt,
    coakka_v2_runtime_auth_config_summary_t *out_summary
);

/**
 * Reads the current auth config summary only after the caller-owned auth
 * context satisfies the runtime-owned observe access policy.
 *
 * Unauthorized or forbidden callers receive COAKKA_V2_OK with out_result set
 * accordingly, and out_summary is projected as an empty value while preserving
 * the caller's struct_size compatibility boundary.
 */
coakka_v2_status_t coakka_v2_runtime_get_auth_config_summary_with_auth_context(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_context_t *context,
    coakka_v2_runtime_auth_config_summary_t *out_summary,
    coakka_v2_runtime_auth_result_t *out_result
);

/** Validates one runtime access-policy payload without mutating runtime state. */
coakka_v2_status_t coakka_v2_runtime_validate_auth_policy(
    const coakka_v2_runtime_auth_policy_t *policy
);

/** Applies one runtime-owned observe/control access policy. */
coakka_v2_status_t coakka_v2_runtime_apply_auth_policy(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_policy_t *policy
);

/** Reads the current runtime-owned observe/control access policy. */
coakka_v2_status_t coakka_v2_runtime_get_auth_policy(
    coakka_v2_runtime_t *rt,
    coakka_v2_runtime_auth_policy_t *out_policy
);

/**
 * Reads the current observe/control access policy only after the caller-owned
 * auth context satisfies the runtime-owned observe access policy.
 */
coakka_v2_status_t coakka_v2_runtime_get_auth_policy_with_auth_context(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_context_t *context,
    coakka_v2_runtime_auth_policy_t *out_policy,
    coakka_v2_runtime_auth_result_t *out_result
);

/** Evaluates one username/password pair against the current runtime-owned auth config. */
coakka_v2_status_t coakka_v2_runtime_authenticate(
    coakka_v2_runtime_t *rt,
    const char *username,
    const char *password,
    coakka_v2_runtime_auth_result_t *out_result
);

/** Clears one caller-owned auth context to an unauthenticated state. */
coakka_v2_status_t coakka_v2_runtime_clear_auth_context(
    coakka_v2_runtime_auth_context_t *out_context
);

/** Authenticates credentials and fills one caller-owned connection auth context. */
coakka_v2_status_t coakka_v2_runtime_login(
    coakka_v2_runtime_t *rt,
    const char *username,
    const char *password,
    coakka_v2_runtime_auth_context_t *out_context,
    coakka_v2_runtime_auth_result_t *out_result
);

/**
 * Evaluates whether one authenticated role satisfies one declared runtime auth
 * scope. Unknown roles or scopes fail closed as INVALID_ARG.
 */
coakka_v2_status_t coakka_v2_runtime_authorize_scope(
    uint32_t role,
    uint32_t required_scope,
    coakka_v2_runtime_auth_result_t *out_result
);

/**
 * Evaluates one role against one declared required scope and records one
 * bounded runtime-owned authz breadcrumb for accepted/forbidden outcomes.
 * Unknown roles or scopes fail closed as INVALID_ARG.
 */
coakka_v2_status_t coakka_v2_runtime_authorize(
    coakka_v2_runtime_t *rt,
    uint32_t role,
    uint32_t required_scope,
    coakka_v2_runtime_auth_result_t *out_result
);

/** Evaluates one role against the current runtime-owned access policy. */
coakka_v2_status_t coakka_v2_runtime_authorize_access(
    coakka_v2_runtime_t *rt,
    uint32_t role,
    uint32_t access_kind,
    coakka_v2_runtime_auth_result_t *out_result
);

/** Evaluates one caller-owned auth context against the current access policy. */
coakka_v2_status_t coakka_v2_runtime_authorize_context_access(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_context_t *context,
    uint32_t access_kind,
    coakka_v2_runtime_auth_result_t *out_result
);

/** Creates one runtime instance. The returned pointer must be destroyed by the host. */
coakka_v2_runtime_t *coakka_v2_runtime_create(const coakka_v2_runtime_config_t *cfg);

/**
 * Destroys an instance, stopping it first if necessary. Host calls must be
 * quiescent before destruction. Unread host lanes do not require a drain;
 * pending delivery is cancelled before workers join and internal fds close.
 * Exported host-owned fds remain the caller's responsibility. NULL is a no-op.
 */
void coakka_v2_runtime_destroy(coakka_v2_runtime_t *rt);

/**
 * Exports host-owned file-descriptor lanes.
 *
 * Call before coakka_v2_runtime_start(). The caller must set struct_size and
 * requested flags in out_handles before calling. The advertised struct_size
 * must include the required request, response, deadletter, and control fds;
 * additive optional lanes remain gated by their own field span. Returned fds
 * are host-owned.
 */
coakka_v2_status_t coakka_v2_runtime_get_host_handles(coakka_v2_runtime_t *rt,
                                                      coakka_v2_host_handles_t *out_handles);

/** Starts dispatching for a created runtime instance. */
coakka_v2_status_t coakka_v2_runtime_start(coakka_v2_runtime_t *rt);

/**
 * Stops a started instance without requiring the host to drain output lanes.
 * Cancels pending output before joining producers and writers, then closes
 * runtime-owned terminal write fds. Pending/unread frames are not guaranteed
 * delivery during cancellation. Serialize lifecycle calls; this is not a
 * deadline guarantee for every transport/backend. Returns BAD_STATE unless
 * started, INVALID_ARG for NULL, or OK after shutdown completes.
 */
coakka_v2_status_t coakka_v2_runtime_stop(coakka_v2_runtime_t *rt);

/** Applies an overload policy without changing the route snapshot. */
coakka_v2_status_t coakka_v2_runtime_apply_overload_policy(
    coakka_v2_runtime_t *rt,
    const coakka_v2_overload_policy_t *policy
);

/** Reads runtime counters and queue-depth evidence. */
coakka_v2_status_t coakka_v2_runtime_get_stats(coakka_v2_runtime_t *rt,
                                               coakka_v2_runtime_stats_t *out_stats);

/**
 * Reads runtime counters only after the caller-owned auth context satisfies the
 * runtime-owned observe access policy.
 */
coakka_v2_status_t coakka_v2_runtime_get_stats_with_auth_context(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_context_t *context,
    coakka_v2_runtime_stats_t *out_stats,
    coakka_v2_runtime_auth_result_t *out_result
);

/** Reads lightweight runtime health evidence. */
coakka_v2_status_t coakka_v2_runtime_get_health(coakka_v2_runtime_t *rt,
                                                coakka_v2_runtime_health_t *out_health);

/**
 * Reads lightweight runtime health evidence only after the caller-owned auth
 * context satisfies the runtime-owned observe access policy.
 */
coakka_v2_status_t coakka_v2_runtime_get_health_with_auth_context(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_context_t *context,
    coakka_v2_runtime_health_t *out_health,
    coakka_v2_runtime_auth_result_t *out_result
);

/**
 * Submits one serialized transport envelope to the runtime. The buffer is not retained.
 *
 * Returns COAKKA_V2_ERR_BAD_STATE before runtime_start() succeeds, and
 * COAKKA_V2_ERR_CLOSED once runtime_stop() has begun closing ingress.
 */
coakka_v2_status_t coakka_v2_runtime_submit_envelope(coakka_v2_runtime_t *rt,
                                                     const uint8_t *buf,
                                                     size_t len);

/**
 * Applies one serialized control envelope to the runtime. The buffer is not
 * retained. len must not exceed INT_MAX bytes.
 * Route target/key-hint/endpoint host strings containing embedded NUL, ports
 * above UINT16_MAX, or strategy values outside the declared route-strategy range
 * return INVALID_ARG rather than being truncated or narrowed.
 * Refusal does not apply routes, generation
 * or overload policy; rejection counters may still advance.
 */
coakka_v2_status_t coakka_v2_runtime_apply_control_envelope(coakka_v2_runtime_t *rt,
                                                            const uint8_t *buf,
                                                            size_t len);

/**
 * Applies one serialized control envelope only after the caller-owned auth
 * context satisfies the runtime-owned control access policy.
 *
 * Unauthorized or forbidden callers receive COAKKA_V2_OK with out_result set
 * accordingly, and the runtime does not parse or apply the envelope.
 */
coakka_v2_status_t coakka_v2_runtime_apply_control_envelope_with_auth_context(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_context_t *context,
    const uint8_t *buf,
    size_t len,
    coakka_v2_runtime_auth_result_t *out_result
);

#ifdef __cplusplus
}
#endif

#endif
