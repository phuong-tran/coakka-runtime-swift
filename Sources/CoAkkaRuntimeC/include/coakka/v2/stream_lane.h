#ifndef COAKKA_V2_STREAM_LANE_H
#define COAKKA_V2_STREAM_LANE_H

#include <stddef.h>
#include <stdint.h>

#include "coakka/v2/lane_grant.h"
#include "coakka/v2/runtime.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Opaque lane owned by the caller from create through stop and destroy. */
typedef struct coakka_v2_stream_lane_t coakka_v2_stream_lane_t;

/** Stable limits, defaults, capability flags, and application frame flags. */
enum {
  COAKKA_V2_STREAM_LANE_WIRE_VERSION = 1u,
  COAKKA_V2_STREAM_LANE_ENABLE_PUBLISHER = 1u << 0,
  COAKKA_V2_STREAM_LANE_ENABLE_SUBSCRIBER = 1u << 1,
  COAKKA_V2_STREAM_LANE_SESSION_ID_MAX_BYTES = 64u,
  COAKKA_V2_STREAM_LANE_TOKEN_MAX_BYTES = 128u,
  COAKKA_V2_STREAM_LANE_DETAIL_MAX_BYTES = 160u,
  COAKKA_V2_STREAM_LANE_DEFAULT_CAPACITY = 8u,
  COAKKA_V2_STREAM_LANE_MAX_CAPACITY = 64u,
  COAKKA_V2_STREAM_LANE_DEFAULT_MAX_FRAME_BYTES = 256u * 1024u,
  COAKKA_V2_STREAM_LANE_MAX_FRAME_BYTES = 4u * 1024u * 1024u,
  COAKKA_V2_STREAM_LANE_MAX_WINDOW_BYTES = 16u * 1024u * 1024u,
  COAKKA_V2_STREAM_LANE_DEFAULT_IO_TIMEOUT_MS = 30000u,
  COAKKA_V2_STREAM_LANE_DEFAULT_SOURCE_RETRY_MS = 5u,
  COAKKA_V2_STREAM_LANE_MAX_SOURCE_RETRY_MS = 1000u,
  COAKKA_V2_STREAM_LANE_DEFAULT_PROGRESS_FRAMES = 30u,
  COAKKA_V2_STREAM_LANE_DEFAULT_PROGRESS_INTERVAL_MS = 250u,
  COAKKA_V2_STREAM_LANE_DEFAULT_PRESSURE_AFTER_MS = 100u,
  COAKKA_V2_STREAM_LANE_DEFAULT_STALLED_AFTER_MS = 1000u,
  COAKKA_V2_STREAM_LANE_DEFAULT_RECOVERY_AFTER_MS = 500u,
  COAKKA_V2_STREAM_LANE_DEFAULT_PRESSURE_OBSERVATION_MS = 100u,
  COAKKA_V2_STREAM_LANE_MAX_PRESSURE_INTERVAL_MS = 60000u,
  COAKKA_V2_STREAM_LANE_MAX_WORKERS = 4u,
  COAKKA_V2_STREAM_LANE_FRAME_FLAG_KEYFRAME = 1u << 0,
  COAKKA_V2_STREAM_LANE_FRAME_FLAG_DISCONTINUITY = 1u << 1,
  COAKKA_V2_STREAM_LANE_FRAME_FLAG_END_OF_SEGMENT = 1u << 2
};

/** Transport protection selected once when the lane is created. */
typedef enum coakka_v2_stream_lane_security_mode_t {
  COAKKA_V2_STREAM_LANE_SECURITY_DIRECT = COAKKA_V2_TCP_SECURITY_PLAINTEXT,
  COAKKA_V2_STREAM_LANE_SECURITY_TLS = COAKKA_V2_TCP_SECURITY_TLS,
  COAKKA_V2_STREAM_LANE_SECURITY_MUTUAL_TLS = COAKKA_V2_TCP_SECURITY_MUTUAL_TLS
} coakka_v2_stream_lane_security_mode_t;

/** Identifies the publisher or subscriber record for one session id. */
typedef enum coakka_v2_stream_direction_t {
  COAKKA_V2_STREAM_DIRECTION_PUBLISH = 1u,
  COAKKA_V2_STREAM_DIRECTION_SUBSCRIBE = 2u
} coakka_v2_stream_direction_t;

/** Lifecycle state of one publisher or subscriber record. */
typedef enum coakka_v2_stream_state_t {
  COAKKA_V2_STREAM_STATE_PREPARED = 1u,
  COAKKA_V2_STREAM_STATE_QUEUED = 2u,
  COAKKA_V2_STREAM_STATE_CONNECTING = 3u,
  COAKKA_V2_STREAM_STATE_ACTIVE = 4u,
  COAKKA_V2_STREAM_STATE_STOPPING = 5u,
  COAKKA_V2_STREAM_STATE_ENDED = 6u,
  COAKKA_V2_STREAM_STATE_REJECTED = 7u,
  COAKKA_V2_STREAM_STATE_FAILED = 8u,
  COAKKA_V2_STREAM_STATE_CANCELED = 9u
} coakka_v2_stream_state_t;

/**
 * Neutral transport-pressure state observed by the lane.
 *
 * These states describe delivery conditions only. They do not prescribe a
 * codec, resolution, frame-rate, retry, or shedding policy.
 */
typedef enum coakka_v2_stream_pressure_state_t {
  COAKKA_V2_STREAM_PRESSURE_INACTIVE = 0u,
  COAKKA_V2_STREAM_PRESSURE_FLOWING = 1u,
  COAKKA_V2_STREAM_PRESSURE_PRESSURED = 2u,
  COAKKA_V2_STREAM_PRESSURE_STALLED = 3u,
  COAKKA_V2_STREAM_PRESSURE_RECOVERING = 4u
} coakka_v2_stream_pressure_state_t;

/** Bitmask reasons which may be combined in a pressure snapshot. */
enum {
  COAKKA_V2_STREAM_PRESSURE_REASON_CREDIT_WAIT = 1u << 0,
  COAKKA_V2_STREAM_PRESSURE_REASON_TRANSPORT_WRITE = 1u << 1,
  COAKKA_V2_STREAM_PRESSURE_REASON_CONSUMER_BUSY = 1u << 2,
  COAKKA_V2_STREAM_PRESSURE_REASON_TRANSPORT_READ = 1u << 3
};

/** Stable terminal result reported independently by each session side. */
typedef enum coakka_v2_stream_result_t {
  COAKKA_V2_STREAM_RESULT_NONE = 0u,
  COAKKA_V2_STREAM_RESULT_OK = 1u,
  COAKKA_V2_STREAM_RESULT_NOT_PREPARED = 2u,
  COAKKA_V2_STREAM_RESULT_TOKEN_MISMATCH = 3u,
  COAKKA_V2_STREAM_RESULT_FORMAT_MISMATCH = 4u,
  COAKKA_V2_STREAM_RESULT_FRAME_LIMIT = 5u,
  COAKKA_V2_STREAM_RESULT_NETWORK_IO = 6u,
  COAKKA_V2_STREAM_RESULT_TIMEOUT = 7u,
  COAKKA_V2_STREAM_RESULT_QUEUE_FULL = 8u,
  COAKKA_V2_STREAM_RESULT_PROTOCOL_ERROR = 9u,
  COAKKA_V2_STREAM_RESULT_SOURCE_ERROR = 10u,
  COAKKA_V2_STREAM_RESULT_CONSUMER_ERROR = 11u,
  COAKKA_V2_STREAM_RESULT_INTERNAL_ERROR = 12u,
  COAKKA_V2_STREAM_RESULT_CANCELED_BY_HOST = 13u,
  COAKKA_V2_STREAM_RESULT_TLS_CONFIG_INVALID = 14u,
  COAKKA_V2_STREAM_RESULT_TLS_HANDSHAKE_FAILED = 15u,
  COAKKA_V2_STREAM_RESULT_PEER_CERT_UNTRUSTED = 16u,
  COAKKA_V2_STREAM_RESULT_PEER_CERT_EXPIRED = 17u,
  COAKKA_V2_STREAM_RESULT_PEER_IDENTITY_MISMATCH = 18u,
  COAKKA_V2_STREAM_RESULT_CLIENT_CERT_REQUIRED = 19u
} coakka_v2_stream_result_t;

/**
 * Metadata for one ordered frame.
 *
 * Source callbacks set captured_mono_ns, dropped_before, flags, and size.
 * The lane assigns sequence. Consumer callbacks receive every field. A zero
 * monotonic timestamp means the source did not supply one; it is never a wall
 * clock timestamp. size is measured in bytes.
 */
typedef struct coakka_v2_stream_frame_t {
  size_t struct_size;
  uint64_t sequence;
  uint64_t captured_mono_ns;
  uint64_t dropped_before;
  uint32_t flags;
  size_t size;
} coakka_v2_stream_frame_t;

/**
 * Produces one frame in runtime-owned destination storage.
 *
 * Return OK with a non-empty frame, WOULD_BLOCK when no frame is ready,
 * CLOSED for graceful source end, or another status for source failure.
 * sequence is lane-owned and ignored on source return. destination and
 * out_frame are borrowed only for this call. The callback may write at most
 * capacity bytes and must return a size in [1, capacity] with OK. It can be
 * invoked on a publisher worker and must bound internal waits so cancellation
 * and lane stop remain observable. It must not call stop or destroy on the
 * same lane.
 *
 * @param context Borrowed app-host state retained by the publish record.
 * @param destination Borrowed runtime-owned storage for this invocation only.
 * @param capacity Writable destination capacity in bytes.
 * @param out_frame Borrowed metadata output initialized by the runtime.
 * @return OK, WOULD_BLOCK, CLOSED, or another stable failure status.
 */
typedef coakka_v2_status_t (*coakka_v2_stream_source_next_fn)(
    void *context, uint8_t *destination, size_t capacity,
    coakka_v2_stream_frame_t *out_frame);

/**
 * Consumes borrowed frame bytes. data and frame are valid only during the
 * call; copy data before returning if the app-host needs to retain it. The
 * callback runs on a subscriber worker and must remain bounded. Return OK
 * after consumption, CLOSED to request a clean end, or another status to fail
 * the subscriber. It must not call stop or destroy on the same lane.
 *
 * @param context Borrowed app-host state retained by the subscribe record.
 * @param data Borrowed frame bytes valid only for this invocation.
 * @param frame Borrowed immutable metadata valid only for this invocation.
 * @return OK to continue, CLOSED to end cleanly, or a failure status.
 */
typedef coakka_v2_status_t (*coakka_v2_stream_consumer_fn)(
    void *context, const uint8_t *data, const coakka_v2_stream_frame_t *frame);

/**
 * Stream transport protection copied during lane creation.
 *
 * DIRECT requires a protected deployment network. TLS authenticates the
 * publisher endpoint; MUTUAL_TLS authenticates both peers. Publisher-only TLS
 * lanes need an identity certificate and private key. Subscriber-only TLS
 * lanes need a CA certificate. Mutual-TLS peers need both. credential_id is
 * diagnostic identity, while credential_generation lets the app-host identify
 * the selected immutable credential set.
 */
typedef struct coakka_v2_stream_lane_security_config_t {
  size_t struct_size;
  uint32_t mode;
  uint32_t reserved;
  uint64_t credential_generation;
  const char *credential_id;
  const char *ca_certificate_file;
  const char *identity_certificate_file;
  const char *private_key_file;
} coakka_v2_stream_lane_security_config_t;

/**
 * Bounded configuration copied synchronously during create.
 *
 * flags selects at least one lane role. bind_port=0 requests an ephemeral
 * publisher port. capacity bounds retained/queued records. max_frame_bytes and
 * max_window_bytes are byte limits. Timeout, retry, progress, and pressure
 * intervals are milliseconds; zero selects the documented default. Worker
 * counts are in [1, COAKKA_V2_STREAM_LANE_MAX_WORKERS], with zero selecting
 * one worker. A null security pointer selects DIRECT. The caller may release
 * the config, security object, and all referenced strings after create returns.
 */
typedef struct coakka_v2_stream_lane_config_t {
  size_t struct_size;
  uint32_t flags;
  const char *bind_host;
  uint16_t bind_port;
  size_t capacity;
  uint32_t max_frame_bytes;
  uint32_t max_window_bytes;
  uint32_t io_timeout_ms;
  uint32_t source_retry_ms;
  uint32_t progress_frames;
  uint32_t progress_interval_ms;
  uint32_t publisher_worker_count;
  uint32_t subscriber_worker_count;
  const coakka_v2_stream_lane_security_config_t *security;
  /* Zero selects the documented transport-pressure timing defaults. */
  uint32_t pressure_after_ms;
  uint32_t stalled_after_ms;
  uint32_t recovery_after_ms;
  uint32_t pressure_observation_ms;
} coakka_v2_stream_lane_config_t;

/**
 * Additive owner-aware creation config for replica-pinned grants.
 *
 * Embedding the complete legacy lane config keeps its ABI frozen. The nested
 * configs are projected during create_owned; pointed-to strings and security
 * inputs are borrowed only for that call. Callers initialize all three
 * struct_size fields to the size of their respective type.
 */
typedef struct coakka_v2_stream_lane_owned_config_t {
  size_t struct_size;
  coakka_v2_stream_lane_config_t lane;
  coakka_v2_lane_owner_config_t owner;
} coakka_v2_stream_lane_owned_config_t;

/**
 * Publisher authorization and source prepared by the source-owning app-host.
 *
 * prepare_publish copies session_id and authorization_token, then retains the
 * callback and source_context as borrowed application state until the record
 * is forgotten or the lane is destroyed. The app-host must keep that state
 * alive and thread-safe for callback execution. format_id is opaque to CoAkka;
 * both peers must supply the same non-zero value. max_frame_bytes must not
 * exceed the lane bound.
 */
typedef struct coakka_v2_stream_publish_spec_t {
  size_t struct_size;
  const char *session_id;
  const char *authorization_token;
  uint64_t format_id;
  uint32_t max_frame_bytes;
  coakka_v2_stream_source_next_fn source_next;
  void *source_context;
} coakka_v2_stream_publish_spec_t;

/**
 * Subscriber job opened by the consuming app-host.
 *
 * subscribe copies every string, then retains consume and consumer_context as
 * borrowed application state until the record is forgotten or the lane is
 * destroyed. initial_window_bytes is receive credit in bytes and must cover at
 * least one negotiated frame. timeout_ms=0 selects the lane I/O timeout.
 */
typedef struct coakka_v2_stream_subscribe_spec_t {
  size_t struct_size;
  const char *session_id;
  const char *authorization_token;
  const char *remote_host;
  uint16_t remote_port;
  uint64_t format_id;
  uint32_t max_frame_bytes;
  uint32_t initial_window_bytes;
  uint32_t timeout_ms;
  coakka_v2_stream_consumer_fn consume;
  void *consumer_context;
} coakka_v2_stream_subscribe_spec_t;

/**
 * Publisher-issued capability for one prepared point-to-point session.
 *
 * The fixed-size value owns all text, including the secret token. Do not log
 * or persist the token. owner names the exact publisher instance and listener;
 * callers must not replace it with a replica-load-balancing service address.
 * The first valid OPEN consumes the capability before ACCEPT or frame delivery;
 * transport failure after admission requires a fresh prepare and grant.
 */
typedef struct coakka_v2_stream_publish_grant_t {
  size_t struct_size;
  coakka_v2_lane_owner_endpoint_t owner;
  char session_id[COAKKA_V2_STREAM_LANE_SESSION_ID_MAX_BYTES + 1u];
  char authorization_token[COAKKA_V2_STREAM_LANE_TOKEN_MAX_BYTES + 1u];
  uint64_t format_id;
  uint32_t max_frame_bytes;
  uint32_t reserved;
} coakka_v2_stream_publish_grant_t;

/**
 * Caller-owned point-in-time session projection.
 *
 * frames, bytes, dropped_frames, and last_sequence are cumulative for the
 * record. update_sequence increases whenever an observable projection changes
 * and is the cursor accepted by wait_session(). All *_mono_ns values use the
 * process-local monotonic clock and cannot be compared with wall time or with
 * timestamps from another process. terminal_mono_ns is zero until the record
 * reaches ENDED, REJECTED, FAILED, or CANCELED. detail is always NUL-terminated
 * when the caller supplies the current struct size.
 */
typedef struct coakka_v2_stream_session_snapshot_t {
  size_t struct_size;
  uint32_t direction;
  uint32_t state;
  uint32_t result;
  uint64_t format_id;
  uint64_t frames;
  uint64_t bytes;
  uint64_t dropped_frames;
  uint64_t last_sequence;
  uint32_t negotiated_max_frame_bytes;
  uint32_t window_bytes;
  uint32_t cancel_requested;
  uint64_t update_sequence;
  uint64_t submitted_mono_ns;
  uint64_t started_mono_ns;
  uint64_t updated_mono_ns;
  uint64_t terminal_mono_ns;
  char detail[COAKKA_V2_STREAM_LANE_DETAIL_MAX_BYTES];
} coakka_v2_stream_session_snapshot_t;

/**
 * Bounded operational counters for one lane instance.
 *
 * queued/active/prepared/retained values are current gauges. The remaining
 * values are cumulative until lane destruction. Failed counts exclude clean
 * ends and host cancellations. Byte and frame counts describe transport work;
 * they do not imply application-level decoding or persistence.
 */
typedef struct coakka_v2_stream_lane_stats_t {
  size_t struct_size;
  size_t capacity;
  size_t queued_subscribers;
  size_t prepared_publishers;
  size_t active_publishers;
  size_t active_subscribers;
  size_t retained_records;
  uint64_t submitted_subscribers;
  uint64_t prepared_publisher_count;
  uint64_t ended_publishers;
  uint64_t ended_subscribers;
  uint64_t failed_publishers;
  uint64_t failed_subscribers;
  uint64_t canceled_sessions;
  uint64_t published_frames;
  uint64_t published_bytes;
  uint64_t consumed_frames;
  uint64_t consumed_bytes;
  uint64_t source_reported_drops;
} coakka_v2_stream_lane_stats_t;

/**
 * Caller-owned transport-pressure observation for app-host policy.
 *
 * Credit and window fields are bytes. Throughput is bytes per second. All
 * *_ns values are process-local monotonic timestamps or durations. A zero
 * pressure_started_mono_ns means the record has not entered pressure in its
 * current observation history. update_sequence is the cursor accepted by
 * wait_pressure(); updates may be coalesced by pressure_observation_ms.
 */
typedef struct coakka_v2_stream_pressure_snapshot_t {
  size_t struct_size;
  uint32_t direction;
  uint32_t state;
  uint32_t reason_bits;
  uint32_t available_credit_bytes;
  uint32_t window_capacity_bytes;
  uint64_t update_sequence;
  uint64_t transition_count;
  uint64_t observed_mono_ns;
  uint64_t state_started_mono_ns;
  uint64_t pressure_started_mono_ns;
  uint64_t last_progress_mono_ns;
  uint64_t observed_delivery_bps;
  uint64_t current_operation_ns;
  uint64_t last_operation_ns;
  uint64_t total_pressured_ns;
  uint64_t max_pressured_ns;
} coakka_v2_stream_pressure_snapshot_t;

/**
 * Creates a stopped lane, or returns NULL on invalid config or allocation
 * failure. Prefer create_ex when the caller needs the exact failure status.
 * The returned lane is owned by the caller and must be destroyed.
 *
 * @param config Borrowed configuration copied before this call returns.
 * @return Owned stopped lane, or NULL on invalid input or allocation failure.
 */
coakka_v2_stream_lane_t *
coakka_v2_stream_lane_create(const coakka_v2_stream_lane_config_t *config);

/**
 * Creates a stopped lane and writes caller-owned output only on success.
 *
 * @param config Borrowed configuration copied before this call returns.
 * @param out_lane Receives the owned stopped lane on success or NULL on failure.
 * @return Stable runtime status.
 */
coakka_v2_status_t
coakka_v2_stream_lane_create_ex(const coakka_v2_stream_lane_config_t *config,
                                coakka_v2_stream_lane_t **out_lane);

/**
 * Creates a stopped owner-aware lane for replica-pinned publish grants.
 * The complete nested lane and owner configuration is copied before return.
 * The caller owns a successful result and must stop it before destroy.
 *
 * @param config Borrowed owner-aware configuration copied during this call.
 * @return Owned stopped lane, or NULL on validation or allocation failure.
 */
coakka_v2_stream_lane_t *coakka_v2_stream_lane_create_owned(
    const coakka_v2_stream_lane_owned_config_t *config);

/**
 * Status-returning owner-aware factory used by prepare_publish_grant.
 * Caller output is set to NULL on failure and receives ownership on success.
 *
 * @param config Borrowed owner-aware configuration copied during this call.
 * @param out_lane Receives the owned stopped lane on success or NULL on failure.
 * @return COAKKA_V2_OK on success or a stable validation/allocation status.
 */
coakka_v2_status_t coakka_v2_stream_lane_create_owned_ex(
    const coakka_v2_stream_lane_owned_config_t *config,
    coakka_v2_stream_lane_t **out_lane);

/**
 * Releases a stopped lane. Passing NULL is allowed. The caller must first
 * prevent concurrent API calls and complete stop; destroy does not substitute
 * for lifecycle coordination.
 *
 * @param lane Owned stopped lane or NULL.
 */
void coakka_v2_stream_lane_destroy(coakka_v2_stream_lane_t *lane);

/**
 * Starts workers and, for publisher lanes, the configured listener. Start and
 * stop transitions are internally serialized; admission is accepted only
 * after start completes.
 *
 * @param lane Owned stopped lane.
 * @return COAKKA_V2_OK on transition to started, otherwise a stable status.
 */
coakka_v2_status_t coakka_v2_stream_lane_start(coakka_v2_stream_lane_t *lane);

/**
 * Requests stop, prevents new admission before cancellation begins, wakes
 * blocked waits, and joins workers. Repeated and concurrent start/stop calls
 * are internally serialized. Callback contexts remain borrowed until records
 * are forgotten or the lane is destroyed; destroy still requires caller-side
 * exclusion.
 *
 * @param lane Owned lane to stop.
 * @return COAKKA_V2_OK for a valid lane, including repeated stop calls.
 */
coakka_v2_status_t coakka_v2_stream_lane_stop(coakka_v2_stream_lane_t *lane);

/**
 * Reads the active publisher port after start; output is unchanged on error.
 *
 * @param lane Borrowed started publisher-capable lane.
 * @param out_port Receives the bound host-order port on success.
 * @return Stable runtime status.
 */
coakka_v2_status_t
coakka_v2_stream_lane_get_bound_port(coakka_v2_stream_lane_t *lane,
                                     uint16_t *out_port);

/**
 * Registers one publisher authorization and callback. The session id must be
 * unique among retained publisher records. This call does not invoke source.
 *
 * @param lane Borrowed started publisher-capable lane.
 * @param spec Borrowed spec; strings are copied and callback context retained.
 * @return COAKKA_V2_OK on admission or a stable rejection status.
 */
coakka_v2_status_t coakka_v2_stream_lane_prepare_publish(
    coakka_v2_stream_lane_t *lane, const coakka_v2_stream_publish_spec_t *spec);

/**
 * Prepares one publisher and returns a replica-pinned session capability.
 *
 * The lane must be started with publisher capability and a valid owner config.
 * On success the grant contains the lane's copied owner identity and actual
 * bound port. Stop or owner loss invalidates the capability; another replica
 * must prepare and issue a new grant rather than reuse this one. The first
 * valid OPEN consumes the grant even if ACCEPT or later delivery fails.
 *
 * @param lane Borrowed started publisher-capable lane.
 * @param spec Borrowed publisher authorization copied by the lane.
 * @param out_grant Caller-owned output initialized with struct_size.
 * @return COAKKA_V2_OK, or a stable rejection without modifying out_grant.
 */
coakka_v2_status_t coakka_v2_stream_lane_prepare_publish_grant(
    coakka_v2_stream_lane_t *lane,
    const coakka_v2_stream_publish_spec_t *spec,
    coakka_v2_stream_publish_grant_t *out_grant);

/**
 * Queues one outbound subscriber job. Queue admission is bounded and may
 * return QUEUE_FULL without retaining the job.
 *
 * @param lane Borrowed started subscriber-capable lane.
 * @param spec Borrowed spec; strings are copied and callback context retained.
 * @return COAKKA_V2_OK on admission or a stable rejection status.
 */
coakka_v2_status_t
coakka_v2_stream_lane_subscribe(coakka_v2_stream_lane_t *lane,
                                const coakka_v2_stream_subscribe_spec_t *spec);

/**
 * Copies the latest projection for one retained direction/session record.
 *
 * @param lane Borrowed lane retaining the record.
 * @param session_id Borrowed NUL-terminated application session ID.
 * @param direction Publisher or subscriber record to observe.
 * @param out_snapshot Caller-owned output initialized with struct_size.
 * @return COAKKA_V2_OK on copy; output is unspecified on failure.
 */
coakka_v2_status_t coakka_v2_stream_lane_get_session(
    coakka_v2_stream_lane_t *lane, const char *session_id, uint32_t direction,
    coakka_v2_stream_session_snapshot_t *out_snapshot);

/**
 * Waits until the record update_sequence is newer than after_update_sequence.
 * timeout_ms=0 performs a non-blocking observation and returns WOULD_BLOCK if
 * no newer projection exists. Stop wakes the wait. On OK, out_snapshot is a
 * complete copied projection; on error its contents are unspecified.
 *
 * @param lane Borrowed lane retaining the record.
 * @param session_id Borrowed NUL-terminated application session ID.
 * @param direction Publisher or subscriber record to observe.
 * @param after_update_sequence Last update already processed.
 * @param timeout_ms Bounded wait in milliseconds; zero is non-blocking.
 * @param out_snapshot Caller-owned output initialized with struct_size.
 * @return COAKKA_V2_OK, WOULD_BLOCK, CLOSED, or another stable status.
 */
coakka_v2_status_t coakka_v2_stream_lane_wait_session(
    coakka_v2_stream_lane_t *lane, const char *session_id, uint32_t direction,
    uint64_t after_update_sequence, uint32_t timeout_ms,
    coakka_v2_stream_session_snapshot_t *out_snapshot);

/**
 * Copies the latest pressure projection for one retained session record.
 *
 * @param lane Borrowed lane retaining the record.
 * @param session_id Borrowed NUL-terminated application session ID.
 * @param direction Publisher or subscriber record to observe.
 * @param out_snapshot Caller-owned output initialized with struct_size.
 * @return COAKKA_V2_OK on copy; output is unspecified on failure.
 */
coakka_v2_status_t coakka_v2_stream_lane_get_pressure(
    coakka_v2_stream_lane_t *lane, const char *session_id, uint32_t direction,
    coakka_v2_stream_pressure_snapshot_t *out_snapshot);

/**
 * Waits for a coalesced pressure update newer than after_update_sequence.
 * timeout_ms=0 is non-blocking and returns WOULD_BLOCK when no update exists.
 * Stop wakes the wait. On error, out_snapshot contents are unspecified.
 *
 * @param lane Borrowed lane retaining the record.
 * @param session_id Borrowed NUL-terminated application session ID.
 * @param direction Publisher or subscriber record to observe.
 * @param after_update_sequence Last pressure update already processed.
 * @param timeout_ms Bounded wait in milliseconds; zero is non-blocking.
 * @param out_snapshot Caller-owned output initialized with struct_size.
 * @return COAKKA_V2_OK, WOULD_BLOCK, CLOSED, or another stable status.
 */
coakka_v2_status_t coakka_v2_stream_lane_wait_pressure(
    coakka_v2_stream_lane_t *lane, const char *session_id, uint32_t direction,
    uint64_t after_update_sequence, uint32_t timeout_ms,
    coakka_v2_stream_pressure_snapshot_t *out_snapshot);

/**
 * Requests cooperative cancellation. Queued/prepared records transition
 * synchronously; active callbacks and I/O observe the request asynchronously.
 * Wait for a terminal snapshot before releasing callback state or forgetting.
 *
 * @param lane Borrowed lane retaining the record.
 * @param session_id Borrowed NUL-terminated application session ID.
 * @param direction Publisher or subscriber record to cancel.
 * @return Stable runtime status for the cancellation request.
 */
coakka_v2_status_t coakka_v2_stream_lane_cancel_session(
    coakka_v2_stream_lane_t *lane, const char *session_id, uint32_t direction);

/**
 * Removes one terminal record and releases the lane's callback reference.
 * Active records cannot be forgotten. After success, the app-host may release
 * the callback context for that direction/session pair.
 *
 * @param lane Borrowed lane retaining the terminal record.
 * @param session_id Borrowed NUL-terminated application session ID.
 * @param direction Publisher or subscriber record to release.
 * @return COAKKA_V2_OK on release or BAD_STATE for non-terminal work.
 */
coakka_v2_status_t coakka_v2_stream_lane_forget_session(
    coakka_v2_stream_lane_t *lane, const char *session_id, uint32_t direction);

/**
 * Copies current gauges and cumulative counters without blocking on I/O.
 *
 * @param lane Borrowed lane.
 * @param out_stats Caller-owned output initialized with struct_size.
 * @return COAKKA_V2_OK on copy; output is unspecified on failure.
 */
coakka_v2_status_t
coakka_v2_stream_lane_get_stats(coakka_v2_stream_lane_t *lane,
                                coakka_v2_stream_lane_stats_t *out_stats);

#ifdef __cplusplus
}
#endif

#endif
