#ifndef COAKKA_V2_RUNTIME_MONITOR_H
#define COAKKA_V2_RUNTIME_MONITOR_H

#include "coakka/v2/runtime_topology.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Deep-copied runtime-owned monitor snapshot.
 *
 * `change_sequence` increments whenever runtime marks one monitor-visible
 * state change. It is monotonic for the lifetime of the runtime instance and
 * may advance by more than one between doorbell reads when signals coalesce.
 * `observed_mono_ns` captures the runtime monotonic clock when the snapshot
 * was read. `health` and `stats` are embedded value snapshots. `topology`
 * reuses the deep-copied topology contract, so callers must release the whole
 * monitor snapshot with coakka_v2_runtime_free_monitor_snapshot(...).
 */
typedef struct coakka_v2_runtime_monitor_snapshot_t {
    uint64_t change_sequence;
    uint64_t observed_mono_ns;
    coakka_v2_runtime_health_t health;
    coakka_v2_runtime_stats_t stats;
    coakka_v2_runtime_topology_snapshot_t topology;
} coakka_v2_runtime_monitor_snapshot_t;

/**
 * Reads one monitor-oriented runtime snapshot.
 *
 * This is a pull contract. Monitor doorbells still only signal that the caller
 * should refresh; they do not carry typed payload history.
 */
coakka_v2_status_t coakka_v2_runtime_get_monitor_snapshot(
    coakka_v2_runtime_t *rt,
    coakka_v2_runtime_monitor_snapshot_t *out_snapshot
);

/**
 * Reads one monitor snapshot only after the caller-owned auth context
 * satisfies the runtime-owned observe access policy.
 *
 * Unauthorized or forbidden callers receive COAKKA_V2_OK with out_result set
 * accordingly, and out_snapshot is cleared to an empty value snapshot.
 */
coakka_v2_status_t coakka_v2_runtime_get_monitor_snapshot_with_auth_context(
    coakka_v2_runtime_t *rt,
    const coakka_v2_runtime_auth_context_t *context,
    coakka_v2_runtime_monitor_snapshot_t *out_snapshot,
    coakka_v2_runtime_auth_result_t *out_result
);

/** Releases memory returned by coakka_v2_runtime_get_monitor_snapshot(...). */
void coakka_v2_runtime_free_monitor_snapshot(
    coakka_v2_runtime_monitor_snapshot_t *snapshot
);

#ifdef __cplusplus
}
#endif

#endif
