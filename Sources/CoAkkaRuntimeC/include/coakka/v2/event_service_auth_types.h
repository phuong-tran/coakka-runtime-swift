#ifndef COAKKA_V2_EVENT_SERVICE_AUTH_TYPES_H
#define COAKKA_V2_EVENT_SERVICE_AUTH_TYPES_H

#include <stddef.h>
#include <stdint.h>

#include "coakka/v2/event_service_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Future auth/capability placeholder types for coakka-event-service.
 *
 * These declarations define normalized principal/capability evidence only.
 * They intentionally do not define password, token, cookie, mTLS, or other
 * transport/integration-specific auth mechanisms.
 */

typedef enum coakka_v2_event_principal_kind_t {
    COAKKA_V2_EVENT_PRINCIPAL_ANONYMOUS = 0,
    COAKKA_V2_EVENT_PRINCIPAL_APPLICATION_SERVICE = 1,
    COAKKA_V2_EVENT_PRINCIPAL_HUMAN_OPERATOR = 2,
    COAKKA_V2_EVENT_PRINCIPAL_AUTOMATION_AGENT = 3,
    COAKKA_V2_EVENT_PRINCIPAL_PLATFORM_ADMIN = 4
} coakka_v2_event_principal_kind_t;

typedef enum coakka_v2_event_capability_t {
    COAKKA_V2_EVENT_CAPABILITY_PUBLISH_EVENT = 0,
    COAKKA_V2_EVENT_CAPABILITY_READ_STREAM = 1,
    COAKKA_V2_EVENT_CAPABILITY_CONSUME_EPHEMERAL = 2,
    COAKKA_V2_EVENT_CAPABILITY_CONSUME_DURABLE = 3,
    COAKKA_V2_EVENT_CAPABILITY_INSPECT_LAG = 4,
    COAKKA_V2_EVENT_CAPABILITY_INSPECT_DEADLETTER = 5,
    COAKKA_V2_EVENT_CAPABILITY_INSPECT_AUDIT = 6,
    COAKKA_V2_EVENT_CAPABILITY_BEGIN_REPLAY = 7,
    COAKKA_V2_EVENT_CAPABILITY_CANCEL_REPLAY = 8,
    COAKKA_V2_EVENT_CAPABILITY_MANAGE_STREAM_CONFIG = 9,
    COAKKA_V2_EVENT_CAPABILITY_MANAGE_SUBSCRIPTION_CONFIG = 10,
    COAKKA_V2_EVENT_CAPABILITY_PAUSE_SUBSCRIPTION = 11,
    COAKKA_V2_EVENT_CAPABILITY_RESUME_SUBSCRIPTION = 12,
    COAKKA_V2_EVENT_CAPABILITY_REPLACE_CHECKPOINT = 13
} coakka_v2_event_capability_t;

typedef enum coakka_v2_event_authz_disposition_t {
    COAKKA_V2_EVENT_AUTHZ_ALLOWED = 0,
    COAKKA_V2_EVENT_AUTHZ_DENIED_MISSING_PRINCIPAL = 1,
    COAKKA_V2_EVENT_AUTHZ_DENIED_INSUFFICIENT_CAPABILITY = 2,
    COAKKA_V2_EVENT_AUTHZ_DENIED_SCOPE_MISMATCH = 3,
    COAKKA_V2_EVENT_AUTHZ_DENIED_RESOURCE_DISABLED = 4,
    COAKKA_V2_EVENT_AUTHZ_DENIED_UNSAFE_RAW_AUTH_MATERIAL = 5
} coakka_v2_event_authz_disposition_t;

typedef struct coakka_v2_event_scope_hint_t {
    size_t struct_size;
    coakka_v2_event_string_view_t namespace_name;
    coakka_v2_event_string_view_t stream_name;
    coakka_v2_event_string_view_t subscription_name;
} coakka_v2_event_scope_hint_t;

typedef struct coakka_v2_event_principal_t {
    size_t struct_size;
    coakka_v2_event_string_view_t principal_name;
    coakka_v2_event_scope_hint_t scope_hint;
    const uint32_t *capabilities;
    size_t capability_count;
    uint32_t principal_kind;
} coakka_v2_event_principal_t;

typedef struct coakka_v2_event_authz_decision_t {
    size_t struct_size;
    coakka_v2_event_string_view_t principal_name;
    coakka_v2_event_string_view_t reason_text;
    coakka_v2_event_scope_hint_t scope_hint;
    uint32_t principal_kind;
    uint32_t required_capability;
    uint32_t disposition;
} coakka_v2_event_authz_decision_t;

void coakka_v2_event_service_default_scope_hint(
    coakka_v2_event_scope_hint_t *out_scope);

void coakka_v2_event_service_default_principal(
    coakka_v2_event_principal_t *out_principal);

void coakka_v2_event_service_default_authz_decision(
    coakka_v2_event_authz_decision_t *out_decision);

const char *coakka_v2_event_principal_kind_name(uint32_t kind);

const char *coakka_v2_event_capability_name(uint32_t capability);

const char *coakka_v2_event_authz_disposition_name(uint32_t disposition);

#ifdef __cplusplus
}
#endif

#endif
