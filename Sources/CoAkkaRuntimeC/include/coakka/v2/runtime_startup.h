#ifndef COAKKA_V2_RUNTIME_STARTUP_H
#define COAKKA_V2_RUNTIME_STARTUP_H

#include "coakka/v2/runtime.h"

#ifdef __cplusplus
extern "C" {
#endif

#define COAKKA_V2_STARTUP_CPU_AUTO UINT32_C(0)
#define COAKKA_V2_STARTUP_CPU_SINGLE UINT32_C(1)

/** Construction-only CPU intent. AUTO prefers two allowed logical CPUs, or
 * one when restricted; SINGLE requires one. Neither is a thread count, CPU
 * quota or exclusive reservation. Set struct_size and keep reserved zero. */
typedef struct coakka_v2_startup_execution_options_t {
    size_t struct_size;
    uint32_t cpu_policy;
    uint32_t reserved;
} coakka_v2_startup_execution_options_t;

/** Immutable optional receiver-readiness intent. Omission/zero is OFF: no
 * optional probe, ring or worker. 1 permits Core to probe Linux support and use
 * the optional backend for an active TCP receiver; unsupported/OS-denied hosts
 * keep ordinary readiness, with the reason in startup_config.io. Resource or
 * unexpected I/O failures reject rather than silently downgrade. Other values
 * reject. Outbound waits, framing and TLS byte I/O remain unchanged. Enabling
 * this option alone is not evidence of use or a performance guarantee; inspect
 * requested/compiled/probed/supported/effective. Changing intent requires a new
 * instance, not stop/start. */
typedef struct coakka_v2_startup_io_options_t {
    size_t struct_size;
    uint32_t use_io_uring;
    uint32_t reserved;
} coakka_v2_startup_io_options_t;

/** Immutable collection permission, independent of exporting a monitor signal.
 * Omission/zero is OFF; 1 reserves bounded collection. OFF cannot be enabled by
 * exporting handles, attaching, or stop/start; destroy/create is required. */
typedef struct coakka_v2_startup_monitor_options_t {
    size_t struct_size;
    uint32_t enabled;
    uint32_t reserved;
} coakka_v2_startup_monitor_options_t;

/** Synchronous startup intent. NULL options/groups select Core defaults:
 * AUTO CPU, persistent MULTIPLEXED connection, I/O opt-in OFF, monitor OFF.
 * All records need their full current struct_size; zero/short/unknown sizes
 * reject before reading optional pointers. All pointees are borrowed only for
 * create_native and are copied before return. Connection options use their
 * existing presence/validation contract. No connector default resolution is
 * necessary. This does not activate private experimental datapath features. */
typedef struct coakka_v2_runtime_startup_options_t {
    size_t struct_size;
    const coakka_v2_startup_execution_options_t *execution;
    const coakka_v2_tcp_connection_options_t *connection;
    const coakka_v2_startup_io_options_t *io;
    const coakka_v2_startup_monitor_options_t *monitor;
} coakka_v2_runtime_startup_options_t;

enum {
    COAKKA_V2_STARTUP_DEFAULT_EXECUTION = 1u << 0,
    COAKKA_V2_STARTUP_DEFAULT_CONNECTION = 1u << 1,
    COAKKA_V2_STARTUP_DEFAULT_IO = 1u << 2,
    COAKKA_V2_STARTUP_DEFAULT_MONITOR = 1u << 3
};

/** Core's immutable construction selection. Unknown IDs are UINT32_MAX.
 * Unsupported AUTO inherits OS placement with supported/counts == 0; explicit
 * SINGLE rejects. startup_applied means the last successful start verified
 * placement at Core thread birth, not a live affinity probe or utilization.
 * Future Core reader births enforce the same selection before doing work.
 * OS policy changes may make later births fail; Core never widens the child's
 * inherited allowance. App-host and separately created lane threads are not
 * placed. Stop/destroy never restore or change unrelated thread affinity. */
typedef struct coakka_v2_startup_cpu_info_t {
    uint32_t requested_policy;
    uint32_t supported;
    uint32_t available_cpu_count;
    uint32_t selected_cpu_count;
    uint32_t selected_cpu_ids[2];
    uint32_t startup_applied;
    uint32_t reserved;
} coakka_v2_startup_cpu_info_t;

/** Instance facts, never probed by the config getter. compiled describes this
 * image; OFF leaves probed/supported/effective/error zero. On opt-in, supported
 * is the successful construction probe, not a continuing OS-policy promise.
 * effective is 1 only while this instance has a running optional TCP receiver
 * readiness owner; it is 0 before start, after stop, and without a receiver
 * (EMBEDDED/OUTBOUND_ONLY). Outbound readiness is not covered. probe_error is
 * the positive OS error of the construction probe (zero on success); ENOTSUP,
 * ENOSYS or OS permission denial explains an accepted ordinary fallback. A
 * later operational/start failure still follows the normal typed error law. */
typedef struct coakka_v2_startup_io_info_t {
    uint32_t requested;
    uint32_t compiled;
    uint32_t probed;
    uint32_t supported;
    uint32_t effective;
    int32_t probe_error;
} coakka_v2_startup_io_info_t;

/** Accepted immutable collection permission; counters remain in the owning
 * operational/statistics APIs. ON retains the existing bounded log/mutex law. */
typedef struct coakka_v2_startup_monitor_info_t {
    uint32_t enabled;
    uint32_t reserved;
} coakka_v2_startup_monitor_info_t;

typedef enum coakka_v2_startup_delivery_mode_t {
    COAKKA_V2_STARTUP_DELIVERY_FRAMED = 1,
    COAKKA_V2_STARTUP_DELIVERY_OWNED_QUEUE = 2
} coakka_v2_startup_delivery_mode_t;

/** Core-selected native delivery facts. This separate versioned record keeps
 * the established startup-config layout unchanged. `compiled` reports whether
 * this image contains the owned-queue product composition. Modes are accepted
 * immutable choices, not connector preferences or live queue-depth
 * observations. A framed request mode can coexist with an owned response mode
 * when the accepted public request ceiling is larger than the owned queue's
 * safe bound. The remote batch value is a maximum of already-ready work, never
 * a fill wait. */
typedef struct coakka_v2_runtime_delivery_config_t {
    size_t struct_size;
    uint32_t compiled;
    uint32_t request_mode;
    uint32_t response_mode;
    uint32_t remote_batch_max_calls;
    uint32_t slot_capacity;
    uint32_t reserved;
    uint64_t byte_capacity;
} coakka_v2_runtime_delivery_config_t;

/** Pointer-free effective startup facts. Set struct_size to the allocated
 * size, at least sizeof this record. Getter writes one complete current record
 * only on success and preserves output on failure. Strings remain available
 * through runtime_get_config with its existing ownership law. Lifecycle calls
 * and destruction must be serialized; the mutex-coherent snapshot is not a
 * continuing promise about external OS policy. */
typedef struct coakka_v2_runtime_startup_config_t {
    size_t struct_size;
    uint32_t defaults_revision;
    uint32_t defaulted_groups;
    int32_t strict_no_drop;
    uint32_t queue_capacity;
    uint64_t request_max_frame_size;
    uint32_t runtime_state;
    uint32_t reserved;
    coakka_v2_startup_cpu_info_t execution;
    coakka_v2_tcp_connection_config_snapshot_t connection;
    coakka_v2_startup_io_info_t io;
    coakka_v2_startup_monitor_info_t monitor;
} coakka_v2_runtime_startup_config_t;

/** Creates a native instance without changing the frozen runtime_create ABI.
 * @param config Required original base configuration; strings are copied.
 * @param options Optional startup intent; NULL selects all Core defaults.
 * @param out_runtime Required output slot, set NULL before fallible work.
 * @return OK with one owned instance, or typed validation/capability/resource
 * failure without a partial instance. Destroy a successful instance with the
 * existing runtime_destroy. No thread or affinity mutation occurs at create.
 * Connection mode is fixed by this constructor; old pre-start connection
 * apply calls reject on native-created instances instead of changing defaults.
 * Network participation defaults to EMBEDDED without explicit user policy;
 * runtime_get_network_config reports that accepted mode and presence. An
 * explicit network policy may still be applied before the initial snapshot.
 * Legacy runtime_create keeps its historical route-derived network behavior.
 */
coakka_v2_status_t coakka_v2_runtime_create_native(
    const coakka_v2_runtime_config_t *config,
    const coakka_v2_runtime_startup_options_t *options,
    coakka_v2_runtime_t **out_runtime);

#define COAKKA_V2_STARTUP_CONFIG_MAX_BYTES UINT32_C(4096)

/** Creates the same native instance from serialized startup intent (version1).
 * config retains the original base-config ownership law. startup_bytes is a
 * nonempty message of at most STARTUP_CONFIG_MAX_BYTES; it is borrowed only
 * until return. Core does not retain caller bytes or parser storage. Version
 * presence is required; unsupported versions return FEATURE_UNAVAILABLE.
 * Malformed data, unknown fields/enums and invalid option combinations return
 * INVALID_ARG (or the existing typed capability refusal). Empty groups select
 * Core defaults; explicit scalar zero/false remains explicit. No defaults are
 * resolved by this input adapter. Parse recursion is bounded to8 levels.
 * This is construction-only, never a control-envelope update. All record
 * layouts and existing constructors are unchanged. out_runtime is set NULL
 * before fallible work; failure never publishes a partial instance.
 */
coakka_v2_status_t coakka_v2_runtime_create_native_from_config(
    const coakka_v2_runtime_config_t *config,
    const uint8_t *startup_bytes,
    size_t startup_size,
    coakka_v2_runtime_t **out_runtime);

/** Returns accepted configuration independently of monitor collection.
 * @param runtime Live instance created by runtime_create_native.
 * @param out_config Initialized complete caller-owned output record.
 * @return OK, INVALID_ARG for an invalid pointer/span, or FEATURE_UNAVAILABLE
 * for an old-constructor instance, preserving out_config on every failure.
 */
coakka_v2_status_t coakka_v2_runtime_get_startup_config(
    coakka_v2_runtime_t *runtime,
    coakka_v2_runtime_startup_config_t *out_config);

/** Returns Core's accepted immutable delivery composition for a native-created
 * instance. Set struct_size to sizeof the record. The getter never probes the
 * OS and preserves the complete output on failure. Old-constructor instances
 * return FEATURE_UNAVAILABLE. */
coakka_v2_status_t coakka_v2_runtime_get_delivery_config(
    coakka_v2_runtime_t *runtime,
    coakka_v2_runtime_delivery_config_t *out_config);

#ifdef __cplusplus
}
#endif
#endif
