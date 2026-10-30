#ifndef COAKKA_V2_DUBBING_H
#define COAKKA_V2_DUBBING_H

#include <stddef.h>
#include <stdint.h>

#include "coakka/v2/runtime.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum coakka_v2_dubbing_job_state_t {
    COAKKA_V2_DUBBING_JOB_STATE_NONE = 0,
    COAKKA_V2_DUBBING_JOB_STATE_QUEUED = 1,
    COAKKA_V2_DUBBING_JOB_STATE_RUNNING = 2,
    COAKKA_V2_DUBBING_JOB_STATE_SUCCEEDED = 3,
    COAKKA_V2_DUBBING_JOB_STATE_FAILED = 4,
    COAKKA_V2_DUBBING_JOB_STATE_CANCELLED = 5
} coakka_v2_dubbing_job_state_t;

typedef enum coakka_v2_dubbing_job_stage_t {
    COAKKA_V2_DUBBING_JOB_STAGE_NONE = 0,
    COAKKA_V2_DUBBING_JOB_STAGE_PREFLIGHT = 1,
    COAKKA_V2_DUBBING_JOB_STAGE_ASR = 2,
    COAKKA_V2_DUBBING_JOB_STAGE_TRANSLATION = 3,
    COAKKA_V2_DUBBING_JOB_STAGE_TTS = 4,
    COAKKA_V2_DUBBING_JOB_STAGE_MUX = 5,
    COAKKA_V2_DUBBING_JOB_STAGE_PUBLISH = 6
} coakka_v2_dubbing_job_stage_t;

/**
 * One submitted dubbing job.
 *
 * The runtime copies every provided string before the call returns.
 */
typedef struct coakka_v2_dubbing_job_spec_t {
    size_t struct_size;
    const char *job_label;
    const char *source_media_path;
    const char *output_root;
    const char *requested_scope;
} coakka_v2_dubbing_job_spec_t;

/**
 * Trusted orchestration update for one runtime-owned dubbing job.
 *
 * This is a migration bridge for the first runtime-owned job snapshot lane:
 * adapters or future in-core workers publish the latest job truth here, while
 * hosts and UIs consume current state through get/list plus the monitor
 * doorbell. The update replaces the current mutable fields; passing NULL for a
 * string clears that field.
 */
typedef struct coakka_v2_dubbing_job_update_t {
    size_t struct_size;
    uint64_t job_id;
    uint32_t state;
    uint32_t stage;
    uint32_t progress_milli;
    const char *status_reason;
    const char *active_artifact_path;
    const char *accepted_output_path;
} coakka_v2_dubbing_job_update_t;

enum {
    COAKKA_V2_DUBBING_JOB_LABEL_CAP = 128u,
    COAKKA_V2_DUBBING_PATH_CAP = 512u,
    COAKKA_V2_DUBBING_SCOPE_CAP = 64u,
    COAKKA_V2_DUBBING_REASON_CAP = 192u
};

/**
 * Stable runtime-owned snapshot of one dubbing job.
 *
 * Callers set struct_size to sizeof(coakka_v2_dubbing_job_snapshot_t). The
 * runtime fills only the fields that fit within the caller-provided struct
 * size, keeping additive growth source-compatible for older hosts.
 */
typedef struct coakka_v2_dubbing_job_snapshot_t {
    size_t struct_size;
    uint64_t job_id;
    uint32_t state;
    uint32_t stage;
    uint32_t progress_milli;
    uint32_t cancel_requested;
    uint64_t update_sequence;
    uint64_t submitted_mono_ns;
    uint64_t updated_mono_ns;
    char job_label[COAKKA_V2_DUBBING_JOB_LABEL_CAP];
    char source_media_path[COAKKA_V2_DUBBING_PATH_CAP];
    char output_root[COAKKA_V2_DUBBING_PATH_CAP];
    char requested_scope[COAKKA_V2_DUBBING_SCOPE_CAP];
    char status_reason[COAKKA_V2_DUBBING_REASON_CAP];
    char active_artifact_path[COAKKA_V2_DUBBING_PATH_CAP];
    char accepted_output_path[COAKKA_V2_DUBBING_PATH_CAP];
} coakka_v2_dubbing_job_snapshot_t;

/**
 * Submits one runtime-owned dubbing job.
 *
 * Phase-1 creates a bounded job slot inside runtime-core and publishes the
 * initial `QUEUED/PREFLIGHT` snapshot. Live consumers should wait on
 * `monitor_read_fd`, consume the monitor doorbell, then refresh job state
 * through list/get.
 */
coakka_v2_status_t coakka_v2_runtime_submit_dubbing_job(
    coakka_v2_runtime_t *rt,
    const coakka_v2_dubbing_job_spec_t *spec,
    uint64_t *out_job_id
);

/**
 * Publishes the latest state for one runtime-owned dubbing job.
 *
 * This narrow bridge lets a trusted adapter or a future in-core worker update
 * the runtime-owned read model without inventing a separate websocket or event
 * stream contract.
 */
coakka_v2_status_t coakka_v2_runtime_publish_dubbing_job_update(
    coakka_v2_runtime_t *rt,
    const coakka_v2_dubbing_job_update_t *update
);

/**
 * Cancels one runtime-owned dubbing job.
 *
 * Phase-1 cancellation is immediate: non-terminal jobs transition to
 * `CANCELLED` and the runtime rings the existing monitor doorbell.
 */
coakka_v2_status_t coakka_v2_runtime_cancel_dubbing_job(coakka_v2_runtime_t *rt,
                                                        uint64_t job_id);

/** Reads the current snapshot for one runtime-owned dubbing job. */
coakka_v2_status_t coakka_v2_runtime_get_dubbing_job(
    coakka_v2_runtime_t *rt,
    uint64_t job_id,
    coakka_v2_dubbing_job_snapshot_t *out_snapshot
);

/**
 * Lists known dubbing job ids in newest-first order.
 *
 * When out_job_ids is NULL or out_capacity is zero, the function only reports
 * the current total through out_job_count.
 */
coakka_v2_status_t coakka_v2_runtime_list_dubbing_jobs(
    coakka_v2_runtime_t *rt,
    uint64_t *out_job_ids,
    size_t out_capacity,
    size_t *out_job_count
);

#ifdef __cplusplus
}
#endif

#endif
