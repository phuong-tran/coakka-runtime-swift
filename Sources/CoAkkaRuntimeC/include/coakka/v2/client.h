#ifndef COAKKA_V2_CLIENT_H
#define COAKKA_V2_CLIENT_H

#include <stddef.h>
#include <stdint.h>

#include "coakka/v2/runtime.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct coakka_v2_ask_client_t coakka_v2_ask_client_t;
typedef struct coakka_v2_ask_ticket_t coakka_v2_ask_ticket_t;

/** Result kind returned by a completed ask ticket. */
typedef enum coakka_v2_client_result_kind_t {
    COAKKA_V2_CLIENT_RESULT_NONE = 0,
    COAKKA_V2_CLIENT_RESULT_RESPONSE = 1,
    COAKKA_V2_CLIENT_RESULT_DEADLETTER = 2
} coakka_v2_client_result_kind_t;

/** Delivery preference encoded into a connector-built request envelope. */
typedef enum coakka_v2_client_delivery_hint_t {
    COAKKA_V2_CLIENT_DELIVERY_HINT_UNSPECIFIED = 0,
    COAKKA_V2_CLIENT_DELIVERY_HINT_ROUTER_DEFAULT = 1,
    COAKKA_V2_CLIENT_DELIVERY_HINT_PREFER_LOCAL = 2,
    COAKKA_V2_CLIENT_DELIVERY_HINT_REQUIRE_LOCAL = 3,
    COAKKA_V2_CLIENT_DELIVERY_HINT_REQUIRE_REMOTE = 4
} coakka_v2_client_delivery_hint_t;

/** Envelope kinds accepted by the opaque payload projection helper. */
typedef enum coakka_v2_client_envelope_kind_t {
    COAKKA_V2_CLIENT_ENVELOPE_REQUEST = 1,
    COAKKA_V2_CLIENT_ENVELOPE_RESPONSE = 2
} coakka_v2_client_envelope_kind_t;

/**
 * Raw request envelope builder input.
 *
 * The caller owns every string and payload byte span for the duration of the
 * build call. The returned buffer is owned by the caller and must be released
 * with coakka_v2_client_bytes_release(). Required fields outside struct_size
 * fail closed. Required strings must be non-empty. Optional tail fields outside
 * struct_size use safe defaults. struct_size = 0 means the current full local
 * struct. delivery_hint must be one of coakka_v2_client_delivery_hint_t, and
 * one_way must be 0 or 1. timeout_ms must fit the transport int32 timeout
 * field.
 */
typedef struct coakka_v2_client_raw_request_spec_t {
    size_t struct_size;
    const char *message_id;
    const char *source;
    const char *target;
    const char *reply_to;
    const uint8_t *payload;
    size_t payload_len;
    uint32_t timeout_ms;
    uint32_t delivery_hint;
    uint32_t one_way;
} coakka_v2_client_raw_request_spec_t;

/**
 * Raw reply envelope builder input.
 *
 * request_buf/request_len must contain one delivered request frame returned by
 * the runtime. The returned reply buffer is caller-owned and must be released
 * with coakka_v2_client_bytes_release(). Required fields outside struct_size
 * fail closed. Required strings must be non-empty. Optional tail fields outside
 * struct_size use safe defaults. struct_size = 0 means the current full local
 * struct. request_len must not exceed INT_MAX bytes.
 * The request frame must be reply-capable: MESSAGE_KIND_REQUEST,
 * one_way=false, and non-empty message_id/source.
 */
typedef struct coakka_v2_client_raw_reply_spec_t {
    size_t struct_size;
    const uint8_t *request_buf;
    size_t request_len;
    const char *source;
    const uint8_t *payload;
    size_t payload_len;
} coakka_v2_client_raw_reply_spec_t;

/**
 * Creates connector-side ask state over an already-created runtime host.
 *
 * The host handles span must include response_read_fd, deadletter_read_fd, and
 * delivered_request_read_fd; older spans fail closed instead of reading beyond
 * the caller's advertised struct_size. struct_size = 0 means the current full
 * local host-handle struct.
 */
coakka_v2_ask_client_t *coakka_v2_ask_client_create(
    coakka_v2_runtime_t *rt,
    const coakka_v2_host_handles_t *handles
);

/**
 * Creates the same ask owner with an authoritative failure status.
 *
 * out_client is required and cleared before fallible work. Success transfers
 * one owner, destroyed with ask_client_destroy after host calls quiesce.
 * Runtime/handle borrowing and required advertised handle fields are identical
 * to ask_client_create; no descriptor ownership transfers. No partial owner
 * escapes on failure: started readers/attachments are joined/retired first.
 *
 * INVALID_ARG reports invalid pointers, short handle spans or negative required
 * descriptors; NOMEM reports allocation failure. Runtime inspection/handoff
 * failures preserve their status, including terminal CLOSED during attachment.
 * Thread/placement system errors and unexpected exceptions report IO;
 * allocation exceptions remain NOMEM, never classified from error text.
 * The pointer-only entrypoint retains its original ABI and NULL-on-failure law.
 */
coakka_v2_status_t coakka_v2_ask_client_create_ex(
    coakka_v2_runtime_t *rt,
    const coakka_v2_host_handles_t *handles,
    coakka_v2_ask_client_t **out_client);

/** Destroys the ask client and releases connector-side matching state. */
void coakka_v2_ask_client_destroy(coakka_v2_ask_client_t *client);

/**
 * Submits a request frame and returns a ticket used to await or poll the result.
 * The request correlation_id may be absent (Core normalizes it to message_id)
 * or equal message_id. A different correlation_id is invalid because the ask
 * ticket's response and deadletter terminal identity is the request message_id.
 *
 * Returns COAKKA_V2_ERR_CLOSED when the ask helper has already observed that
 * the runtime's terminal response/deadletter lanes are no longer usable.
 */
coakka_v2_status_t coakka_v2_ask_client_begin(
    coakka_v2_ask_client_t *client,
    const uint8_t *request_buf,
    size_t request_len,
    coakka_v2_ask_ticket_t **out_ticket
);

/**
 * Blocks up to timeout_ms for a response or matched deadletter.
 *
 * On COAKKA_V2_OK, out_buf is caller-owned and must be released with
 * coakka_v2_client_bytes_release(). It remains valid independently of the
 * ticket, client and runtime lifetimes. Await/poll consumes the ticket's result.
 * Returns COAKKA_V2_ERR_WOULD_BLOCK when the caller wait window expires while
 * the ask remains pending. Returns COAKKA_V2_ERR_CLOSED when the runtime
 * closes its terminal response/deadletter lanes before any terminal result is
 * delivered.
 */
coakka_v2_status_t coakka_v2_ask_ticket_await(
    coakka_v2_ask_ticket_t *ticket,
    uint32_t timeout_ms,
    uint32_t *out_result_kind,
    uint8_t **out_buf,
    size_t *out_len
);

/**
 * Polls an ask ticket without blocking.
 *
 * Returns COAKKA_V2_ERR_WOULD_BLOCK when no response/deadletter is available.
 * Returns COAKKA_V2_ERR_CLOSED when the runtime has already closed terminal
 * ask lanes before any matched result arrived.
 * On COAKKA_V2_OK, out_buf is caller-owned and must be released with
 * coakka_v2_client_bytes_release().
 */
coakka_v2_status_t coakka_v2_ask_ticket_poll(
    coakka_v2_ask_ticket_t *ticket,
    uint32_t *out_result_kind,
    uint8_t **out_buf,
    size_t *out_len
);

/**
 * Stops local matching and discards any unconsumed result, including a result
 * that completed before cancellation. Does not revoke a buffer already returned
 * by await/poll. Safe to call before destroying the ticket; serialize host calls
 * on the same ticket.
 */
void coakka_v2_ask_ticket_cancel(coakka_v2_ask_ticket_t *ticket);

/** Returns the ticket's message id; the pointer is valid until ticket destroy. */
const char *coakka_v2_ask_ticket_message_id(const coakka_v2_ask_ticket_t *ticket);

/** Releases one ask ticket and any unconsumed result; awaiting is not required. */
void coakka_v2_ask_ticket_destroy(coakka_v2_ask_ticket_t *ticket);

/** Builds a raw request frame from a C-friendly spec. */
coakka_v2_status_t coakka_v2_client_build_raw_request(
    const coakka_v2_client_raw_request_spec_t *spec,
    uint8_t **out_buf,
    size_t *out_len
);

/** Builds a raw reply frame from a delivered request frame and response payload. */
coakka_v2_status_t coakka_v2_client_build_raw_reply(
    const coakka_v2_client_raw_reply_spec_t *spec,
    uint8_t **out_buf,
    size_t *out_len
);

/**
 * Validates one serialized request/response Envelope and copies its payload.
 *
 * frame_buf is borrowed only for this call. expected_kind must be one of
 * coakka_v2_client_envelope_kind_t and must match the wire Envelope exactly.
 * frame_len must not exceed INT_MAX bytes. On success,
 * an empty payload returns NULL/0; otherwise the caller owns out_payload and
 * must release it with coakka_v2_client_bytes_release(). Valid output pointers
 * are reset to NULL/0 before validation, including on malformed wire or kind
 * mismatch. The helper exposes only copied payload bytes, never a retained view.
 */
coakka_v2_status_t coakka_v2_client_copy_envelope_payload(
    const uint8_t *frame_buf,
    size_t frame_len,
    uint32_t expected_kind,
    uint8_t **out_payload,
    size_t *out_payload_len
);

/**
 * Validates a serialized request Envelope and copies dispatch facts.
 *
 * frame_buf is borrowed only for this call. The wire kind must be REQUEST and
 * target must be non-empty. On success, target is a non-empty caller-owned byte
 * span, payload is a caller-owned span or NULL/0 when empty, and out_one_way is
 * exactly 0 or 1 from the accepted request. Release both non-NULL spans with
 * coakka_v2_client_bytes_release(). Valid output pointers are reset before
 * validation and remain reset on every failure. No generated type or retained
 * view crosses this boundary.
 */
coakka_v2_status_t coakka_v2_client_copy_request_dispatch(
    const uint8_t *frame_buf,
    size_t frame_len,
    uint8_t **out_target,
    size_t *out_target_len,
    uint8_t **out_payload,
    size_t *out_payload_len,
    uint32_t *out_one_way
);

/** Releases buffers returned by client build and ask-ticket APIs. */
void coakka_v2_client_bytes_release(uint8_t *buf);

#ifdef __cplusplus
}
#endif

#endif
