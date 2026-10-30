#ifndef COAKKA_V2_EVENT_SERVICE_OPERATOR_API_H
#define COAKKA_V2_EVENT_SERVICE_OPERATOR_API_H

#include "coakka/v2/event_service_api.h"
#include "coakka/v2/event_service_operator_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Future operator/control placeholder API for coakka-event-service.
 *
 * These entrypoints are intentionally separate from the normal event-service
 * data-plane header because replay and lag/audit-facing operations require a
 * stronger operational contract.
 */

coakka_v2_event_service_status_t coakka_v2_event_service_describe_subscription_lag(
    coakka_v2_event_service_t *service,
    const coakka_v2_event_selector_t *selector,
    coakka_v2_event_subscription_lag_snapshot_t *out_snapshot);

coakka_v2_event_service_status_t coakka_v2_event_service_begin_replay_job(
    coakka_v2_event_service_t *service,
    const coakka_v2_event_replay_request_t *request,
    coakka_v2_event_replay_job_snapshot_t *out_snapshot);

coakka_v2_event_service_status_t coakka_v2_event_service_describe_replay_job(
    coakka_v2_event_service_t *service,
    coakka_v2_event_string_view_t replay_job_id,
    coakka_v2_event_replay_job_snapshot_t *out_snapshot);

coakka_v2_event_service_status_t coakka_v2_event_service_cancel_replay_job(
    coakka_v2_event_service_t *service,
    coakka_v2_event_string_view_t replay_job_id,
    coakka_v2_event_string_view_t requested_by,
    coakka_v2_event_string_view_t reason_text);

#ifdef __cplusplus
}
#endif

#endif
