#ifndef COAKKA_V2_EVENT_SERVICE_ADMIN_API_H
#define COAKKA_V2_EVENT_SERVICE_ADMIN_API_H

#include "coakka/v2/event_service_admin_types.h"
#include "coakka/v2/event_service_api.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Future admin/provisioning placeholder API for coakka-event-service.
 *
 * These entrypoints own durable resource definitions and checkpoint-authority
 * mutations. They are intentionally separate from normal publish/subscribe and
 * separate from operator replay/lag contracts.
 */

coakka_v2_event_service_status_t coakka_v2_event_service_upsert_stream_config(
    coakka_v2_event_service_t *service,
    const coakka_v2_event_stream_config_t *config,
    coakka_v2_event_admin_apply_result_t *out_result);

coakka_v2_event_service_status_t coakka_v2_event_service_describe_stream_config(
    coakka_v2_event_service_t *service,
    const coakka_v2_event_stream_id_t *stream,
    coakka_v2_event_stream_config_t *out_config);

coakka_v2_event_service_status_t coakka_v2_event_service_upsert_subscription_config(
    coakka_v2_event_service_t *service,
    const coakka_v2_event_subscription_config_t *config,
    coakka_v2_event_admin_apply_result_t *out_result);

coakka_v2_event_service_status_t coakka_v2_event_service_describe_subscription_config(
    coakka_v2_event_service_t *service,
    coakka_v2_event_string_view_t subscription_name,
    coakka_v2_event_subscription_config_t *out_config);

coakka_v2_event_service_status_t coakka_v2_event_service_replace_subscription_checkpoint(
    coakka_v2_event_service_t *service,
    const coakka_v2_event_checkpoint_replace_request_t *request,
    coakka_v2_event_checkpoint_snapshot_t *out_checkpoint,
    coakka_v2_event_admin_apply_result_t *out_result);

#ifdef __cplusplus
}
#endif

#endif
