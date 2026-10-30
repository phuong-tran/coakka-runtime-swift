#ifndef COAKKA_V2_RUNTIME_TRANSPORT_CONFIG_H
#define COAKKA_V2_RUNTIME_TRANSPORT_CONFIG_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum {
  COAKKA_V2_TCP_CONNECTION_DEFAULTS_REVISION = 1u,
  COAKKA_V2_TCP_BOUNDED_POOL_DEFAULT_MAX_CONNECTIONS = 8u,
  COAKKA_V2_TCP_BOUNDED_POOL_DEFAULT_MAX_REQUESTS_PER_CONNECTION = 1024u,
  COAKKA_V2_TCP_BOUNDED_POOL_DEFAULT_IDLE_TIMEOUT_MS = 30000u
};

/*
 * Runtime network participation is independent from route locality.
 *
 * LEGACY_ROUTE_DERIVED is reported only for runtime_create without an explicit
 * policy. Native construction defaults to EMBEDDED at Core. Select an explicit
 * mode before the initial snapshot when another participation policy is needed.
 */
typedef enum coakka_v2_network_mode_t {
  COAKKA_V2_NETWORK_LEGACY_ROUTE_DERIVED = 0,
  COAKKA_V2_NETWORK_EMBEDDED = 1,
  COAKKA_V2_NETWORK_OUTBOUND_ONLY = 2,
  COAKKA_V2_NETWORK_NODE = 3
} coakka_v2_network_mode_t;

enum {
  COAKKA_V2_NETWORK_FIELD_MODE = UINT64_C(1) << 0,
  COAKKA_V2_NETWORK_FIELD_BIND_HOST = UINT64_C(1) << 1,
  COAKKA_V2_NETWORK_FIELD_BIND_PORT = UINT64_C(1) << 2,
  COAKKA_V2_NETWORK_FIELD_ADVERTISE_HOST = UINT64_C(1) << 3,
  COAKKA_V2_NETWORK_FIELD_ADVERTISE_PORT = UINT64_C(1) << 4
};

#define COAKKA_V2_NETWORK_ALL_FIELDS                                          \
  (COAKKA_V2_NETWORK_FIELD_MODE | COAKKA_V2_NETWORK_FIELD_BIND_HOST |         \
   COAKKA_V2_NETWORK_FIELD_BIND_PORT |                                        \
   COAKKA_V2_NETWORK_FIELD_ADVERTISE_HOST |                                   \
   COAKKA_V2_NETWORK_FIELD_ADVERTISE_PORT)

/*
 * Additive startup-only network policy.
 *
 * EMBEDDED rejects remote endpoints and does not create a listener.
 * OUTBOUND_ONLY permits remote endpoints but does not create a listener.
 * NETWORK_NODE requires explicit bind and advertised endpoints. bind_host is
 * the local IPv4 address passed to bind(2); advertise_host is connector-owned
 * identity and must not be a wildcard address. Strings are borrowed only for
 * the synchronous apply call and are copied by the runtime.
 */
typedef struct coakka_v2_network_options_t {
  size_t struct_size;
  uint64_t fields;
  uint32_t mode;
  uint32_t reserved;
  const char *bind_host;
  const char *advertise_host;
  uint16_t bind_port;
  uint16_t advertise_port;
  uint32_t reserved2;
} coakka_v2_network_options_t;

typedef enum coakka_v2_network_validation_code_t {
  COAKKA_V2_NETWORK_VALID = 0,
  COAKKA_V2_NETWORK_INVALID_STRUCT_SIZE = 1,
  COAKKA_V2_NETWORK_UNKNOWN_FIELD = 2,
  COAKKA_V2_NETWORK_MODE_REQUIRED = 3,
  COAKKA_V2_NETWORK_UNKNOWN_MODE = 4,
  COAKKA_V2_NETWORK_RESERVED_NONZERO = 5,
  COAKKA_V2_NETWORK_FIELD_OUTSIDE_STRUCT = 6,
  COAKKA_V2_NETWORK_FIELD_NOT_APPLICABLE = 7,
  COAKKA_V2_NETWORK_REQUIRED_FIELD_MISSING = 8,
  COAKKA_V2_NETWORK_INVALID_BIND_HOST = 9,
  COAKKA_V2_NETWORK_INVALID_ADVERTISE_HOST = 10,
  COAKKA_V2_NETWORK_VALUE_WITHOUT_FIELD = 11
} coakka_v2_network_validation_code_t;

typedef struct coakka_v2_network_validation_t {
  size_t struct_size;
  uint32_t code;
  uint32_t reserved;
  uint64_t field;
} coakka_v2_network_validation_t;

/* Runtime-owned strings remain valid until the next apply or runtime destroy.
 * explicit_policy records accepted explicit user intent, not activation:
 * native default EMBEDDED has0, explicit EMBEDDED has1. Identify legacy by its
 * mode, never by negating this presence fact. */
typedef struct coakka_v2_network_config_snapshot_t {
  size_t struct_size;
  uint32_t mode;
  uint32_t explicit_policy;
  const char *bind_host;
  const char *advertise_host;
  uint16_t bind_port;
  uint16_t advertise_port;
  uint32_t reserved;
} coakka_v2_network_config_snapshot_t;

typedef enum coakka_v2_tcp_connection_mode_t {
  COAKKA_V2_TCP_CONNECTION_PER_EXCHANGE = 0,
  COAKKA_V2_TCP_CONNECTION_BOUNDED_POOL = 1,
  COAKKA_V2_TCP_CONNECTION_PERSISTENT_SINGLE_FLIGHT = 2,
  COAKKA_V2_TCP_CONNECTION_MULTIPLEXED = 3
} coakka_v2_tcp_connection_mode_t;

enum {
  COAKKA_V2_TCP_CONNECTION_FIELD_MODE = UINT64_C(1) << 0,
  COAKKA_V2_TCP_CONNECTION_FIELD_MAX_CONNECTIONS = UINT64_C(1) << 1,
  COAKKA_V2_TCP_CONNECTION_FIELD_MAX_REQUESTS_PER_CONNECTION = UINT64_C(1) << 2,
  COAKKA_V2_TCP_CONNECTION_FIELD_IDLE_TIMEOUT_MS = UINT64_C(1) << 3
};

#define COAKKA_V2_TCP_CONNECTION_ALL_FIELDS                                    \
  (COAKKA_V2_TCP_CONNECTION_FIELD_MODE |                                       \
   COAKKA_V2_TCP_CONNECTION_FIELD_MAX_CONNECTIONS |                            \
   COAKKA_V2_TCP_CONNECTION_FIELD_MAX_REQUESTS_PER_CONNECTION |                \
   COAKKA_V2_TCP_CONNECTION_FIELD_IDLE_TIMEOUT_MS)

/*
 * Additive TCP connection configuration.
 *
 * fields is a presence mask. A value outside the mask must remain zero. The
 * MODE field is required by the current apply contract. Pool tuning fields are
 * meaningful only with BOUNDED_POOL and may be compile- or entitlement-gated.
 * PERSISTENT_SINGLE_FLIGHT retains at most one connection per exact endpoint
 * and serializes that endpoint's exchanges. MULTIPLEXED permits bounded
 * concurrent exchanges on one retained connection. Their initial limits are
 * build-profile defaults rather than public tuning fields.
 * A profile that compiles bounded pool without tuning accepts MODE alone and
 * applies its fixed defaults revision; any tuning field returns the stable
 * feature-unavailable result. The ABI remains present when a profile omits an
 * implementation. A runtime accepts a larger struct_size when all unknown
 * presence bits remain clear, so a newer host can use the shared prefix against
 * an older runtime.
 */
typedef struct coakka_v2_tcp_connection_options_t {
  size_t struct_size;
  uint64_t fields;
  uint32_t mode;
  uint32_t reserved;
  uint32_t max_connections;
  uint32_t reserved2;
  uint64_t max_requests_per_connection;
  uint64_t idle_timeout_ms;
} coakka_v2_tcp_connection_options_t;

typedef enum coakka_v2_tcp_connection_validation_code_t {
  COAKKA_V2_TCP_CONNECTION_VALID = 0,
  COAKKA_V2_TCP_CONNECTION_INVALID_STRUCT_SIZE = 1,
  COAKKA_V2_TCP_CONNECTION_UNKNOWN_FIELD = 2,
  COAKKA_V2_TCP_CONNECTION_MODE_REQUIRED = 3,
  COAKKA_V2_TCP_CONNECTION_UNKNOWN_MODE = 4,
  COAKKA_V2_TCP_CONNECTION_FIELD_NOT_APPLICABLE = 5,
  COAKKA_V2_TCP_CONNECTION_VALUE_OUT_OF_RANGE = 6,
  COAKKA_V2_TCP_CONNECTION_FEATURE_UNAVAILABLE = 7,
  COAKKA_V2_TCP_CONNECTION_FEATURE_NOT_ENTITLED = 8,
  COAKKA_V2_TCP_CONNECTION_RESERVED_NONZERO = 9,
  COAKKA_V2_TCP_CONNECTION_FIELD_OUTSIDE_STRUCT = 10,
  COAKKA_V2_TCP_CONNECTION_VALUE_WITHOUT_FIELD = 11
} coakka_v2_tcp_connection_validation_code_t;

typedef struct coakka_v2_tcp_connection_validation_t {
  size_t struct_size;
  uint32_t code;
  uint32_t reserved;
  uint64_t field;
  uint64_t minimum_value;
  uint64_t maximum_value;
} coakka_v2_tcp_connection_validation_t;

/* Effective immutable configuration for one runtime instance. */
typedef struct coakka_v2_tcp_connection_config_snapshot_t {
  size_t struct_size;
  uint32_t defaults_revision;
  uint32_t mode;
  uint64_t applicable_fields;
  uint64_t explicitly_configured_fields;
  uint64_t defaulted_fields;
  uint64_t configurable_fields;
  uint32_t max_connections;
  uint32_t reserved;
  uint64_t max_requests_per_connection;
  uint64_t idle_timeout_ms;
} coakka_v2_tcp_connection_config_snapshot_t;

/* Transport security is independent from TCP connection reuse. */
typedef enum coakka_v2_tcp_security_mode_t {
  COAKKA_V2_TCP_SECURITY_PLAINTEXT = 0,
  COAKKA_V2_TCP_SECURITY_TLS = 1,
  COAKKA_V2_TCP_SECURITY_MUTUAL_TLS = 2
} coakka_v2_tcp_security_mode_t;

typedef enum coakka_v2_tls_credential_source_kind_t {
  COAKKA_V2_TLS_CREDENTIAL_SOURCE_NONE = 0,
  COAKKA_V2_TLS_CREDENTIAL_SOURCE_FILE = 1,
  COAKKA_V2_TLS_CREDENTIAL_SOURCE_MEMORY = 2,
  COAKKA_V2_TLS_CREDENTIAL_SOURCE_PROVIDER = 3
} coakka_v2_tls_credential_source_kind_t;

typedef enum coakka_v2_tls_reload_mode_t {
  COAKKA_V2_TLS_RELOAD_GRACEFUL = 0,
  COAKKA_V2_TLS_RELOAD_DRAIN_EXISTING_CONNECTIONS = 1
} coakka_v2_tls_reload_mode_t;

typedef enum coakka_v2_tls_reload_status_t {
  COAKKA_V2_TLS_RELOAD_NOT_CONFIGURED = 0,
  COAKKA_V2_TLS_RELOAD_NEVER_LOADED = 1,
  COAKKA_V2_TLS_RELOAD_ACTIVE = 2,
  COAKKA_V2_TLS_RELOAD_FAILED = 3,
  COAKKA_V2_TLS_RELOAD_EXPIRED = 4
} coakka_v2_tls_reload_status_t;

enum {
  COAKKA_V2_TCP_SECURITY_FIELD_MODE = UINT64_C(1) << 0,
  COAKKA_V2_TCP_SECURITY_FIELD_CREDENTIAL_SOURCE = UINT64_C(1) << 1,
  COAKKA_V2_TCP_SECURITY_FIELD_RELOAD_MODE = UINT64_C(1) << 2,
  COAKKA_V2_TCP_SECURITY_FIELD_CREDENTIAL_GENERATION = UINT64_C(1) << 3,
  COAKKA_V2_TCP_SECURITY_FIELD_CREDENTIAL_ID = UINT64_C(1) << 4,
  COAKKA_V2_TCP_SECURITY_FIELD_CA_CERTIFICATE_FILE = UINT64_C(1) << 5,
  COAKKA_V2_TCP_SECURITY_FIELD_IDENTITY_CERTIFICATE_FILE = UINT64_C(1) << 6,
  COAKKA_V2_TCP_SECURITY_FIELD_PRIVATE_KEY_FILE = UINT64_C(1) << 7
};

#define COAKKA_V2_TCP_SECURITY_ALL_FIELDS                                      \
  (COAKKA_V2_TCP_SECURITY_FIELD_MODE |                                         \
   COAKKA_V2_TCP_SECURITY_FIELD_CREDENTIAL_SOURCE |                            \
   COAKKA_V2_TCP_SECURITY_FIELD_RELOAD_MODE |                                  \
   COAKKA_V2_TCP_SECURITY_FIELD_CREDENTIAL_GENERATION |                        \
   COAKKA_V2_TCP_SECURITY_FIELD_CREDENTIAL_ID |                                \
   COAKKA_V2_TCP_SECURITY_FIELD_CA_CERTIFICATE_FILE |                          \
   COAKKA_V2_TCP_SECURITY_FIELD_IDENTITY_CERTIFICATE_FILE |                    \
   COAKKA_V2_TCP_SECURITY_FIELD_PRIVATE_KEY_FILE)

enum {
  COAKKA_V2_TLS_CREDENTIAL_ID_MAX_BYTES = 127u,
  COAKKA_V2_TLS_CERTIFICATE_SHA256_HEX_BYTES = 64u
};

typedef enum coakka_v2_tls_protocol_version_t {
  COAKKA_V2_TLS_PROTOCOL_VERSION_PROVIDER_DEFAULT = 0,
  COAKKA_V2_TLS_PROTOCOL_VERSION_1_2 = 0x0303,
  COAKKA_V2_TLS_PROTOCOL_VERSION_1_3 = 0x0304
} coakka_v2_tls_protocol_version_t;

enum {
  COAKKA_V2_TLS_VERIFY_PEER = UINT64_C(1) << 0,
  COAKKA_V2_TLS_VERIFY_PEER_IDENTITY = UINT64_C(1) << 1,
  COAKKA_V2_TLS_REQUIRE_CLIENT_CERTIFICATE = UINT64_C(1) << 2
};

/*
 * Additive TCP security configuration.
 *
 * Credential strings are borrowed only for the synchronous apply call. The
 * runtime loads their contents into a private immutable TLS context and does
 * not expose or retain their paths in public introspection. FILE is the first
 * implemented source. MEMORY and PROVIDER reserve the source vocabulary for
 * later additive source-specific structures.
 */
typedef struct coakka_v2_tcp_security_options_t {
  size_t struct_size;
  uint64_t fields;
  uint32_t mode;
  uint32_t credential_source_kind;
  uint32_t reload_mode;
  uint32_t reserved;
  uint64_t credential_generation;
  const char *credential_id;
  const char *ca_certificate_file;
  const char *identity_certificate_file;
  const char *private_key_file;
} coakka_v2_tcp_security_options_t;

typedef enum coakka_v2_tcp_security_validation_code_t {
  COAKKA_V2_TCP_SECURITY_VALID = 0,
  COAKKA_V2_TCP_SECURITY_INVALID_STRUCT_SIZE = 1,
  COAKKA_V2_TCP_SECURITY_UNKNOWN_FIELD = 2,
  COAKKA_V2_TCP_SECURITY_MODE_REQUIRED = 3,
  COAKKA_V2_TCP_SECURITY_UNKNOWN_MODE = 4,
  COAKKA_V2_TCP_SECURITY_RESERVED_NONZERO = 5,
  COAKKA_V2_TCP_SECURITY_FIELD_OUTSIDE_STRUCT = 6,
  COAKKA_V2_TCP_SECURITY_FIELD_NOT_APPLICABLE = 7,
  COAKKA_V2_TCP_SECURITY_REQUIRED_FIELD_MISSING = 8,
  COAKKA_V2_TCP_SECURITY_SOURCE_UNAVAILABLE = 9,
  COAKKA_V2_TCP_SECURITY_FEATURE_UNAVAILABLE = 10,
  COAKKA_V2_TCP_SECURITY_INVALID_GENERATION = 11,
  COAKKA_V2_TCP_SECURITY_CREDENTIAL_ID_TOO_LONG = 12,
  COAKKA_V2_TCP_SECURITY_VALUE_WITHOUT_FIELD = 13
} coakka_v2_tcp_security_validation_code_t;

/*
 * Stable reason shared by the additive transport apply-result ABIs. This is
 * more specific than apply_status; validation remains the field-level reason
 * for option-shape and capability rejection.
 */
typedef enum coakka_v2_transport_apply_reason_t {
  COAKKA_V2_TRANSPORT_APPLY_REASON_NONE = 0,
  COAKKA_V2_TRANSPORT_APPLY_REASON_INVALID_ARGUMENT = 1,
  COAKKA_V2_TRANSPORT_APPLY_REASON_FEATURE_UNAVAILABLE = 2,
  COAKKA_V2_TRANSPORT_APPLY_REASON_FEATURE_NOT_ENTITLED = 3,
  COAKKA_V2_TRANSPORT_APPLY_REASON_RUNTIME_NOT_CONFIGURABLE = 4,
  COAKKA_V2_TRANSPORT_APPLY_REASON_SECURITY_MODE_CHANGE_REQUIRES_RECREATE = 5,
  COAKKA_V2_TRANSPORT_APPLY_REASON_STALE_CREDENTIAL_GENERATION = 6,
  COAKKA_V2_TRANSPORT_APPLY_REASON_CREDENTIAL_REJECTED = 7,
  COAKKA_V2_TRANSPORT_APPLY_REASON_RESOURCE_FAILURE = 8,
  COAKKA_V2_TRANSPORT_APPLY_REASON_ADAPTER_REJECTED = 9
} coakka_v2_transport_apply_reason_t;

#define COAKKA_V2_TRANSPORT_APPLY_RUNTIME_STATE_UNKNOWN UINT32_MAX

typedef struct coakka_v2_tcp_security_validation_t {
  size_t struct_size;
  uint32_t code;
  uint32_t reserved;
  uint64_t field;
} coakka_v2_tcp_security_validation_t;

/*
 * Frozen effective security-config snapshot.
 *
 * credential_id points to runtime-owned storage and remains valid until the
 * next successful security apply or runtime destruction. Copy it immediately
 * when the caller needs a stable value across credential reload.
 */
typedef struct coakka_v2_tcp_security_config_snapshot_t {
  size_t struct_size;
  uint32_t mode;
  uint32_t credential_source_kind;
  uint32_t reload_mode;
  uint32_t reload_status;
  uint64_t credential_generation;
  const char *credential_id;
} coakka_v2_tcp_security_config_snapshot_t;

/*
 * Additive, copy-safe, non-secret TLS identity metadata. Certificate times are
 * raw X.509 bounds, not wall-clock-based runtime entitlement. Credential
 * material, paths, provider tokens, and raw diagnostics never belong here.
 */
typedef struct coakka_v2_tcp_security_identity_info_t {
  size_t struct_size;
  uint32_t minimum_protocol_version;
  uint32_t maximum_protocol_version;
  uint64_t inbound_verification_flags;
  uint64_t outbound_verification_flags;
  int64_t identity_not_before_unix_seconds;
  int64_t identity_not_after_unix_seconds;
  char credential_id_value[COAKKA_V2_TLS_CREDENTIAL_ID_MAX_BYTES + 1u];
  char identity_fingerprint_sha256[
      COAKKA_V2_TLS_CERTIFICATE_SHA256_HEX_BYTES + 1u];
} coakka_v2_tcp_security_identity_info_t;

/*
 * Additive security metadata aggregates frozen blocks. The compatibility
 * pointer in config keeps its original lifetime; new callers read the inline
 * identity credential ID. A getter fills a nested block only when the caller's
 * outer struct_size includes that complete block.
 */
typedef struct coakka_v2_tcp_security_info_t {
  size_t struct_size;
  coakka_v2_tcp_security_config_snapshot_t config;
  coakka_v2_tcp_security_identity_info_t identity;
} coakka_v2_tcp_security_info_t;

/*
 * Additive result for one connection-strategy apply attempt. apply_status is
 * the same value returned by the _ex call. changed is 1 only when the effective
 * configuration or its explicit/default provenance changed. Validation and
 * effective_config are complete nested blocks and are never partially
 * projected. effective_config is the state that remains active after the
 * attempt, including after rejection.
 */
typedef struct coakka_v2_tcp_connection_apply_result_t {
  size_t struct_size;
  int32_t apply_status;
  uint32_t changed;
  uint32_t reason;
  uint32_t runtime_state;
  coakka_v2_tcp_connection_validation_t validation;
  coakka_v2_tcp_connection_config_snapshot_t effective_config;
} coakka_v2_tcp_connection_apply_result_t;

/*
 * Additive result for one security apply/reload attempt. active_security is
 * the complete non-secret state that remains published after the attempt.
 * changed is 1 only after successful atomic publication of different mode or
 * credential-generation state.
 * Its compatibility credential-ID pointer keeps the original getter lifetime;
 * new callers should consume identity.credential_id_value.
 */
typedef struct coakka_v2_tcp_security_apply_result_t {
  size_t struct_size;
  int32_t apply_status;
  uint32_t changed;
  uint32_t reason;
  uint32_t runtime_state;
  coakka_v2_tcp_security_validation_t validation;
  coakka_v2_tcp_security_info_t active_security;
} coakka_v2_tcp_security_apply_result_t;

#define COAKKA_V2_TCP_SECURITY_IDENTITY_INFO_V1_SIZE                          \
  sizeof(coakka_v2_tcp_security_identity_info_t)

#define COAKKA_V2_TCP_SECURITY_INFO_V1_SIZE                                   \
  (offsetof(coakka_v2_tcp_security_info_t, identity) +                        \
   sizeof(((coakka_v2_tcp_security_info_t *)0)->identity))

#define COAKKA_V2_TCP_CONNECTION_APPLY_RESULT_V1_HEADER_SIZE                  \
  offsetof(coakka_v2_tcp_connection_apply_result_t, validation)

#define COAKKA_V2_TCP_CONNECTION_APPLY_RESULT_V1_SIZE                         \
  sizeof(coakka_v2_tcp_connection_apply_result_t)

#define COAKKA_V2_TCP_SECURITY_APPLY_RESULT_V1_HEADER_SIZE                    \
  offsetof(coakka_v2_tcp_security_apply_result_t, validation)

#define COAKKA_V2_TCP_SECURITY_APPLY_RESULT_V1_SIZE                           \
  sizeof(coakka_v2_tcp_security_apply_result_t)

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* COAKKA_V2_RUNTIME_TRANSPORT_CONFIG_H */
