#ifndef COAKKA_V2_MESSAGE_VALUE_H
#define COAKKA_V2_MESSAGE_VALUE_H

#include "coakka/v2/client.h"

#ifdef __cplusplus
extern "C" {
#endif

#define COAKKA_V2_MESSAGE_VALUE_MAX_FRAME_BYTES UINT64_C(67108864)
#define COAKKA_V2_MESSAGE_VALUE_MAX_METADATA_BYTES UINT64_C(1048576)

/** Borrowed bytes. Text fields are length-bearing UTF-8, including embedded
 * NUL; payload is opaque. NULL/0 is empty; NULL/nonzero is invalid. */
typedef struct coakka_v2_message_span_t {
    const uint8_t *data;
    size_t size;
} coakka_v2_message_span_t;

typedef struct coakka_v2_message_property_t {
    coakka_v2_message_span_t key;
    coakka_v2_message_span_t value;
} coakka_v2_message_property_t;

typedef struct coakka_v2_message_address_t {
    coakka_v2_message_span_t message_id;
    coakka_v2_message_span_t correlation_id;
    coakka_v2_message_span_t source;
    coakka_v2_message_span_t target;
    coakka_v2_message_span_t reply_to;
} coakka_v2_message_address_t;

/** Numeric kind/hint values retain their established message meaning; unknown
 * signed values are preserved. one_way must be exactly0/1. Runtime semantic
 * admission is separate; encoding does not authorize or submit a request. */
typedef struct coakka_v2_message_delivery_t {
    int32_t kind;
    uint32_t one_way;
    int32_t timeout_ms;
    int32_t delivery_hint;
} coakka_v2_message_delivery_t;

/** Application-owned payload declaration. Core never decodes the body using
 * this declaration. Unknown encoding values and schema version0 are preserved. */
typedef struct coakka_v2_message_payload_identity_t {
    coakka_v2_message_span_t message_type;
    uint32_t schema_version;
    int32_t format;
} coakka_v2_message_payload_identity_t;

/** Application business outcome, never a native delivery failure. */
typedef struct coakka_v2_message_business_result_t {
    int32_t status;
    coakka_v2_message_span_t error_code;
    coakka_v2_message_span_t error_message;
} coakka_v2_message_business_result_t;

/** Complete v1 message value. All inputs borrow only through encode. Optional
 * NULL groups mean zero values; decoded all-zero groups are NULL. This is
 * value semantics, not observed scalar wire presence. Duplicate property keys
 * use Core's last-value law; property order is unspecified. Unknown wire fields
 * are not retained. Every pointed-to output byte belongs to its value lease.
 * Set struct_size to the exact complete v1 size; zero/short/unknown sizes reject.
 * Future record-layout evolution requires a reviewed versioned entrypoint. */
typedef struct coakka_v2_message_value_t {
    size_t struct_size;
    coakka_v2_message_address_t address;
    coakka_v2_message_delivery_t delivery;
    coakka_v2_message_span_t payload;
    const coakka_v2_message_payload_identity_t *payload_identity;
    const coakka_v2_message_business_result_t *business;
    const coakka_v2_message_property_t *properties;
    size_t property_count;
} coakka_v2_message_value_t;

enum {
    COAKKA_V2_VALUE_FAILURE_DOMAIN_UNKNOWN = 0u,
    COAKKA_V2_VALUE_FAILURE_CONNECTIVITY = 1u,
    COAKKA_V2_VALUE_FAILURE_SECURITY = 2u,
    COAKKA_V2_VALUE_FAILURE_PROTOCOL = 3u,
    COAKKA_V2_VALUE_FAILURE_PRESSURE = 4u,
    COAKKA_V2_VALUE_FAILURE_LIFECYCLE = 5u,
    COAKKA_V2_VALUE_FAILURE_RESOURCE = 6u
};
enum {
    COAKKA_V2_VALUE_FAILURE_PHASE_UNKNOWN = 0u,
    COAKKA_V2_VALUE_FAILURE_CONFIG = 1u,
    COAKKA_V2_VALUE_FAILURE_ACQUIRE = 2u,
    COAKKA_V2_VALUE_FAILURE_CONNECT = 3u,
    COAKKA_V2_VALUE_FAILURE_HANDSHAKE = 4u,
    COAKKA_V2_VALUE_FAILURE_WRITE = 5u,
    COAKKA_V2_VALUE_FAILURE_READ = 6u,
    COAKKA_V2_VALUE_FAILURE_SHUTDOWN = 7u
};
enum {
    COAKKA_V2_VALUE_FAILURE_CODE_UNKNOWN = 0u,
    COAKKA_V2_VALUE_FAILURE_CONNECT_FAILED = 1u,
    COAKKA_V2_VALUE_FAILURE_ADAPTER_UNAVAILABLE = 2u,
    COAKKA_V2_VALUE_FAILURE_POOL_BUSY = 3u,
    COAKKA_V2_VALUE_FAILURE_NEGOTIATION_FAILED = 4u,
    COAKKA_V2_VALUE_FAILURE_EXCHANGE_FAILED = 5u,
    COAKKA_V2_VALUE_FAILURE_RESPONSE_TIMEOUT = 6u,
    COAKKA_V2_VALUE_FAILURE_RESPONSE_MALFORMED = 7u,
    COAKKA_V2_VALUE_FAILURE_RESPONSE_MISSING = 8u,
    COAKKA_V2_VALUE_FAILURE_ALLOCATION_FAILED = 9u,
    COAKKA_V2_VALUE_FAILURE_PEER_CERT_EXPIRED = 10u,
    COAKKA_V2_VALUE_FAILURE_FRAME_BUDGET_EXHAUSTED = 11u,
    COAKKA_V2_VALUE_FAILURE_FRAME_TOO_LARGE = 12u,
    COAKKA_V2_VALUE_FAILURE_TLS_CONFIG_INVALID = 13u,
    COAKKA_V2_VALUE_FAILURE_TLS_HANDSHAKE_FAILED = 14u,
    COAKKA_V2_VALUE_FAILURE_PEER_CERT_UNTRUSTED = 15u,
    COAKKA_V2_VALUE_FAILURE_PEER_IDENTITY_MISMATCH = 16u,
    COAKKA_V2_VALUE_FAILURE_CLIENT_CERT_REQUIRED = 17u,
    COAKKA_V2_VALUE_FAILURE_CREDENTIAL_RETIRED = 18u
};
enum {
    COAKKA_V2_VALUE_DELIVERY_UNKNOWN = 0u,
    COAKKA_V2_VALUE_NOT_DELIVERED = 1u,
    COAKKA_V2_VALUE_DELIVERY_AMBIGUOUS = 2u
};
enum {
    COAKKA_V2_VALUE_FAILURE_SCOPE_UNKNOWN = 0u,
    COAKKA_V2_VALUE_FAILURE_LOCAL_PROFILE = 1u,
    COAKKA_V2_VALUE_FAILURE_ENDPOINT = 2u,
    COAKKA_V2_VALUE_FAILURE_CONNECTION = 3u
};

/** Core-interpreted native failure dimensions. An unrecognized code remains0
 * with its raw bounded detail preserved; it is not a guessed successful cause. */
typedef struct coakka_v2_message_failure_t {
    uint32_t domain;
    uint32_t phase;
    uint32_t code;
    uint32_t certainty;
    uint32_t scope;
} coakka_v2_message_failure_t;

typedef struct coakka_v2_deadletter_value_t {
    size_t struct_size;
    const coakka_v2_message_value_t *original;
    int32_t reason;
    uint64_t active_generation;
    coakka_v2_message_span_t detail;
    coakka_v2_message_span_t resolved_host;
    uint32_t resolved_port;
    uint32_t endpoint_attempt_count;
    const coakka_v2_message_failure_t *failure;
    const coakka_v2_message_property_t *failure_details;
    size_t failure_detail_count;
} coakka_v2_deadletter_value_t;

typedef struct coakka_v2_message_value_owner_t coakka_v2_message_value_owner_t;

/** Encodes values, without runtime admission or routing. Inputs and output
 * objects must be valid and non-overlapping. Root output overlap is rejected
 * without writes; otherwise valid required output slots
 * reset before fallible work. Success returns independent client bytes, released
 * with client_bytes_release. Invalid representation/UTF-8/boolean/limits returns
 * INVALID_ARG; allocation failure NOMEM; unexpected encoding failure IO. No
 * partial bytes or alternate-codec retry. */
coakka_v2_status_t coakka_v2_client_encode_message_value(
    const coakka_v2_message_value_t *value, uint8_t **out_bytes, size_t *out_size);

/** Decodes a complete bounded message (empty is a zero value). Input, owner
 * slot and view must not overlap; overlapping roots reject without writes.
 * Required owner
 * output resets before fallible work; out_value must advertise its exact full
 * v1 size and is preserved on failure. Success transfers one lease and complete
 * immutable view. Input is not retained. A lease is independent of runtime/
 * ticket/input lifetime; serialize release against every reader. Module lifetime
 * must outlive release. No implicit retain or hidden registry is provided.
 * Invalid spans/sizes/limits return INVALID_ARG; malformed format IO; recoverable
 * allocation failure NOMEM. Parse depth is bounded to16. Packed metadata (owner,
 * tables/text, excluding payload) is at most MAX_METADATA_BYTES; frame ceiling
 * is MAX_FRAME_BYTES. Temporary parser/allocator overhead is separate. */
coakka_v2_status_t coakka_v2_client_decode_message_value(
    const uint8_t *bytes, size_t size, coakka_v2_message_value_owner_t **out_owner,
    coakka_v2_message_value_t *out_value);

/** Same lease/reset/bounds law for a terminal delivery outcome. Absent original
 * or native failure stays NULL; unknown numeric reasons stay numeric. Core
 * validates/interprets bounded failure details; hosts must not reconstruct a
 * cause from error text/version strings. out_value requires its full v1 size. */
coakka_v2_status_t coakka_v2_client_decode_deadletter_value(
    const uint8_t *bytes, size_t size, coakka_v2_message_value_owner_t **out_owner,
    coakka_v2_deadletter_value_t *out_value);

/** Consumes the exclusive packed owner; NULL is harmless. */
void coakka_v2_message_value_release(coakka_v2_message_value_owner_t *owner);

#ifdef __cplusplus
}
#endif
#endif
