#ifndef COAKKA_V2_RUNTIME_AUTH_H
#define COAKKA_V2_RUNTIME_AUTH_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum {
    /** Maximum principals retained by one runtime auth config. */
    COAKKA_V2_RUNTIME_AUTH_MAX_USERS = 32,
    /** Maximum UTF-8 bytes before the username NUL terminator. */
    COAKKA_V2_RUNTIME_AUTH_USERNAME_MAX_BYTES = 127,
    /** Maximum secret bytes before the password NUL terminator. */
    COAKKA_V2_RUNTIME_AUTH_PASSWORD_MAX_BYTES = 255
};

/*
 * Additive types for runtime-side control authentication.
 *
 * These types define a small public ABI vocabulary for runtime-fed auth
 * config, normalized login/authz outcomes, and caller-owned auth context.
 * They do not imply one durable user store, runtime-owned session database,
 * or product login system.
 */

typedef enum coakka_v2_runtime_auth_role_t {
    COAKKA_V2_RUNTIME_AUTH_ROLE_NONE = 0,
    COAKKA_V2_RUNTIME_AUTH_ROLE_VIEWER = 1,
    COAKKA_V2_RUNTIME_AUTH_ROLE_OPERATOR = 2,
    COAKKA_V2_RUNTIME_AUTH_ROLE_ADMIN = 3
} coakka_v2_runtime_auth_role_t;

typedef enum coakka_v2_runtime_auth_result_code_t {
    COAKKA_V2_RUNTIME_AUTH_RESULT_OK = 0,
    COAKKA_V2_RUNTIME_AUTH_RESULT_UNAUTHORIZED = 1,
    COAKKA_V2_RUNTIME_AUTH_RESULT_FORBIDDEN = 2,
    COAKKA_V2_RUNTIME_AUTH_RESULT_BAD_REQUEST = 3,
    COAKKA_V2_RUNTIME_AUTH_RESULT_BAD_STATE = 4
} coakka_v2_runtime_auth_result_code_t;

typedef enum coakka_v2_runtime_auth_scope_t {
    COAKKA_V2_RUNTIME_AUTH_SCOPE_OBSERVE = 1,
    COAKKA_V2_RUNTIME_AUTH_SCOPE_CONTROL = 2,
    COAKKA_V2_RUNTIME_AUTH_SCOPE_ADMIN = 3
} coakka_v2_runtime_auth_scope_t;

typedef enum coakka_v2_runtime_auth_access_kind_t {
    COAKKA_V2_RUNTIME_AUTH_ACCESS_OBSERVE = 1,
    COAKKA_V2_RUNTIME_AUTH_ACCESS_CONTROL = 2
} coakka_v2_runtime_auth_access_kind_t;

/*
 * One runtime principal fed by app-host or local deployment config.
 *
 * Set struct_size to sizeof(coakka_v2_runtime_auth_user_t). Future additive
 * fields may extend this struct while preserving source compatibility for
 * smaller caller-provided sizes. `username` and `password` must both be
 * present, non-empty, NUL-terminated, and no longer than the public byte
 * limits above. The runtime copies both strings during synchronous apply.
 */
typedef struct coakka_v2_runtime_auth_user_t {
    size_t struct_size;
    const char *username;
    const char *password;
    uint32_t role;
} coakka_v2_runtime_auth_user_t;

/*
 * One small principal list for future runtime-side auth configuration.
 *
 * Set struct_size to sizeof(coakka_v2_runtime_auth_config_t). The caller owns
 * all pointed-to storage for the duration of any future config/apply call that
 * consumes this struct. This is a bounded runtime access-control list, not a
 * product identity database; oversized user counts or strings fail closed.
 */
typedef struct coakka_v2_runtime_auth_config_t {
    size_t struct_size;
    const coakka_v2_runtime_auth_user_t *users;
    size_t user_count;
} coakka_v2_runtime_auth_config_t;

/*
 * Normalized login or authorization result shape for future runtime-facing
 * auth handshakes and privileged action replies.
 *
 * Set struct_size to sizeof(coakka_v2_runtime_auth_result_t).
 * `role` should remain COAKKA_V2_RUNTIME_AUTH_ROLE_NONE when the caller is not
 * authenticated successfully.
 */
typedef struct coakka_v2_runtime_auth_result_t {
    size_t struct_size;
    uint32_t code;
    uint32_t role;
} coakka_v2_runtime_auth_result_t;

/*
 * Caller-owned authenticated context for one live runtime-facing connection.
 *
 * The runtime fills this shape after a successful login helper call. It does
 * not contain secret material and does not imply one runtime-owned durable
 * session store. A future CLI, inspect process, sidecar, or transport session
 * may keep this context for the lifetime of its own connection and pass it
 * back to runtime access checks.
 *
 * Set struct_size to sizeof(coakka_v2_runtime_auth_context_t).
 * `authenticated` must be either 0 or 1 when passed back to runtime access
 * checks. When `authenticated = 1`, `role` must be one declared authenticated
 * runtime role: VIEWER, OPERATOR, or ADMIN.
 */
typedef struct coakka_v2_runtime_auth_context_t {
    size_t struct_size;
    uint32_t authenticated;
    uint32_t role;
} coakka_v2_runtime_auth_context_t;

/*
 * Runtime-owned summary view of the currently active auth config.
 *
 * This summary intentionally exposes only bounded role/count truth and never
 * returns usernames or secret material.
 *
 * Set struct_size to sizeof(coakka_v2_runtime_auth_config_summary_t).
 */
typedef struct coakka_v2_runtime_auth_config_summary_t {
    size_t struct_size;
    uint32_t config_present;
    size_t user_count;
    size_t viewer_count;
    size_t operator_count;
    size_t admin_count;
} coakka_v2_runtime_auth_config_summary_t;

/*
 * Runtime-owned access-policy truth for observe vs control paths.
 *
 * `observe_min_role = NONE` means observe paths are open in the current
 * deployment. `control_min_role` must stay at least `OPERATOR`.
 *
 * Runtime access checks use the explicit role ladder:
 * `NONE < VIEWER < OPERATOR < ADMIN`. Callers must not infer future access
 * semantics from the enum integer values alone. Policy role values outside the
 * declared ladder fail closed.
 *
 * Set struct_size to sizeof(coakka_v2_runtime_auth_policy_t).
 */
typedef struct coakka_v2_runtime_auth_policy_t {
    size_t struct_size;
    uint32_t observe_min_role;
    uint32_t control_min_role;
} coakka_v2_runtime_auth_policy_t;

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* COAKKA_V2_RUNTIME_AUTH_H */
