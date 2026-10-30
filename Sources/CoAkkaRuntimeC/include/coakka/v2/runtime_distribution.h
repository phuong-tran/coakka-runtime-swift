#ifndef COAKKA_V2_RUNTIME_DISTRIBUTION_H
#define COAKKA_V2_RUNTIME_DISTRIBUTION_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Commercial packaging labels. Callers must not infer feature ordering from
 * these values; capability snapshots are the authoritative behavior contract.
 */
typedef enum coakka_v2_runtime_edition_t {
  COAKKA_V2_RUNTIME_EDITION_UNKNOWN = 0,
  COAKKA_V2_RUNTIME_EDITION_COMMUNITY = 1,
  /* Reserved legacy labels. Edition-v1 builds use COMMUNITY or ENTERPRISE. */
  COAKKA_V2_RUNTIME_EDITION_PRO = 2,
  COAKKA_V2_RUNTIME_EDITION_ENTERPRISE = 3,
  COAKKA_V2_RUNTIME_EDITION_PRO_MAX = 4
} coakka_v2_runtime_edition_t;

enum { COAKKA_V2_RUNTIME_DISTRIBUTION_CONTRACT_VERSION = 1u };

/*
 * Immutable edition/build-profile identity. String pointers refer to
 * process-lifetime build storage and must not be freed.
 */
typedef struct coakka_v2_runtime_distribution_info_t {
  size_t struct_size;
  uint32_t distribution_contract_version;
  uint32_t reserved;
  const char *edition_name;
  const char *build_profile;
  const char *release_channel;
  const char *tls_provider;
  const char *tls_provider_version;
} coakka_v2_runtime_distribution_info_t;

#define COAKKA_V2_RUNTIME_DISTRIBUTION_INFO_V1_SIZE                            \
  (offsetof(coakka_v2_runtime_distribution_info_t, tls_provider_version) +     \
   sizeof(((coakka_v2_runtime_distribution_info_t *)0)->tls_provider_version))

/* Stable, edition-independent capability bits. */
enum {
  COAKKA_V2_CAPABILITY_TCP_BOUNDED_POOL = UINT64_C(1) << 0,
  COAKKA_V2_CAPABILITY_TCP_POOL_TUNING = UINT64_C(1) << 1,
  COAKKA_V2_CAPABILITY_TCP_TLS = UINT64_C(1) << 2,
  COAKKA_V2_CAPABILITY_TCP_MUTUAL_TLS = UINT64_C(1) << 3,
  COAKKA_V2_CAPABILITY_TLS_CREDENTIAL_RELOAD = UINT64_C(1) << 4,
  COAKKA_V2_CAPABILITY_TLS_EXTERNAL_PROVIDER = UINT64_C(1) << 5,
  COAKKA_V2_CAPABILITY_TCP_PERSISTENT_SINGLE_FLIGHT = UINT64_C(1) << 6,
  COAKKA_V2_CAPABILITY_TCP_MULTIPLEXING = UINT64_C(1) << 7
};

typedef enum coakka_v2_runtime_license_status_t {
  COAKKA_V2_RUNTIME_LICENSE_NOT_REQUIRED = 0,
  COAKKA_V2_RUNTIME_LICENSE_ACTIVE = 1,
  COAKKA_V2_RUNTIME_LICENSE_GRACE = 2,
  COAKKA_V2_RUNTIME_LICENSE_EXPIRED = 3,
  COAKKA_V2_RUNTIME_LICENSE_INVALID = 4,
  COAKKA_V2_RUNTIME_LICENSE_TIME_UNTRUSTED = 5
} coakka_v2_runtime_license_status_t;

/*
 * Immutable distribution and entitlement view.
 *
 * effective_capabilities is a subset of compiled and entitled capabilities.
 * Runtime state or platform support may remove additional bits.
 */
typedef struct coakka_v2_runtime_capability_snapshot_t {
  size_t struct_size;
  uint32_t edition;
  uint32_t license_status;
  uint64_t compiled_capabilities;
  uint64_t entitled_capabilities;
  uint64_t effective_capabilities;
  uint32_t tcp_connection_defaults_revision;
  uint32_t reserved;
} coakka_v2_runtime_capability_snapshot_t;

/*
 * Non-secret license status. Edition-v1 gates binary distribution in the
 * release vault and reports NOT_REQUIRED with empty static strings and zero
 * validity times. A future signed runtime-side provider may project stronger
 * states without changing this ABI. This snapshot is not a verifier and does
 * not prove artifact authenticity.
 */
typedef struct coakka_v2_runtime_license_snapshot_t {
  size_t struct_size;
  uint32_t status;
  uint32_t edition;
  uint64_t entitled_capabilities;
  int64_t not_before_unix_seconds;
  int64_t expires_at_unix_seconds;
  const char *license_id;
  const char *signing_key_id;
} coakka_v2_runtime_license_snapshot_t;

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* COAKKA_V2_RUNTIME_DISTRIBUTION_H */
