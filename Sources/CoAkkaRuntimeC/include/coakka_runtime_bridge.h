#ifndef COAKKA_RUNTIME_BRIDGE_H
#define COAKKA_RUNTIME_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum {
    COAKKA_SWIFT_OK = 0,
    COAKKA_SWIFT_ERR_LOAD = -100,
    COAKKA_SWIFT_ERR_SYMBOL = -101
};

enum {
    COAKKA_SWIFT_STATUS_OK = 0,
    COAKKA_SWIFT_STATUS_INVALID_ARG = -1,
    COAKKA_SWIFT_STATUS_NOMEM = -2,
    COAKKA_SWIFT_STATUS_BAD_STATE = -3,
    COAKKA_SWIFT_STATUS_STALE_GENERATION = -4,
    COAKKA_SWIFT_STATUS_IO = -5,
    COAKKA_SWIFT_STATUS_WOULD_BLOCK = -6,
    COAKKA_SWIFT_STATUS_CLOSED = -7
};

enum {
    COAKKA_SWIFT_STATE_CREATED = 0,
    COAKKA_SWIFT_STATE_STARTED = 1,
    COAKKA_SWIFT_STATE_STOPPED = 2
};

enum {
    COAKKA_SWIFT_HOST_ENABLE_MONITOR = 1u << 0,
    COAKKA_SWIFT_HOST_SEPARATE_DELIVERED_REQUEST_LANE = 1u << 1
};

enum {
    COAKKA_SWIFT_ENDPOINT_LOCAL = 1u << 0
};

enum {
    COAKKA_SWIFT_ROUTE_SINGLE_OWNER = 1
};

enum {
    COAKKA_SWIFT_CLIENT_RESULT_RESPONSE = 1,
    COAKKA_SWIFT_CLIENT_RESULT_DEADLETTER = 2
};

enum {
    COAKKA_SWIFT_DELIVERY_ROUTER_DEFAULT = 1,
    COAKKA_SWIFT_DELIVERY_REQUIRE_LOCAL = 3
};

typedef struct coakka_swift_runtime_library_t coakka_swift_runtime_library_t;
typedef struct coakka_swift_runtime_t coakka_swift_runtime_t;
typedef struct coakka_swift_ask_client_t coakka_swift_ask_client_t;
typedef struct coakka_swift_ask_ticket_t coakka_swift_ask_ticket_t;
typedef struct coakka_swift_frame_reader_t coakka_swift_frame_reader_t;

typedef struct coakka_swift_host_handles_t {
    size_t struct_size;
    uint32_t flags;
    int request_write_fd;
    int response_read_fd;
    int deadletter_read_fd;
    int control_write_fd;
    int monitor_read_fd;
    int delivered_request_read_fd;
} coakka_swift_host_handles_t;

typedef struct coakka_swift_runtime_info_t {
    size_t struct_size;
    uint32_t abi_version;
    uint32_t feature_flags;
    const char *runtime_version;
    const char *git_commit;
    const char *backend;
} coakka_swift_runtime_info_t;

typedef struct coakka_swift_runtime_config_view_t {
    size_t struct_size;
    const char *system_name;
    const char *node_id;
    int strict_no_drop;
    int queue_capacity;
    int runtime_state;
    uint32_t snapshot_present;
    uint64_t applied_generation;
    size_t route_count;
} coakka_swift_runtime_config_view_t;

typedef struct coakka_swift_runtime_health_t {
    size_t struct_size;
    int runtime_state;
    uint32_t flags;
    uint64_t applied_generation;
} coakka_swift_runtime_health_t;

typedef struct coakka_swift_runtime_stats_t {
    size_t struct_size;
    uint64_t applied_generation;
    size_t route_count;
    int runtime_state;
    size_t ingress_queue_capacity;
    size_t ingress_queue_depth;
    size_t ingress_queue_high_watermark;
    uint64_t queue_rejected_count;
    uint64_t route_miss_count;
    uint64_t deadletter_count;
    uint64_t delivery_failed_count;
} coakka_swift_runtime_stats_t;

typedef struct coakka_swift_endpoint_spec_t {
    const char *host;
    uint16_t port;
    uint32_t weight;
    uint32_t flags;
} coakka_swift_endpoint_spec_t;

typedef struct coakka_swift_route_spec_t {
    const char *target;
    uint32_t strategy;
    const char *route_key_hint;
    uint32_t flags;
    const coakka_swift_endpoint_spec_t *endpoints;
    size_t endpoint_count;
} coakka_swift_route_spec_t;

typedef struct coakka_swift_raw_request_spec_t {
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
} coakka_swift_raw_request_spec_t;

typedef struct coakka_swift_raw_reply_spec_t {
    size_t struct_size;
    const uint8_t *request_buf;
    size_t request_len;
    const char *source;
    const uint8_t *payload;
    size_t payload_len;
} coakka_swift_raw_reply_spec_t;

int32_t coakka_swift_runtime_library_open(const char *path,
                                          coakka_swift_runtime_library_t **out_library,
                                          char *error_buf,
                                          size_t error_buf_len);
void coakka_swift_runtime_library_close(coakka_swift_runtime_library_t *library);

uint32_t coakka_swift_runtime_get_abi_version(coakka_swift_runtime_library_t *library);
int32_t coakka_swift_runtime_get_info(coakka_swift_runtime_library_t *library,
                                      coakka_swift_runtime_info_t *out_info);

coakka_swift_runtime_t *coakka_swift_runtime_create(coakka_swift_runtime_library_t *library,
                                                    const char *system_name,
                                                    const char *node_id,
                                                    int strict_no_drop,
                                                    int queue_capacity);
void coakka_swift_runtime_destroy(coakka_swift_runtime_library_t *library,
                                  coakka_swift_runtime_t *runtime);
int32_t coakka_swift_runtime_get_host_handles(coakka_swift_runtime_library_t *library,
                                              coakka_swift_runtime_t *runtime,
                                              uint32_t flags,
                                              coakka_swift_host_handles_t *out_handles);
int32_t coakka_swift_runtime_start(coakka_swift_runtime_library_t *library,
                                   coakka_swift_runtime_t *runtime);
int32_t coakka_swift_runtime_stop(coakka_swift_runtime_library_t *library,
                                  coakka_swift_runtime_t *runtime);
int32_t coakka_swift_runtime_apply_snapshot(coakka_swift_runtime_library_t *library,
                                            coakka_swift_runtime_t *runtime,
                                            uint64_t generation,
                                            const coakka_swift_route_spec_t *routes,
                                            size_t route_count);
int32_t coakka_swift_runtime_submit_envelope(coakka_swift_runtime_library_t *library,
                                             coakka_swift_runtime_t *runtime,
                                             const uint8_t *buf,
                                             size_t len);
int32_t coakka_swift_runtime_get_config(coakka_swift_runtime_library_t *library,
                                        coakka_swift_runtime_t *runtime,
                                        coakka_swift_runtime_config_view_t *out_config);
int32_t coakka_swift_runtime_get_health(coakka_swift_runtime_library_t *library,
                                        coakka_swift_runtime_t *runtime,
                                        coakka_swift_runtime_health_t *out_health);
int32_t coakka_swift_runtime_get_stats(coakka_swift_runtime_library_t *library,
                                       coakka_swift_runtime_t *runtime,
                                       coakka_swift_runtime_stats_t *out_stats);

coakka_swift_ask_client_t *coakka_swift_ask_client_create(coakka_swift_runtime_library_t *library,
                                                          coakka_swift_runtime_t *runtime,
                                                          const coakka_swift_host_handles_t *handles);
void coakka_swift_ask_client_destroy(coakka_swift_runtime_library_t *library,
                                     coakka_swift_ask_client_t *client);
int32_t coakka_swift_ask_client_begin(coakka_swift_runtime_library_t *library,
                                      coakka_swift_ask_client_t *client,
                                      const uint8_t *request_buf,
                                      size_t request_len,
                                      coakka_swift_ask_ticket_t **out_ticket);
int32_t coakka_swift_ask_ticket_await(coakka_swift_runtime_library_t *library,
                                      coakka_swift_ask_ticket_t *ticket,
                                      uint32_t timeout_ms,
                                      uint32_t *out_result_kind,
                                      uint8_t **out_buf,
                                      size_t *out_len);
const char *coakka_swift_ask_ticket_message_id(coakka_swift_runtime_library_t *library,
                                               const coakka_swift_ask_ticket_t *ticket);
void coakka_swift_ask_ticket_destroy(coakka_swift_runtime_library_t *library,
                                     coakka_swift_ask_ticket_t *ticket);

int32_t coakka_swift_build_raw_request(coakka_swift_runtime_library_t *library,
                                       const coakka_swift_raw_request_spec_t *spec,
                                       uint8_t **out_buf,
                                       size_t *out_len);
int32_t coakka_swift_build_raw_reply(coakka_swift_runtime_library_t *library,
                                     const coakka_swift_raw_reply_spec_t *spec,
                                     uint8_t **out_buf,
                                     size_t *out_len);
void coakka_swift_client_bytes_release(coakka_swift_runtime_library_t *library,
                                       uint8_t *buf);

coakka_swift_frame_reader_t *coakka_swift_frame_reader_create(coakka_swift_runtime_library_t *library,
                                                              int fd,
                                                              size_t max_frame_size);
void coakka_swift_frame_reader_destroy(coakka_swift_runtime_library_t *library,
                                       coakka_swift_frame_reader_t *reader);
int32_t coakka_swift_frame_read_try(coakka_swift_runtime_library_t *library,
                                    coakka_swift_frame_reader_t *reader,
                                    uint8_t **out_buf,
                                    size_t *out_len);
void coakka_swift_frame_release(coakka_swift_runtime_library_t *library,
                                uint8_t *buf);

#ifdef __cplusplus
}
#endif

#endif
