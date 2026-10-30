#ifndef COAKKA_V2_TRANSPORT_H
#define COAKKA_V2_TRANSPORT_H

#include <stddef.h>
#include <stdint.h>

#include "coakka/v2/runtime.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct coakka_v2_frame_reader_t coakka_v2_frame_reader_t;

/*
 * Stable deadletter reason vocabulary shared by framed runtime deadletter
 * payloads and public C clients. Numeric values are the stable wire reason
 * values; preserve them when projecting a received deadletter.
 */
typedef enum coakka_v2_deadletter_reason_t {
    COAKKA_V2_DEADLETTER_REASON_UNSPECIFIED = 0u,
    COAKKA_V2_DEADLETTER_REASON_NO_ACTIVE_SNAPSHOT = 1u,
    COAKKA_V2_DEADLETTER_REASON_ROUTE_MISS = 2u,
    COAKKA_V2_DEADLETTER_REASON_NO_RESPONSIBLE_HOST = 3u,
    COAKKA_V2_DEADLETTER_REASON_QUEUE_REJECTED = 4u,
    COAKKA_V2_DEADLETTER_REASON_LOCAL_HANDOFF_FAILED = 5u,
    COAKKA_V2_DEADLETTER_REASON_DELIVERY_FAILED = 6u,
    COAKKA_V2_DEADLETTER_REASON_REMOTE_TRANSPORT_FAILED = 7u,
    COAKKA_V2_DEADLETTER_REASON_RUNTIME_STOPPED = 8u,
    COAKKA_V2_DEADLETTER_REASON_INVALID_ENVELOPE = 9u,
    COAKKA_V2_DEADLETTER_REASON_ENDPOINT_UNAVAILABLE = 10u,
    COAKKA_V2_DEADLETTER_REASON_REMOTE_REPLY_TIMEOUT = 11u,
    COAKKA_V2_DEADLETTER_REASON_LOCALITY_MISMATCH = 12u,
    COAKKA_V2_DEADLETTER_REASON_EXPIRED_BEFORE_DELIVERY = 13u,
    COAKKA_V2_DEADLETTER_REASON_ONE_WAY_DROPPED_BY_POLICY = 14u,
    COAKKA_V2_DEADLETTER_REASON_REMOTE_TRANSPORT_SECURITY_FAILED = 15u
} coakka_v2_deadletter_reason_t;

/**
 * Creates a bounded framed-pipe reader.
 *
 * The reader does not own fd. The host remains responsible for closing the fd
 * when the lane is no longer needed.
 */
coakka_v2_frame_reader_t *coakka_v2_frame_reader_create(int fd, size_t max_frame_size);

/** Destroys a frame reader without closing the fd passed at creation time. */
void coakka_v2_frame_reader_destroy(coakka_v2_frame_reader_t *reader);

/**
 * Attempts to read one complete frame without blocking the runtime.
 *
 * Returns COAKKA_V2_ERR_WOULD_BLOCK when no full frame is available. On
 * COAKKA_V2_OK, out_buf is caller-owned and must be released with
 * coakka_v2_frame_release(). Frames whose advertised payload length exceeds
 * max_frame_size or cannot be represented safely by the runtime allocator are
 * rejected as COAKKA_V2_ERR_IO.
 */
coakka_v2_status_t coakka_v2_frame_read_try(coakka_v2_frame_reader_t *reader,
                                            uint8_t **out_buf,
                                            size_t *out_len);

/**
 * Reads one complete frame within a bounded monotonic wait.
 *
 * The reader remains the sole consumer and retains partial-frame state between
 * calls. timeout_ms=0 is exactly one non-blocking attempt. On success the
 * caller owns out_buf as with coakka_v2_frame_read_try(). A peer close before
 * any frame byte returns CLOSED; close after a partial frame returns IO.
 */
coakka_v2_status_t coakka_v2_frame_read_wait(coakka_v2_frame_reader_t *reader,
                                             uint32_t timeout_ms,
                                             uint8_t **out_buf,
                                             size_t *out_len);

/** Writes one length-prefixed frame to fd. The payload span is not retained. */
coakka_v2_status_t coakka_v2_frame_write(int fd,
                                         const uint8_t *payload,
                                         size_t payload_len);

/** Releases a buffer returned by coakka_v2_frame_read_try()/read_wait(). */
void coakka_v2_frame_release(uint8_t *buf);

/**
 * Consumes monitor doorbell bytes and returns the number of signals drained.
 *
 * monitor_read_fd is a wakeup signal. It does not carry serialized monitor
 * event records; refresh stats/health through direct runtime APIs after drain.
 */
coakka_v2_status_t coakka_v2_monitor_consume(int fd, uint64_t *out_signal_count);

/** Waits monotonically for and consumes one or more monitor doorbell signals. */
coakka_v2_status_t coakka_v2_monitor_wait_consume(int fd,
                                                  uint32_t timeout_ms,
                                                  uint64_t *out_signal_count);

/**
 * Closes every advertised host handle exactly once and resets fitting fields.
 *
 * NULL is a no-op. struct_size=0 means the current full struct. Duplicate fd
 * values are closed once. Fields beyond a legacy caller's advertised span are
 * neither read nor written.
 */
void coakka_v2_host_handles_close(coakka_v2_host_handles_t *handles);

#ifdef __cplusplus
}
#endif

#endif
