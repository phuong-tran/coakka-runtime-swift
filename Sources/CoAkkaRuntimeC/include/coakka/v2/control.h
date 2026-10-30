#ifndef COAKKA_V2_CONTROL_H
#define COAKKA_V2_CONTROL_H

#include <stddef.h>
#include <stdint.h>

#include "coakka/v2/runtime.h"
#include "coakka/v2/message_value.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Endpoint metadata inside a runtime route snapshot.
 *
 * For endpoints marked COAKKA_V2_ENDPOINT_FLAG_LOCAL, host/port are diagnostic
 * metadata only; the runtime does not use that tuple for same-process
 * delivery. Explicit-network hosts may set port to zero. Legacy hosts may
 * retain a non-zero port while migrating away from route-derived listeners.
 *
 * Remote endpoint host must be concrete and its port must be non-zero.
 */
typedef struct coakka_v2_endpoint_t {
    const char *host;
    uint16_t port;
    uint32_t weight;
    uint32_t flags;
} coakka_v2_endpoint_t;

/** Route resolution policy used when a target has one or more endpoints. */
typedef enum coakka_v2_route_resolution_strategy_t {
    COAKKA_V2_ROUTE_STRATEGY_UNSPECIFIED = 0,
    COAKKA_V2_ROUTE_STRATEGY_SINGLE_OWNER = 1,
    COAKKA_V2_ROUTE_STRATEGY_WEIGHTED_ROUND_ROBIN = 2,
    COAKKA_V2_ROUTE_STRATEGY_RENDEZVOUS_HASH = 3
} coakka_v2_route_resolution_strategy_t;

enum {
    /** No route-level flags. */
    COAKKA_V2_ROUTE_FLAG_NONE = 0u,
    /** Prefer local endpoints when the route also has remote candidates. */
    COAKKA_V2_ROUTE_FLAG_PREFER_LOCAL = 1u << 0
};

enum {
    /** No endpoint flags. */
    COAKKA_V2_ENDPOINT_FLAG_NONE = 0u,
    /** Endpoint is owned by this runtime process. */
    COAKKA_V2_ENDPOINT_FLAG_LOCAL = 1u << 0,
    /** Endpoint is present for diagnostics but unavailable for routing. */
    COAKKA_V2_ENDPOINT_FLAG_UNAVAILABLE = 1u << 1
};

/**
 * Target-to-endpoints route-table entry.
 *
 * `target` must be present and non-empty. It is the runtime routing key, not a
 * display label or business schema name. Targets must be unique within one
 * control snapshot.
 * `strategy` must be one declared route resolution strategy.
 * `endpoint_count` must be non-zero. To remove a target, omit the route from a
 * newer full snapshot instead of publishing an empty route entry.
 * Unknown route or endpoint flag bits are rejected by the current runtime
 * instead of being preserved into topology/catalog read-models.
 *
 * The caller owns every string and endpoint array for the duration of the
 * apply call. The runtime copies the snapshot before returning.
 */
typedef struct coakka_v2_route_t {
    const char *target;
    coakka_v2_route_resolution_strategy_t strategy;
    const char *route_key_hint;
    uint32_t flags;
    const coakka_v2_endpoint_t *endpoints;
    size_t endpoint_count;
} coakka_v2_route_t;

/**
 * Complete route snapshot applied under one monotonically increasing generation.
 *
 * Generation 0 is invalid. Newer snapshots replace older route state; stale
 * generations are rejected to keep host control-plane updates explicit.
 */
typedef struct coakka_v2_control_snapshot_t {
    uint64_t generation;
    const coakka_v2_route_t *routes;
    size_t route_count;
} coakka_v2_control_snapshot_t;

/** Diagnostics only, not native sequencing/authorization policy. Source text
 * borrows by length and preserves embedded NUL; no host default is inferred. */
typedef struct coakka_v2_control_value_metadata_t {
    uint64_t seq;
    coakka_v2_message_span_t source_connector;
} coakka_v2_control_value_metadata_t;

/** Format values, not an admitted runtime endpoint. Keep the full port range
 * so Core admission, rather than narrowing at an FFI boundary, rejects it. */
typedef struct coakka_v2_control_endpoint_value_t {
    coakka_v2_message_span_t host;
    uint32_t port;
    uint32_t weight;
    uint32_t flags;
} coakka_v2_control_endpoint_value_t;

typedef struct coakka_v2_control_route_value_t {
    coakka_v2_message_span_t target;
    coakka_v2_message_span_t route_key_hint;
    int32_t strategy;
    uint32_t flags;
    const coakka_v2_control_endpoint_value_t *endpoints;
    size_t endpoint_count;
} coakka_v2_control_route_value_t;

typedef struct coakka_v2_control_snapshot_value_t {
    uint64_t generation;
    const coakka_v2_control_route_value_t *routes;
    size_t route_count;
} coakka_v2_control_snapshot_value_t;

typedef struct coakka_v2_control_overload_value_t {
    int32_t ingress_mode;
    int32_t local_delivery_mode;
    int32_t remote_outbound_mode;
    uint32_t remote_outbound_reply_reserve_slots;
} coakka_v2_control_overload_value_t;

/** Borrowed v1 control values for Core encoding. snapshot is required; NULL
 * policy is absent, not a reconstructed default. Metadata is nullable. All
 * input storage borrows only through encode; this operation does not apply or
 * validate runtime policy. These length-bearing format values are separate
 * from the older C-string/uint16 typed-apply records, whose ABI is unchanged. */
typedef struct coakka_v2_control_value_t {
    size_t struct_size;
    const coakka_v2_control_snapshot_value_t *snapshot;
    const coakka_v2_control_overload_value_t *policy;
    const coakka_v2_control_value_metadata_t *metadata;
} coakka_v2_control_value_t;

/** Encodes one complete control update without changing native state. Preserve
 * all intent, including zero values, unknown enums, seq and source diagnostics.
 * No host grammar/defaults are needed. Table/text charge and encoded bytes are
 * each bounded by MESSAGE_VALUE_MAX_METADATA_BYTES. All text is length-bearing
 * UTF-8, preserves embedded NUL and follows message_span empty/null law.
 * Inputs/outputs must not overlap. Root overlap refuses without writes; other
 * valid output slots clear before fallible work. Exact root v1 size is required.
 * INVALID_ARG reports representation/UTF-8/limits, NOMEM allocation failure,
 * IO encoding/unexpected failure. Caller owns successful bytes and releases
 * them with client_bytes_release, including after runtime apply refusal. */
coakka_v2_status_t coakka_v2_client_encode_control_value(
    const coakka_v2_control_value_t *value, uint8_t **out_bytes, size_t *out_size);

/** Applies a route snapshot with the configured boot-time overload defaults. */
coakka_v2_status_t coakka_v2_runtime_apply_control_snapshot(
    coakka_v2_runtime_t *rt,
    const coakka_v2_control_snapshot_t *snapshot
);

/**
 * Applies a route snapshot only after the caller-owned auth context satisfies
 * the runtime-owned control access policy.
 *
 * A valid but unauthorized request returns COAKKA_V2_OK with out_result set to
 * UNAUTHORIZED or FORBIDDEN and does not mutate topology. If authorization is
 * accepted, out_result is OK and the returned status is the underlying control
 * apply status.
 */
coakka_v2_status_t coakka_v2_runtime_apply_control_snapshot_with_auth_context(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_context_t *context,
    const coakka_v2_control_snapshot_t *snapshot,
    coakka_v2_runtime_auth_result_t *out_result
);

/**
 * Applies a route snapshot and overload policy as one control-plane update.
 * A NULL policy, or fields outside its struct_size, use configured boot-time
 * defaults. Invalid/stale updates leave the active route/policy pair unchanged.
 * Each remote route decision captures its generation's admission policy;
 * a later update does not replace the policy of that already-resolved request.
 */
coakka_v2_status_t coakka_v2_runtime_apply_control_snapshot_with_policy(
    coakka_v2_runtime_t *rt,
    const coakka_v2_control_snapshot_t *snapshot,
    const coakka_v2_overload_policy_t *policy
);

#ifdef __cplusplus
}
#endif

#endif
