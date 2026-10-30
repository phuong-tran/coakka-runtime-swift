#ifndef COAKKA_V2_LANE_GRANT_H
#define COAKKA_V2_LANE_GRANT_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum {
  COAKKA_V2_LANE_OWNER_INSTANCE_ID_MAX_BYTES = 127u,
  COAKKA_V2_LANE_ADVERTISED_HOST_MAX_BYTES = 255u
};

/**
 * Stable identity advertised by one receiver or publisher lane instance.
 *
 * The lane copies both strings during create. owner_instance_id identifies
 * the process or pod that owns prepared state. advertised_host must reach that
 * exact owner; a replica-load-balancing service address violates this
 * contract. The listener's actual bound port is supplied by the lane when it
 * issues a grant and is therefore intentionally absent here. Protocol v1 does
 * not carry or authenticate owner_instance_id on the File Offer or Stream Open;
 * it is a diagnostic/orchestration label, while pinning is endpoint-level.
 */
typedef struct coakka_v2_lane_owner_config_t {
  size_t struct_size;
  const char *owner_instance_id;
  const char *advertised_host;
} coakka_v2_lane_owner_config_t;

/**
 * Caller-owned point-in-time owner endpoint projected into a lane grant.
 *
 * The fixed-size value owns its text. It creates no connection and remains
 * valid as data after the lane stops, but the endpoint capability is valid
 * only while the named owner keeps the prepared lane session alive. A new
 * process or pod incarnation must use a fresh application token even when it
 * reuses the same host and port.
 */
typedef struct coakka_v2_lane_owner_endpoint_t {
  size_t struct_size;
  uint16_t port;
  uint16_t reserved;
  char owner_instance_id[COAKKA_V2_LANE_OWNER_INSTANCE_ID_MAX_BYTES + 1u];
  char advertised_host[COAKKA_V2_LANE_ADVERTISED_HOST_MAX_BYTES + 1u];
} coakka_v2_lane_owner_endpoint_t;

#ifdef __cplusplus
}
#endif

#endif
