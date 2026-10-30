#ifndef COAKKA_V2_UTILS_H
#define COAKKA_V2_UTILS_H

#include <stddef.h>
#include <stdint.h>

#include "coakka/v2/control.h"
#include "coakka/v2/runtime_auth.h"
#include "coakka/v2/runtime_transport_config.h"
#include "coakka/v2/transport.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Returns a stable diagnostic name for a runtime status code. */
const char *coakka_v2_status_name(coakka_v2_status_t status);

/** Returns a stable diagnostic name for a runtime lifecycle state. */
const char *coakka_v2_runtime_state_name(coakka_v2_runtime_state_t state);

/** Returns a stable diagnostic name for a transport apply reason. */
const char *coakka_v2_transport_apply_reason_name(uint32_t reason);

/** Returns a stable diagnostic name for an overload mode. */
const char *coakka_v2_overload_mode_name(uint32_t mode);

/** Returns a stable diagnostic name for a route strategy. */
const char *coakka_v2_route_strategy_name(coakka_v2_route_resolution_strategy_t strategy);

/*
 * Monitor event/category name helpers.
 *
 * monitor_read_fd is still only a doorbell and does not emit typed event
 * records, but these enum names are also reused by the pull-based recent event
 * log ABI.
 */
const char *coakka_v2_monitor_event_kind_name(uint32_t kind);

const char *coakka_v2_monitor_queue_scope_name(uint32_t scope);

const char *coakka_v2_monitor_queue_reject_detail_name(uint32_t detail);

const char *coakka_v2_deadletter_reason_name(uint32_t reason);

const char *coakka_v2_runtime_auth_role_name(uint32_t role);

const char *coakka_v2_runtime_auth_scope_name(uint32_t scope);

const char *coakka_v2_runtime_auth_access_kind_name(uint32_t access_kind);

const char *coakka_v2_runtime_auth_result_code_name(uint32_t code);

/** Returns a stable diagnostic name for one dubbing job state. */
const char *coakka_v2_dubbing_job_state_name(uint32_t state);

/** Returns a stable diagnostic name for one dubbing job stage. */
const char *coakka_v2_dubbing_job_stage_name(uint32_t stage);

/** Returns a stable diagnostic name for one runtime feature flag bit. */
const char *coakka_v2_runtime_feature_flag_name(uint32_t flag);

/** Returns a stable diagnostic name for one runtime health flag bit. */
const char *coakka_v2_health_flag_name(uint32_t flag);

/** Returns a stable diagnostic name for one route flag bit. */
const char *coakka_v2_route_flag_name(uint32_t flag);

/** Returns a stable diagnostic name for one endpoint flag bit. */
const char *coakka_v2_endpoint_flag_name(uint32_t flag);

/** Formats a bitset of runtime feature flags into caller-provided storage. */
size_t coakka_v2_format_runtime_feature_flags(uint32_t flags, char *buf, size_t buf_len);

/** Formats a bitset of health flags into caller-provided storage. */
size_t coakka_v2_format_health_flags(uint32_t flags, char *buf, size_t buf_len);

#ifdef __cplusplus
}
#endif

#endif
