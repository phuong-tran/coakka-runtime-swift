#ifndef COAKKA_V2_EVENT_SERVICE_API_H
#define COAKKA_V2_EVENT_SERVICE_API_H

#include <stdint.h>

#include "coakka/v2/event_service_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Future public C ABI placeholder API for coakka-event-service.
 *
 * The current tree does not ship a runnable implementation behind these entry
 * points yet. This file exists to define the intended host-facing boundary.
 */

typedef struct coakka_v2_event_service_t coakka_v2_event_service_t;
typedef struct coakka_v2_event_subscription_t coakka_v2_event_subscription_t;

coakka_v2_event_service_t *coakka_v2_event_service_open(
    const coakka_v2_event_service_open_options_t *options);

void coakka_v2_event_service_close(coakka_v2_event_service_t *service);

coakka_v2_event_service_status_t coakka_v2_event_service_publish(
    coakka_v2_event_service_t *service,
    const coakka_v2_event_publish_spec_t *spec,
    coakka_v2_event_delivery_report_t *out_report);

coakka_v2_event_service_status_t coakka_v2_event_service_begin_subscription(
    coakka_v2_event_service_t *service,
    const coakka_v2_event_subscription_spec_t *spec,
    coakka_v2_event_subscription_t **out_subscription);

coakka_v2_event_service_status_t coakka_v2_event_subscription_poll(
    coakka_v2_event_subscription_t *subscription,
    uint32_t timeout_ms,
    coakka_v2_event_record_t *out_record);

coakka_v2_event_service_status_t coakka_v2_event_subscription_ack(
    coakka_v2_event_subscription_t *subscription,
    coakka_v2_event_string_view_t event_id,
    coakka_v2_event_string_view_t cursor_token);

void coakka_v2_event_subscription_close(
    coakka_v2_event_subscription_t *subscription);

#ifdef __cplusplus
}
#endif

#endif
