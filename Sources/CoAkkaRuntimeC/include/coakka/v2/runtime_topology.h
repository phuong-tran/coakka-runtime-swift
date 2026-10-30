#ifndef COAKKA_V2_RUNTIME_TOPOLOGY_H
#define COAKKA_V2_RUNTIME_TOPOLOGY_H

#include "coakka/v2/control.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Deep-copied runtime-owned topology snapshot.
 *
 * The runtime allocates any returned route arrays, endpoint arrays, and
 * strings. Callers own that copy and must release it with
 * coakka_v2_runtime_free_topology_snapshot(...). Returned pointers should be
 * treated as read-only.
 *
 * If no control snapshot has been accepted yet, snapshot_present is 0 and the
 * remaining fields stay empty. If an empty control snapshot has been accepted,
 * snapshot_present is 1 and route_count may still be 0.
 */
typedef struct coakka_v2_runtime_topology_snapshot_t {
    uint32_t snapshot_present;
    uint64_t applied_generation;
    const char *southbound_bind_host;
    uint16_t southbound_bind_port;
    size_t route_count;
    const coakka_v2_route_t *routes;
} coakka_v2_runtime_topology_snapshot_t;

/**
 * Thin route/capability catalog entry for CLI, inspect, and shared surface
 * clients that need target discovery without full endpoint detail.
 */
typedef struct coakka_v2_runtime_route_catalog_entry_t {
    const char *target;
    uint32_t strategy;
    const char *route_key_hint;
    uint32_t flags;
    size_t endpoint_count;
    size_t local_endpoint_count;
    size_t remote_endpoint_count;
    size_t unavailable_endpoint_count;
    size_t available_endpoint_count;
} coakka_v2_runtime_route_catalog_entry_t;

/**
 * Deep-copied runtime-owned route catalog.
 *
 * This is a pull read-model derived from the same active topology snapshot.
 * It is intended for discovery/listing surfaces; callers that need endpoint
 * host/port detail should still use coakka_v2_runtime_get_topology_snapshot.
 */
typedef struct coakka_v2_runtime_route_catalog_t {
    uint32_t snapshot_present;
    uint64_t applied_generation;
    size_t route_count;
    const coakka_v2_runtime_route_catalog_entry_t *routes;
} coakka_v2_runtime_route_catalog_t;

/** Reads a deep-copied view of the currently active runtime topology. */
coakka_v2_status_t coakka_v2_runtime_get_topology_snapshot(
    coakka_v2_runtime_t *rt,
    coakka_v2_runtime_topology_snapshot_t *out_snapshot
);

/**
 * Reads a topology snapshot only after the caller-owned auth context satisfies
 * the runtime-owned observe access policy.
 *
 * Unauthorized or forbidden callers receive COAKKA_V2_OK with out_result set
 * accordingly, and out_snapshot is cleared to an empty value snapshot.
 */
coakka_v2_status_t coakka_v2_runtime_get_topology_snapshot_with_auth_context(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_context_t *context,
    coakka_v2_runtime_topology_snapshot_t *out_snapshot,
    coakka_v2_runtime_auth_result_t *out_result
);

/** Releases memory returned by coakka_v2_runtime_get_topology_snapshot(...). */
void coakka_v2_runtime_free_topology_snapshot(
    coakka_v2_runtime_topology_snapshot_t *snapshot
);

/** Reads a deep-copied route/catalog view of the active runtime topology. */
coakka_v2_status_t coakka_v2_runtime_get_route_catalog(
    coakka_v2_runtime_t *rt,
    coakka_v2_runtime_route_catalog_t *out_catalog
);

/**
 * Reads a route catalog only after the caller-owned auth context satisfies the
 * runtime-owned observe access policy.
 *
 * Unauthorized or forbidden callers receive COAKKA_V2_OK with out_result set
 * accordingly, and out_catalog is cleared to an empty value snapshot.
 */
coakka_v2_status_t coakka_v2_runtime_get_route_catalog_with_auth_context(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_context_t *context,
    coakka_v2_runtime_route_catalog_t *out_catalog,
    coakka_v2_runtime_auth_result_t *out_result
);

/** Releases memory returned by coakka_v2_runtime_get_route_catalog(...). */
void coakka_v2_runtime_free_route_catalog(
    coakka_v2_runtime_route_catalog_t *catalog
);

#ifdef __cplusplus
}
#endif

#endif
