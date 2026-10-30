#include "coakka_runtime_bridge.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)
#ifndef NOMINMAX
#define NOMINMAX 1
#endif
#include <windows.h>
#else
#include <dlfcn.h>
#endif

/* Native call types are the Core SDK types, not layout mirrors. */
typedef coakka_v2_runtime_t native_runtime_t;
typedef coakka_v2_ask_client_t native_ask_client_t;
typedef coakka_v2_ask_ticket_t native_ask_ticket_t;
typedef coakka_v2_runtime_config_t native_runtime_config_t;
typedef coakka_v2_network_options_t native_network_options_t;
typedef coakka_v2_runtime_info_t native_runtime_info_t;
typedef coakka_v2_runtime_config_view_t native_runtime_config_view_t;
typedef coakka_v2_route_t native_route_t;
typedef coakka_v2_control_snapshot_t native_control_snapshot_t;

typedef uint32_t (*get_abi_version_fn)(void);
typedef coakka_v2_status_t (*get_info_fn)(native_runtime_info_t *);
typedef native_runtime_t *(*runtime_create_fn)(const native_runtime_config_t *);
typedef void (*runtime_destroy_fn)(native_runtime_t *);
typedef coakka_v2_status_t (*apply_network_options_fn)(native_runtime_t *, const native_network_options_t *);
typedef coakka_v2_status_t (*get_host_handles_fn)(native_runtime_t *, coakka_swift_host_handles_t *);
typedef coakka_v2_status_t (*runtime_start_fn)(native_runtime_t *);
typedef coakka_v2_status_t (*runtime_stop_fn)(native_runtime_t *);
typedef coakka_v2_status_t (*apply_snapshot_fn)(native_runtime_t *, const native_control_snapshot_t *);
typedef coakka_v2_status_t (*submit_envelope_fn)(native_runtime_t *, const uint8_t *, size_t);
typedef coakka_v2_status_t (*get_config_fn)(native_runtime_t *, native_runtime_config_view_t *);
typedef coakka_v2_status_t (*get_health_fn)(native_runtime_t *, coakka_swift_runtime_health_t *);
typedef coakka_v2_status_t (*get_stats_fn)(native_runtime_t *, coakka_swift_runtime_stats_t *);
typedef coakka_v2_status_t (*get_capabilities_fn)(coakka_swift_runtime_capabilities_t *);
typedef coakka_v2_status_t (*apply_tcp_connection_options_fn)(
    native_runtime_t *,
    const coakka_swift_tcp_connection_options_t *,
    coakka_swift_tcp_connection_apply_result_t *);
typedef coakka_v2_status_t (*get_tcp_connection_config_fn)(native_runtime_t *,
                                                coakka_swift_tcp_connection_config_t *);
typedef coakka_v2_status_t (*apply_tcp_security_options_fn)(
    native_runtime_t *,
    const coakka_swift_tcp_security_options_t *,
    coakka_swift_tcp_security_apply_result_t *);
typedef coakka_v2_status_t (*get_tcp_security_info_fn)(native_runtime_t *,
                                            coakka_swift_tcp_security_info_t *);
typedef const char *(*core_reason_name_fn)(uint32_t);
typedef native_ask_client_t *(*ask_client_create_fn)(native_runtime_t *, const coakka_swift_host_handles_t *);
typedef void (*ask_client_destroy_fn)(native_ask_client_t *);
typedef coakka_v2_status_t (*ask_client_begin_fn)(native_ask_client_t *, const uint8_t *, size_t, native_ask_ticket_t **);
typedef coakka_v2_status_t (*ask_ticket_await_fn)(native_ask_ticket_t *, uint32_t, uint32_t *, uint8_t **, size_t *);
typedef const char *(*ask_ticket_message_id_fn)(const native_ask_ticket_t *);
typedef void (*ask_ticket_destroy_fn)(native_ask_ticket_t *);
typedef coakka_v2_status_t (*build_raw_request_fn)(const coakka_swift_raw_request_spec_t *, uint8_t **, size_t *);
typedef coakka_v2_status_t (*build_raw_reply_fn)(const coakka_swift_raw_reply_spec_t *, uint8_t **, size_t *);
typedef void (*client_bytes_release_fn)(uint8_t *);

typedef struct runtime_library_t {
coakka_v2_status_t (*create_native)(const native_runtime_config_t *, const coakka_swift_startup_options_t *, native_runtime_t **);
coakka_v2_status_t (*get_startup)(native_runtime_t *, coakka_swift_startup_config_t *);
coakka_v2_status_t (*get_delivery)(native_runtime_t *, coakka_swift_delivery_config_t *);
void (*close_handles)(coakka_swift_host_handles_t *);
coakka_v2_status_t (*reader_create)(native_runtime_t *, const coakka_swift_host_handles_t *, coakka_swift_request_reader_t **);
coakka_v2_status_t (*reader_read)(coakka_swift_request_reader_t *, uint32_t, coakka_swift_owned_frame_t **);
const uint8_t * (*owned_data)(const coakka_swift_owned_frame_t *);
size_t (*owned_size)(const coakka_swift_owned_frame_t *);
void (*owned_release)(coakka_swift_owned_frame_t *);
void (*reader_destroy)(coakka_swift_request_reader_t *);
void (*ticket_cancel)(native_ask_ticket_t *);
coakka_v2_status_t (*copy_payload)(const uint8_t *, size_t, uint32_t, uint8_t **, size_t *);
coakka_v2_status_t (*copy_dispatch)(const uint8_t *, size_t, uint8_t **, size_t *, uint8_t **, size_t *, uint32_t *);
    void *handle;
    get_abi_version_fn get_abi_version;
    get_info_fn get_info;
    runtime_create_fn runtime_create;
    runtime_destroy_fn runtime_destroy;
    apply_network_options_fn apply_network_options;
    get_host_handles_fn get_host_handles;
    runtime_start_fn runtime_start;
    runtime_stop_fn runtime_stop;
    apply_snapshot_fn apply_snapshot;
    submit_envelope_fn submit_envelope;
    get_config_fn get_config;
    get_health_fn get_health;
    get_stats_fn get_stats;
    get_capabilities_fn get_capabilities;
    apply_tcp_connection_options_fn apply_tcp_connection_options;
    get_tcp_connection_config_fn get_tcp_connection_config;
    apply_tcp_security_options_fn apply_tcp_security_options;
    get_tcp_security_info_fn get_tcp_security_info;
    core_reason_name_fn transport_apply_reason_name;
    core_reason_name_fn deadletter_reason_name;
    ask_client_create_fn ask_client_create;
    ask_client_destroy_fn ask_client_destroy;
    ask_client_begin_fn ask_client_begin;
    ask_ticket_await_fn ask_ticket_await;
    ask_ticket_message_id_fn ask_ticket_message_id;
    ask_ticket_destroy_fn ask_ticket_destroy;
    build_raw_request_fn build_raw_request;
    build_raw_reply_fn build_raw_reply;
    client_bytes_release_fn client_bytes_release;
} runtime_library_t;

static runtime_library_t *as_library(coakka_swift_runtime_library_t *library) {
    return (runtime_library_t *)library;
}

_Static_assert(sizeof(coakka_swift_startup_options_t) == 40, "startup options ABI drift");
_Static_assert(sizeof(coakka_swift_startup_config_t) == 176, "startup config ABI drift");
_Static_assert(sizeof(coakka_swift_delivery_config_t) == 40, "delivery config ABI drift");

int32_t coakka_swift_runtime_create_native(coakka_swift_runtime_library_t *library,
    const char *system, const char *node, int strict, int capacity,
    const coakka_swift_startup_options_t *options, coakka_swift_runtime_t **out) {
    runtime_library_t *lib = as_library(library);
    native_runtime_config_t config = {system, node, strict, capacity};
    if (out != NULL) *out = NULL;
    return lib == NULL || out == NULL ? COAKKA_SWIFT_STATUS_INVALID_ARG :
        lib->create_native(&config, options, (native_runtime_t **)out);
}
int32_t coakka_swift_runtime_get_startup_config(coakka_swift_runtime_library_t *library,
    coakka_swift_runtime_t *runtime, coakka_swift_startup_config_t *out) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL ? COAKKA_SWIFT_STATUS_INVALID_ARG : lib->get_startup((native_runtime_t *)runtime, out);
}
int32_t coakka_swift_runtime_get_delivery_config(coakka_swift_runtime_library_t *library,
    coakka_swift_runtime_t *runtime, coakka_swift_delivery_config_t *out) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL ? COAKKA_SWIFT_STATUS_INVALID_ARG : lib->get_delivery((native_runtime_t *)runtime, out);
}
int32_t coakka_swift_runtime_request_reader_create(coakka_swift_runtime_library_t *library,
    coakka_swift_runtime_t *runtime, const coakka_swift_host_handles_t *handles,
    coakka_swift_request_reader_t **out) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL ? COAKKA_SWIFT_STATUS_INVALID_ARG : lib->reader_create((native_runtime_t *)runtime, handles, out);
}
int32_t coakka_swift_request_reader_read(coakka_swift_runtime_library_t *library,
    coakka_swift_request_reader_t *reader, uint32_t timeout, coakka_swift_owned_frame_t **out) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL ? COAKKA_SWIFT_STATUS_INVALID_ARG : lib->reader_read(reader, timeout, out);
}
const uint8_t *coakka_swift_owned_frame_data(coakka_swift_runtime_library_t *library,
    const coakka_swift_owned_frame_t *frame) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL ? NULL : lib->owned_data(frame);
}
size_t coakka_swift_owned_frame_size(coakka_swift_runtime_library_t *library,
    const coakka_swift_owned_frame_t *frame) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL ? 0 : lib->owned_size(frame);
}
void coakka_swift_owned_frame_release(coakka_swift_runtime_library_t *library, coakka_swift_owned_frame_t *frame) {
    runtime_library_t *lib = as_library(library);
    if (lib != NULL) lib->owned_release(frame);
}
void coakka_swift_request_reader_destroy(coakka_swift_runtime_library_t *library, coakka_swift_request_reader_t *reader) {
    runtime_library_t *lib = as_library(library);
    if (lib != NULL) lib->reader_destroy(reader);
}
void coakka_swift_ask_ticket_cancel(coakka_swift_runtime_library_t *library, coakka_swift_ask_ticket_t *ticket) {
    runtime_library_t *lib = as_library(library);
    if (lib != NULL) lib->ticket_cancel((native_ask_ticket_t *)ticket);
}
int32_t coakka_swift_copy_envelope_payload(coakka_swift_runtime_library_t *library, const uint8_t *frame, size_t size,
    uint32_t kind, uint8_t **out, size_t *length) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL ? COAKKA_SWIFT_STATUS_INVALID_ARG : lib->copy_payload(frame, size, kind, out, length);
}
int32_t coakka_swift_copy_request_dispatch(coakka_swift_runtime_library_t *library, const uint8_t *frame, size_t size,
    uint8_t **target, size_t *target_size, uint8_t **payload, size_t *payload_size, uint32_t *one_way) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL ? COAKKA_SWIFT_STATUS_INVALID_ARG : lib->copy_dispatch(frame, size, target, target_size, payload, payload_size, one_way);
}

static void *platform_library_open(const char *path) {
#if defined(_WIN32)
    int wide_len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path, -1, NULL, 0);
    if (wide_len <= 0) {
        return NULL;
    }
    wchar_t *wide_path = (wchar_t *)calloc((size_t)wide_len, sizeof(wchar_t));
    if (wide_path == NULL) {
        return NULL;
    }
    if (MultiByteToWideChar(CP_UTF8,
                            MB_ERR_INVALID_CHARS,
                            path,
                            -1,
                            wide_path,
                            wide_len) <= 0) {
        free(wide_path);
        return NULL;
    }
    HMODULE handle = LoadLibraryW(wide_path);
    free(wide_path);
    return (void *)handle;
#else
    return dlopen(path, RTLD_NOW | RTLD_LOCAL);
#endif
}

static void platform_library_close(void *handle) {
    if (handle == NULL) {
        return;
    }
#if defined(_WIN32)
    FreeLibrary((HMODULE)handle);
#else
    dlclose(handle);
#endif
}

static void *platform_library_symbol(void *handle, const char *name) {
#if defined(_WIN32)
    return (void *)GetProcAddress((HMODULE)handle, name);
#else
    dlerror();
    return dlsym(handle, name);
#endif
}

static const char *platform_library_error(void) {
#if defined(_WIN32)
    return "Windows loader rejected the runtime library or symbol";
#else
    const char *error = dlerror();
    return error == NULL ? "unknown loader error" : error;
#endif
}

static void set_error(char *buf, size_t len, const char *prefix, const char *value) {
    if (buf == NULL || len == 0) {
        return;
    }
    snprintf(buf, len, "%s%s", prefix == NULL ? "" : prefix, value == NULL ? "" : value);
}

static int32_t load_symbol(runtime_library_t *library, void **out_symbol, const char *name, char *error_buf, size_t error_buf_len) {
    void *symbol = platform_library_symbol(library->handle, name);
    if (symbol == NULL) {
        set_error(error_buf, error_buf_len, "missing symbol: ", name);
        return COAKKA_SWIFT_ERR_SYMBOL;
    }
    *out_symbol = symbol;
    return COAKKA_SWIFT_OK;
}

#define LOAD_SYMBOL(field, type, name) \
    do { \
        _Static_assert(_Generic(&(name), type: 1, default: 0), "Core function type drift"); \
        _Static_assert(_Generic(library->field, type: 1, default: 0), "Core slot type drift"); \
        void *symbol = NULL; \
        int32_t status = load_symbol(library, &symbol, #name, error_buf, error_buf_len); \
        if (status != COAKKA_SWIFT_OK) { \
            platform_library_close(library->handle); \
            free(library); \
            return status; \
        } \
        _Static_assert(sizeof(library->field) == sizeof(symbol), "loader pointer width"); \
        memcpy(&library->field, &symbol, sizeof(library->field)); \
    } while (0)

int32_t coakka_swift_runtime_library_open(const char *path,
                                          coakka_swift_runtime_library_t **out_library,
                                          char *error_buf,
                                          size_t error_buf_len) {
    if (path == NULL || out_library == NULL) {
        set_error(error_buf, error_buf_len, "invalid runtime library path", "");
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    *out_library = NULL;
    runtime_library_t *library = (runtime_library_t *)calloc(1, sizeof(runtime_library_t));
    if (library == NULL) {
        set_error(error_buf, error_buf_len, "out of memory", "");
        return COAKKA_SWIFT_STATUS_NOMEM;
    }
    library->handle = platform_library_open(path);
    if (library->handle == NULL) {
        set_error(error_buf, error_buf_len, "failed to open runtime library: ", platform_library_error());
        free(library);
        return COAKKA_SWIFT_ERR_LOAD;
    }

    LOAD_SYMBOL(get_abi_version, get_abi_version_fn, coakka_v2_runtime_get_abi_version);
LOAD_SYMBOL(create_native, coakka_v2_status_t (*)(const native_runtime_config_t *, const coakka_swift_startup_options_t *, native_runtime_t **), coakka_v2_runtime_create_native);
LOAD_SYMBOL(get_startup, coakka_v2_status_t (*)(native_runtime_t *, coakka_swift_startup_config_t *), coakka_v2_runtime_get_startup_config);
LOAD_SYMBOL(get_delivery, coakka_v2_status_t (*)(native_runtime_t *, coakka_swift_delivery_config_t *), coakka_v2_runtime_get_delivery_config);
LOAD_SYMBOL(close_handles, void (*)(coakka_swift_host_handles_t *), coakka_v2_host_handles_close);
LOAD_SYMBOL(reader_create, coakka_v2_status_t (*)(native_runtime_t *, const coakka_swift_host_handles_t *, coakka_swift_request_reader_t **), coakka_v2_runtime_request_reader_create);
LOAD_SYMBOL(reader_read, coakka_v2_status_t (*)(coakka_swift_request_reader_t *, uint32_t, coakka_swift_owned_frame_t **), coakka_v2_request_reader_read);
LOAD_SYMBOL(owned_data, const uint8_t * (*)(const coakka_swift_owned_frame_t *), coakka_v2_owned_frame_data);
LOAD_SYMBOL(owned_size, size_t (*)(const coakka_swift_owned_frame_t *), coakka_v2_owned_frame_size);
LOAD_SYMBOL(owned_release, void (*)(coakka_swift_owned_frame_t *), coakka_v2_owned_frame_release);
LOAD_SYMBOL(reader_destroy, void (*)(coakka_swift_request_reader_t *), coakka_v2_request_reader_destroy);
LOAD_SYMBOL(ticket_cancel, void (*)(native_ask_ticket_t *), coakka_v2_ask_ticket_cancel);
LOAD_SYMBOL(copy_payload, coakka_v2_status_t (*)(const uint8_t *, size_t, uint32_t, uint8_t **, size_t *), coakka_v2_client_copy_envelope_payload);
LOAD_SYMBOL(copy_dispatch, coakka_v2_status_t (*)(const uint8_t *, size_t, uint8_t **, size_t *, uint8_t **, size_t *, uint32_t *), coakka_v2_client_copy_request_dispatch);
    LOAD_SYMBOL(get_info, get_info_fn, coakka_v2_runtime_get_info);
    LOAD_SYMBOL(runtime_create, runtime_create_fn, coakka_v2_runtime_create);
    LOAD_SYMBOL(runtime_destroy, runtime_destroy_fn, coakka_v2_runtime_destroy);
    LOAD_SYMBOL(apply_network_options,
                apply_network_options_fn,
                coakka_v2_runtime_apply_network_options);
    LOAD_SYMBOL(get_host_handles, get_host_handles_fn, coakka_v2_runtime_get_host_handles);
    LOAD_SYMBOL(runtime_start, runtime_start_fn, coakka_v2_runtime_start);
    LOAD_SYMBOL(runtime_stop, runtime_stop_fn, coakka_v2_runtime_stop);
    LOAD_SYMBOL(apply_snapshot, apply_snapshot_fn, coakka_v2_runtime_apply_control_snapshot);
    LOAD_SYMBOL(submit_envelope, submit_envelope_fn, coakka_v2_runtime_submit_envelope);
    LOAD_SYMBOL(get_config, get_config_fn, coakka_v2_runtime_get_config);
    LOAD_SYMBOL(get_health, get_health_fn, coakka_v2_runtime_get_health);
    LOAD_SYMBOL(get_stats, get_stats_fn, coakka_v2_runtime_get_stats);
    LOAD_SYMBOL(get_capabilities, get_capabilities_fn, coakka_v2_runtime_get_capabilities);
    LOAD_SYMBOL(apply_tcp_connection_options,
                apply_tcp_connection_options_fn,
                coakka_v2_runtime_apply_tcp_connection_options_ex);
    LOAD_SYMBOL(get_tcp_connection_config,
                get_tcp_connection_config_fn,
                coakka_v2_runtime_get_tcp_connection_config);
    LOAD_SYMBOL(apply_tcp_security_options,
                apply_tcp_security_options_fn,
                coakka_v2_runtime_apply_tcp_security_options_ex);
    LOAD_SYMBOL(get_tcp_security_info,
                get_tcp_security_info_fn,
                coakka_v2_runtime_get_tcp_security_info);
    LOAD_SYMBOL(transport_apply_reason_name,
                core_reason_name_fn,
                coakka_v2_transport_apply_reason_name);
    LOAD_SYMBOL(deadletter_reason_name, core_reason_name_fn, coakka_v2_deadletter_reason_name);
    LOAD_SYMBOL(ask_client_create, ask_client_create_fn, coakka_v2_ask_client_create);
    LOAD_SYMBOL(ask_client_destroy, ask_client_destroy_fn, coakka_v2_ask_client_destroy);
    LOAD_SYMBOL(ask_client_begin, ask_client_begin_fn, coakka_v2_ask_client_begin);
    LOAD_SYMBOL(ask_ticket_await, ask_ticket_await_fn, coakka_v2_ask_ticket_await);
    LOAD_SYMBOL(ask_ticket_message_id, ask_ticket_message_id_fn, coakka_v2_ask_ticket_message_id);
    LOAD_SYMBOL(ask_ticket_destroy, ask_ticket_destroy_fn, coakka_v2_ask_ticket_destroy);
    LOAD_SYMBOL(build_raw_request, build_raw_request_fn, coakka_v2_client_build_raw_request);
    LOAD_SYMBOL(build_raw_reply, build_raw_reply_fn, coakka_v2_client_build_raw_reply);
    LOAD_SYMBOL(client_bytes_release, client_bytes_release_fn, coakka_v2_client_bytes_release);

    *out_library = (coakka_swift_runtime_library_t *)library;
    return COAKKA_SWIFT_OK;
}

void coakka_swift_runtime_library_close(coakka_swift_runtime_library_t *library) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL) {
        return;
    }
    if (lib->handle != NULL) {
        platform_library_close(lib->handle);
    }
    free(lib);
}

/* POSIX/Win64 loaders return a flat symbol pointer. Copy its representation
 * only after Core's declaration and this exact function type agree. No symbol
 * lookup or loader error is interpreted as a Core capability fact. */
#define CHECKED_CORE_LOADER(type, name) \
    _Static_assert(_Generic(&(name), type: 1, default: 0), "Core function type drift"); \
    static type load_##name(runtime_library_t *library) { \
        void *symbol = platform_library_symbol(library->handle, #name); \
        type function = NULL; \
        _Static_assert(sizeof(function) == sizeof(symbol), "loader pointer width"); \
        memcpy(&function, &symbol, sizeof(function)); \
        return function; \
    }

typedef coakka_v2_file_receive_spec_t swift_native_file_receive_t;
typedef coakka_v2_file_send_spec_t swift_native_file_send_t;
typedef coakka_v2_status_t (*swift_file_create_fn)(const coakka_swift_file_lane_config_t *, coakka_swift_file_lane_t **);
typedef coakka_v2_status_t (*swift_file_create_owned_fn)(const coakka_swift_file_lane_owned_config_t *, coakka_swift_file_lane_t **);
typedef void (*swift_file_destroy_fn)(coakka_swift_file_lane_t *);
typedef coakka_v2_status_t (*swift_file_simple_fn)(coakka_swift_file_lane_t *);
typedef coakka_v2_status_t (*swift_file_port_fn)(coakka_swift_file_lane_t *, uint16_t *);
typedef coakka_v2_status_t (*swift_file_prepare_fn)(coakka_swift_file_lane_t *, const swift_native_file_receive_t *);
typedef coakka_v2_status_t (*swift_file_prepare_grant_fn)(coakka_swift_file_lane_t *, const swift_native_file_receive_t *, coakka_swift_file_receive_grant_t *);
typedef coakka_v2_status_t (*swift_file_submit_fn)(coakka_swift_file_lane_t *, const swift_native_file_send_t *);
typedef coakka_v2_status_t (*swift_file_get_fn)(coakka_swift_file_lane_t *, const char *, uint32_t, coakka_swift_file_transfer_snapshot_t *);
typedef coakka_v2_status_t (*swift_file_wait_fn)(coakka_swift_file_lane_t *, const char *, uint32_t, uint64_t, uint32_t, coakka_swift_file_transfer_snapshot_t *);
typedef coakka_v2_status_t (*swift_file_control_fn)(coakka_swift_file_lane_t *, const char *, uint32_t);
typedef coakka_v2_status_t (*swift_file_stats_fn)(coakka_swift_file_lane_t *, coakka_swift_file_lane_stats_t *);
typedef coakka_v2_status_t (*swift_file_sha_fn)(const char *, uint8_t[32], uint64_t *);

CHECKED_CORE_LOADER(swift_file_control_fn, coakka_v2_file_lane_cancel_transfer)
CHECKED_CORE_LOADER(swift_file_control_fn, coakka_v2_file_lane_forget_transfer)
CHECKED_CORE_LOADER(swift_file_create_fn, coakka_v2_file_lane_create_ex)
CHECKED_CORE_LOADER(swift_file_create_owned_fn, coakka_v2_file_lane_create_owned_ex)
CHECKED_CORE_LOADER(swift_file_destroy_fn, coakka_v2_file_lane_destroy)
CHECKED_CORE_LOADER(swift_file_get_fn, coakka_v2_file_lane_get_transfer)
CHECKED_CORE_LOADER(swift_file_port_fn, coakka_v2_file_lane_get_bound_port)
CHECKED_CORE_LOADER(swift_file_prepare_fn, coakka_v2_file_lane_prepare_receive)
CHECKED_CORE_LOADER(swift_file_prepare_grant_fn, coakka_v2_file_lane_prepare_receive_grant)
CHECKED_CORE_LOADER(swift_file_sha_fn, coakka_v2_file_sha256_path)
CHECKED_CORE_LOADER(swift_file_simple_fn, coakka_v2_file_lane_start)
CHECKED_CORE_LOADER(swift_file_simple_fn, coakka_v2_file_lane_stop)
CHECKED_CORE_LOADER(swift_file_stats_fn, coakka_v2_file_lane_get_stats)
CHECKED_CORE_LOADER(swift_file_submit_fn, coakka_v2_file_lane_submit_send)
CHECKED_CORE_LOADER(swift_file_wait_fn, coakka_v2_file_lane_wait_transfer)

#define SWIFT_FILE_SYMBOL(lib, type, name) load_##name(lib)
/* A successful Core query yields a compiled feature fact. Inspection failure
 * is a status, never an invented unsupported fact or a symbol-presence probe. */
static int32_t core_feature_available(runtime_library_t *lib, uint32_t feature,
                                      uint32_t *out_available) {
    if (out_available == NULL) return COAKKA_SWIFT_STATUS_INVALID_ARG;
    *out_available = 0;
    if (lib == NULL) return COAKKA_SWIFT_STATUS_INVALID_ARG;
    if (lib->get_info == NULL) return COAKKA_SWIFT_ERR_SYMBOL;
    native_runtime_info_t info = {0};
    info.struct_size = sizeof(info);
    coakka_v2_status_t status = lib->get_info(&info);
    if (status != COAKKA_V2_OK) return status;
    *out_available = (info.feature_flags & feature) != 0;
    return COAKKA_V2_OK;
}

int32_t coakka_swift_lane_owner_grants_available(coakka_swift_runtime_library_t *library,
    uint32_t *out_available) {
    return core_feature_available(as_library(library), COAKKA_V2_RUNTIME_FEATURE_LANE_OWNER_GRANTS, out_available);
}
int32_t coakka_swift_file_lane_available(coakka_swift_runtime_library_t *library,
    uint32_t *out_available) {
    return core_feature_available(as_library(library), COAKKA_V2_RUNTIME_FEATURE_FILE_LANE, out_available);
}
int32_t coakka_swift_file_lane_create(coakka_swift_runtime_library_t *library,const coakka_swift_file_lane_config_t *config,coakka_swift_file_lane_t **out){runtime_library_t *lib=as_library(library);swift_file_create_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_create_fn,coakka_v2_file_lane_create_ex):NULL;return f?f(config,out):COAKKA_SWIFT_ERR_SYMBOL;}
int32_t coakka_swift_file_lane_create_owned(coakka_swift_runtime_library_t *library,const coakka_swift_file_lane_owned_config_t *config,coakka_swift_file_lane_t **out){runtime_library_t *lib=as_library(library);swift_file_create_owned_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_create_owned_fn,coakka_v2_file_lane_create_owned_ex):NULL;return f?f(config,out):COAKKA_SWIFT_ERR_SYMBOL;}
void coakka_swift_file_lane_destroy(coakka_swift_runtime_library_t *library,coakka_swift_file_lane_t *lane){runtime_library_t *lib=as_library(library);swift_file_destroy_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_destroy_fn,coakka_v2_file_lane_destroy):NULL;if(f)f(lane);}
int32_t coakka_swift_file_lane_start(coakka_swift_runtime_library_t *library,coakka_swift_file_lane_t *lane){runtime_library_t *lib=as_library(library);swift_file_simple_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_simple_fn,coakka_v2_file_lane_start):NULL;return f?f(lane):COAKKA_SWIFT_ERR_SYMBOL;}
int32_t coakka_swift_file_lane_stop(coakka_swift_runtime_library_t *library,coakka_swift_file_lane_t *lane){runtime_library_t *lib=as_library(library);swift_file_simple_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_simple_fn,coakka_v2_file_lane_stop):NULL;return f?f(lane):COAKKA_SWIFT_ERR_SYMBOL;}
int32_t coakka_swift_file_lane_get_bound_port(coakka_swift_runtime_library_t *library,coakka_swift_file_lane_t *lane,uint16_t*out){runtime_library_t*lib=as_library(library);swift_file_port_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_port_fn,coakka_v2_file_lane_get_bound_port):NULL;return f?f(lane,out):COAKKA_SWIFT_ERR_SYMBOL;}
int32_t coakka_swift_file_lane_prepare_receive(coakka_swift_runtime_library_t *library,coakka_swift_file_lane_t *lane,const char*id,const char*token,const char*path,uint64_t size,const uint8_t sha[32]){runtime_library_t*lib=as_library(library);swift_file_prepare_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_prepare_fn,coakka_v2_file_lane_prepare_receive):NULL;if(!f||!sha)return COAKKA_SWIFT_ERR_SYMBOL;swift_native_file_receive_t s={sizeof(s),id,token,path,size,{0}};memcpy(s.expected_sha256,sha,32);return f(lane,&s);}
int32_t coakka_swift_file_lane_prepare_receive_grant(coakka_swift_runtime_library_t *library,coakka_swift_file_lane_t *lane,const char*id,const char*token,const char*path,uint64_t size,const uint8_t sha[32],coakka_swift_file_receive_grant_t*out){runtime_library_t*lib=as_library(library);swift_file_prepare_grant_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_prepare_grant_fn,coakka_v2_file_lane_prepare_receive_grant):NULL;if(!f||!sha||!out)return COAKKA_SWIFT_ERR_SYMBOL;swift_native_file_receive_t s={sizeof(s),id,token,path,size,{0}};memcpy(s.expected_sha256,sha,32);memset(out,0,sizeof(*out));out->struct_size=sizeof(*out);return f(lane,&s,out);}
int32_t coakka_swift_file_lane_submit_send(coakka_swift_runtime_library_t *library,coakka_swift_file_lane_t *lane,const char*id,const char*token,const char*host,uint16_t port,const char*path,uint64_t size,const uint8_t sha[32],uint32_t timeout){runtime_library_t*lib=as_library(library);swift_file_submit_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_submit_fn,coakka_v2_file_lane_submit_send):NULL;if(!f||!sha)return COAKKA_SWIFT_ERR_SYMBOL;swift_native_file_send_t s={sizeof(s),id,token,host,port,path,size,{0},timeout};memcpy(s.expected_sha256,sha,32);return f(lane,&s);}
int32_t coakka_swift_file_lane_get_transfer(coakka_swift_runtime_library_t*library,coakka_swift_file_lane_t*lane,const char*id,uint32_t d,coakka_swift_file_transfer_snapshot_t*out){runtime_library_t*lib=as_library(library);swift_file_get_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_get_fn,coakka_v2_file_lane_get_transfer):NULL;if(out){memset(out,0,sizeof(*out));out->struct_size=sizeof(*out);}return f?f(lane,id,d,out):COAKKA_SWIFT_ERR_SYMBOL;}
int32_t coakka_swift_file_lane_wait_transfer(coakka_swift_runtime_library_t*library,coakka_swift_file_lane_t*lane,const char*id,uint32_t d,uint64_t seq,uint32_t ms,coakka_swift_file_transfer_snapshot_t*out){runtime_library_t*lib=as_library(library);swift_file_wait_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_wait_fn,coakka_v2_file_lane_wait_transfer):NULL;if(out){memset(out,0,sizeof(*out));out->struct_size=sizeof(*out);}return f?f(lane,id,d,seq,ms,out):COAKKA_SWIFT_ERR_SYMBOL;}
int32_t coakka_swift_file_lane_cancel(coakka_swift_runtime_library_t*l,coakka_swift_file_lane_t*lane,const char*id,uint32_t d){runtime_library_t*lib=as_library(l);swift_file_control_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_control_fn,coakka_v2_file_lane_cancel_transfer):NULL;return f?f(lane,id,d):COAKKA_SWIFT_ERR_SYMBOL;}
int32_t coakka_swift_file_lane_forget(coakka_swift_runtime_library_t*l,coakka_swift_file_lane_t*lane,const char*id,uint32_t d){runtime_library_t*lib=as_library(l);swift_file_control_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_control_fn,coakka_v2_file_lane_forget_transfer):NULL;return f?f(lane,id,d):COAKKA_SWIFT_ERR_SYMBOL;}
int32_t coakka_swift_file_lane_get_stats(coakka_swift_runtime_library_t*l,coakka_swift_file_lane_t*lane,coakka_swift_file_lane_stats_t*out){runtime_library_t*lib=as_library(l);swift_file_stats_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_stats_fn,coakka_v2_file_lane_get_stats):NULL;if(out){memset(out,0,sizeof(*out));out->struct_size=sizeof(*out);}return f?f(lane,out):COAKKA_SWIFT_ERR_SYMBOL;}
int32_t coakka_swift_file_sha256_path(coakka_swift_runtime_library_t*l,const char*path,uint8_t out[32],uint64_t*size){runtime_library_t*lib=as_library(l);swift_file_sha_fn f=lib?SWIFT_FILE_SYMBOL(lib,swift_file_sha_fn,coakka_v2_file_sha256_path):NULL;return f?f(path,out,size):COAKKA_SWIFT_ERR_SYMBOL;}

typedef coakka_v2_stream_publish_spec_t swift_native_stream_publish_t;
typedef coakka_v2_stream_subscribe_spec_t swift_native_stream_subscribe_t;
typedef coakka_v2_status_t (*swift_stream_create_fn)(const coakka_swift_stream_config_t *,
                                          coakka_swift_stream_lane_t **);
typedef coakka_v2_status_t (*swift_stream_create_owned_fn)(const coakka_swift_stream_owned_config_t *,
                                                coakka_swift_stream_lane_t **);
typedef void (*swift_stream_destroy_fn)(coakka_swift_stream_lane_t *);
typedef coakka_v2_status_t (*swift_stream_simple_fn)(coakka_swift_stream_lane_t *);
typedef coakka_v2_status_t (*swift_stream_port_fn)(coakka_swift_stream_lane_t *,
                                        uint16_t *);
typedef coakka_v2_status_t (*swift_stream_publish_fn)(
    coakka_swift_stream_lane_t *, const swift_native_stream_publish_t *);
typedef coakka_v2_status_t (*swift_stream_publish_grant_fn)(
    coakka_swift_stream_lane_t *, const swift_native_stream_publish_t *,
    coakka_swift_stream_publish_grant_t *);
typedef coakka_v2_status_t (*swift_stream_subscribe_fn)(
    coakka_swift_stream_lane_t *, const swift_native_stream_subscribe_t *);
typedef coakka_v2_status_t (*swift_stream_get_fn)(
    coakka_swift_stream_lane_t *, const char *, uint32_t,
    coakka_swift_stream_session_snapshot_t *);
typedef coakka_v2_status_t (*swift_stream_wait_fn)(
    coakka_swift_stream_lane_t *, const char *, uint32_t, uint64_t, uint32_t,
    coakka_swift_stream_session_snapshot_t *);
typedef coakka_v2_status_t (*swift_stream_pressure_fn)(
    coakka_swift_stream_lane_t *, const char *, uint32_t,
    coakka_swift_stream_pressure_snapshot_t *);
typedef coakka_v2_status_t (*swift_stream_wait_pressure_fn)(
    coakka_swift_stream_lane_t *, const char *, uint32_t, uint64_t, uint32_t,
    coakka_swift_stream_pressure_snapshot_t *);
typedef coakka_v2_status_t (*swift_stream_control_fn)(coakka_swift_stream_lane_t *,
                                           const char *, uint32_t);
typedef coakka_v2_status_t (*swift_stream_stats_fn)(coakka_swift_stream_lane_t *,
                                         coakka_swift_stream_stats_t *);

CHECKED_CORE_LOADER(swift_stream_control_fn, coakka_v2_stream_lane_cancel_session)
CHECKED_CORE_LOADER(swift_stream_control_fn, coakka_v2_stream_lane_forget_session)
CHECKED_CORE_LOADER(swift_stream_create_fn, coakka_v2_stream_lane_create_ex)
CHECKED_CORE_LOADER(swift_stream_create_owned_fn, coakka_v2_stream_lane_create_owned_ex)
CHECKED_CORE_LOADER(swift_stream_destroy_fn, coakka_v2_stream_lane_destroy)
CHECKED_CORE_LOADER(swift_stream_get_fn, coakka_v2_stream_lane_get_session)
CHECKED_CORE_LOADER(swift_stream_port_fn, coakka_v2_stream_lane_get_bound_port)
CHECKED_CORE_LOADER(swift_stream_pressure_fn, coakka_v2_stream_lane_get_pressure)
CHECKED_CORE_LOADER(swift_stream_publish_fn, coakka_v2_stream_lane_prepare_publish)
CHECKED_CORE_LOADER(swift_stream_publish_grant_fn, coakka_v2_stream_lane_prepare_publish_grant)
CHECKED_CORE_LOADER(swift_stream_simple_fn, coakka_v2_stream_lane_start)
CHECKED_CORE_LOADER(swift_stream_simple_fn, coakka_v2_stream_lane_stop)
CHECKED_CORE_LOADER(swift_stream_stats_fn, coakka_v2_stream_lane_get_stats)
CHECKED_CORE_LOADER(swift_stream_subscribe_fn, coakka_v2_stream_lane_subscribe)
CHECKED_CORE_LOADER(swift_stream_wait_fn, coakka_v2_stream_lane_wait_session)
CHECKED_CORE_LOADER(swift_stream_wait_pressure_fn, coakka_v2_stream_lane_wait_pressure)

#define SWIFT_STREAM_SYMBOL(lib, type, name) load_##name(lib)
int32_t coakka_swift_stream_available(coakka_swift_runtime_library_t *library,
    uint32_t *out_available) {
    return core_feature_available(as_library(library), COAKKA_V2_RUNTIME_FEATURE_STREAM_LANE, out_available);
}
int32_t coakka_swift_stream_create(coakka_swift_runtime_library_t *l,
                                   const coakka_swift_stream_config_t *c,
                                   coakka_swift_stream_lane_t **out) {
  runtime_library_t *lib = as_library(l);
  swift_stream_create_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_create_fn,
                                coakka_v2_stream_lane_create_ex)
          : NULL;
  return f ? f(c, out) : COAKKA_SWIFT_ERR_SYMBOL;
}
int32_t coakka_swift_stream_create_owned(coakka_swift_runtime_library_t *l,
                                         const coakka_swift_stream_owned_config_t *c,
                                         coakka_swift_stream_lane_t **out) {
  runtime_library_t *lib = as_library(l);
  swift_stream_create_owned_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_create_owned_fn,
                                coakka_v2_stream_lane_create_owned_ex)
          : NULL;
  return f ? f(c, out) : COAKKA_SWIFT_ERR_SYMBOL;
}
void coakka_swift_stream_destroy(coakka_swift_runtime_library_t *l,
                                 coakka_swift_stream_lane_t *lane) {
  runtime_library_t *lib = as_library(l);
  swift_stream_destroy_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_destroy_fn,
                                coakka_v2_stream_lane_destroy)
          : NULL;
  if (f)
    f(lane);
}
int32_t coakka_swift_stream_start(coakka_swift_runtime_library_t *l,
                                  coakka_swift_stream_lane_t *lane) {
  runtime_library_t *lib = as_library(l);
  swift_stream_simple_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_simple_fn,
                                coakka_v2_stream_lane_start)
          : NULL;
  return f ? f(lane) : COAKKA_SWIFT_ERR_SYMBOL;
}
int32_t coakka_swift_stream_stop(coakka_swift_runtime_library_t *l,
                                 coakka_swift_stream_lane_t *lane) {
  runtime_library_t *lib = as_library(l);
  swift_stream_simple_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_simple_fn,
                                coakka_v2_stream_lane_stop)
          : NULL;
  return f ? f(lane) : COAKKA_SWIFT_ERR_SYMBOL;
}
int32_t coakka_swift_stream_bound_port(coakka_swift_runtime_library_t *l,
                                       coakka_swift_stream_lane_t *lane,
                                       uint16_t *out) {
  runtime_library_t *lib = as_library(l);
  swift_stream_port_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_port_fn,
                                coakka_v2_stream_lane_get_bound_port)
          : NULL;
  return f ? f(lane, out) : COAKKA_SWIFT_ERR_SYMBOL;
}
int32_t coakka_swift_stream_prepare_publish(
    coakka_swift_runtime_library_t *l, coakka_swift_stream_lane_t *lane,
    const char *id, const char *token, uint64_t format, uint32_t max_frame,
    coakka_swift_stream_source_fn source, void *context) {
  runtime_library_t *lib = as_library(l);
  swift_stream_publish_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_publish_fn,
                                coakka_v2_stream_lane_prepare_publish)
          : NULL;
  swift_native_stream_publish_t s = {sizeof(s), id,     token,  format,
                                     max_frame, source, context};
  return f ? f(lane, &s) : COAKKA_SWIFT_ERR_SYMBOL;
}
int32_t coakka_swift_stream_prepare_publish_grant(
    coakka_swift_runtime_library_t *l, coakka_swift_stream_lane_t *lane,
    const char *id, const char *token, uint64_t format, uint32_t max_frame,
    coakka_swift_stream_source_fn source, void *context,
    coakka_swift_stream_publish_grant_t *out) {
  runtime_library_t *lib = as_library(l);
  swift_stream_publish_grant_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_publish_grant_fn,
                                coakka_v2_stream_lane_prepare_publish_grant)
          : NULL;
  if (!f || !out) return COAKKA_SWIFT_ERR_SYMBOL;
  swift_native_stream_publish_t s = {sizeof(s), id, token, format, max_frame, source, context};
  memset(out, 0, sizeof(*out));
  out->struct_size = sizeof(*out);
  return f(lane, &s, out);
}
int32_t coakka_swift_stream_subscribe(
    coakka_swift_runtime_library_t *l, coakka_swift_stream_lane_t *lane,
    const char *id, const char *token, const char *host, uint16_t port,
    uint64_t format, uint32_t max_frame, uint32_t window, uint32_t timeout,
    coakka_swift_stream_consumer_fn consumer, void *context) {
  runtime_library_t *lib = as_library(l);
  swift_stream_subscribe_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_subscribe_fn,
                                coakka_v2_stream_lane_subscribe)
          : NULL;
  swift_native_stream_subscribe_t s = {sizeof(s), id,       token,     host,
                                       port,      format,   max_frame, window,
                                       timeout,   consumer, context};
  return f ? f(lane, &s) : COAKKA_SWIFT_ERR_SYMBOL;
}
int32_t coakka_swift_stream_get_session(
    coakka_swift_runtime_library_t *l, coakka_swift_stream_lane_t *lane,
    const char *id, uint32_t d, coakka_swift_stream_session_snapshot_t *out) {
  runtime_library_t *lib = as_library(l);
  swift_stream_get_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_get_fn,
                                coakka_v2_stream_lane_get_session)
          : NULL;
  if (out) {
    memset(out, 0, sizeof(*out));
    out->struct_size = sizeof(*out);
  }
  return f ? f(lane, id, d, out) : COAKKA_SWIFT_ERR_SYMBOL;
}
int32_t coakka_swift_stream_wait_session(
    coakka_swift_runtime_library_t *l, coakka_swift_stream_lane_t *lane,
    const char *id, uint32_t d, uint64_t seq, uint32_t ms,
    coakka_swift_stream_session_snapshot_t *out) {
  runtime_library_t *lib = as_library(l);
  swift_stream_wait_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_wait_fn,
                                coakka_v2_stream_lane_wait_session)
          : NULL;
  if (out) {
    memset(out, 0, sizeof(*out));
    out->struct_size = sizeof(*out);
  }
  return f ? f(lane, id, d, seq, ms, out) : COAKKA_SWIFT_ERR_SYMBOL;
}
int32_t coakka_swift_stream_get_pressure(
    coakka_swift_runtime_library_t *l, coakka_swift_stream_lane_t *lane,
    const char *id, uint32_t d, coakka_swift_stream_pressure_snapshot_t *out) {
  runtime_library_t *lib = as_library(l);
  swift_stream_pressure_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_pressure_fn,
                                coakka_v2_stream_lane_get_pressure)
          : NULL;
  if (out) {
    memset(out, 0, sizeof(*out));
    out->struct_size = sizeof(*out);
  }
  return f ? f(lane, id, d, out) : COAKKA_SWIFT_ERR_SYMBOL;
}
int32_t coakka_swift_stream_wait_pressure(
    coakka_swift_runtime_library_t *l, coakka_swift_stream_lane_t *lane,
    const char *id, uint32_t d, uint64_t seq, uint32_t ms,
    coakka_swift_stream_pressure_snapshot_t *out) {
  runtime_library_t *lib = as_library(l);
  swift_stream_wait_pressure_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_wait_pressure_fn,
                                coakka_v2_stream_lane_wait_pressure)
          : NULL;
  if (out) {
    memset(out, 0, sizeof(*out));
    out->struct_size = sizeof(*out);
  }
  return f ? f(lane, id, d, seq, ms, out) : COAKKA_SWIFT_ERR_SYMBOL;
}
int32_t coakka_swift_stream_cancel(coakka_swift_runtime_library_t *l,
                                   coakka_swift_stream_lane_t *lane,
                                   const char *id, uint32_t d) {
  runtime_library_t *lib = as_library(l);
  swift_stream_control_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_control_fn,
                                coakka_v2_stream_lane_cancel_session)
          : NULL;
  return f ? f(lane, id, d) : COAKKA_SWIFT_ERR_SYMBOL;
}
int32_t coakka_swift_stream_forget(coakka_swift_runtime_library_t *l,
                                   coakka_swift_stream_lane_t *lane,
                                   const char *id, uint32_t d) {
  runtime_library_t *lib = as_library(l);
  swift_stream_control_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_control_fn,
                                coakka_v2_stream_lane_forget_session)
          : NULL;
  return f ? f(lane, id, d) : COAKKA_SWIFT_ERR_SYMBOL;
}
int32_t coakka_swift_stream_stats(coakka_swift_runtime_library_t *l,
                                  coakka_swift_stream_lane_t *lane,
                                  coakka_swift_stream_stats_t *out) {
  runtime_library_t *lib = as_library(l);
  swift_stream_stats_fn f =
      lib ? SWIFT_STREAM_SYMBOL(lib, swift_stream_stats_fn,
                                coakka_v2_stream_lane_get_stats)
          : NULL;
  if (out) {
    memset(out, 0, sizeof(*out));
    out->struct_size = sizeof(*out);
  }
  return f ? f(lane, out) : COAKKA_SWIFT_ERR_SYMBOL;
}

uint32_t coakka_swift_runtime_get_abi_version(coakka_swift_runtime_library_t *library) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL ? 0 : lib->get_abi_version();
}

int32_t coakka_swift_runtime_get_info(coakka_swift_runtime_library_t *library,
                                      coakka_swift_runtime_info_t *out_info) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || out_info == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    native_runtime_info_t native = {0};
    native.struct_size = sizeof(native);
    int32_t status = lib->get_info(&native);
    if (status != COAKKA_SWIFT_OK) {
        return status;
    }
    memset(out_info, 0, sizeof(*out_info));
    out_info->struct_size = sizeof(*out_info);
    out_info->abi_version = native.abi_version;
    out_info->feature_flags = native.feature_flags;
    out_info->runtime_version = native.runtime_version;
    out_info->git_commit = native.git_commit;
    out_info->backend = native.southbound_backend;
    return COAKKA_SWIFT_OK;
}

coakka_swift_runtime_t *coakka_swift_runtime_create(coakka_swift_runtime_library_t *library,
                                                    const char *system_name,
                                                    const char *node_id,
                                                    int strict_no_drop,
                                                    int queue_capacity) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL) {
        return NULL;
    }
    native_runtime_config_t config = {
        .system_name = system_name,
        .node_id = node_id,
        .strict_no_drop = strict_no_drop,
        .queue_capacity = queue_capacity,
    };
    return (coakka_swift_runtime_t *)lib->runtime_create(&config);
}

void coakka_swift_runtime_destroy(coakka_swift_runtime_library_t *library,
                                  coakka_swift_runtime_t *runtime) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || runtime == NULL) {
        return;
    }
    lib->runtime_destroy((native_runtime_t *)runtime);
}

int32_t coakka_swift_runtime_apply_network(coakka_swift_runtime_library_t *library,
                                           coakka_swift_runtime_t *runtime,
                                           uint32_t mode,
                                           const char *bind_host,
                                           uint16_t bind_port,
                                           const char *advertise_host,
                                           uint16_t advertise_port) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || runtime == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    native_network_options_t options;
    memset(&options, 0, sizeof(options));
    options.struct_size = sizeof(options);
    options.fields = mode == COAKKA_SWIFT_NETWORK_NODE ? UINT64_C(0x1f) : UINT64_C(0x01);
    if (bind_host != NULL) options.fields |= UINT64_C(0x02);
    if (advertise_host != NULL) options.fields |= UINT64_C(0x04);
    if (bind_port != 0) options.fields |= UINT64_C(0x08);
    if (advertise_port != 0) options.fields |= UINT64_C(0x10);
    options.mode = mode;
    options.bind_host = bind_host;
    options.advertise_host = advertise_host;
    options.bind_port = bind_port;
    options.advertise_port = advertise_port;
    return lib->apply_network_options((native_runtime_t *)runtime, &options);
}

int32_t coakka_swift_runtime_get_host_handles(coakka_swift_runtime_library_t *library,
                                              coakka_swift_runtime_t *runtime,
                                              uint32_t flags,
                                              coakka_swift_host_handles_t *out_handles) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || runtime == NULL || out_handles == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    memset(out_handles, 0, sizeof(*out_handles));
    out_handles->struct_size = sizeof(*out_handles);
    out_handles->flags = flags;
    out_handles->request_write_fd = -1;
    out_handles->response_read_fd = -1;
    out_handles->deadletter_read_fd = -1;
    out_handles->control_write_fd = -1;
    out_handles->monitor_read_fd = -1;
    out_handles->delivered_request_read_fd = -1;
    return lib->get_host_handles((native_runtime_t *)runtime, out_handles);
}

void coakka_swift_host_handles_close(coakka_swift_runtime_library_t *library,
    coakka_swift_host_handles_t *handles) {
    runtime_library_t *lib = as_library(library);
    if (lib != NULL && handles != NULL) lib->close_handles(handles);
}

int32_t coakka_swift_runtime_start(coakka_swift_runtime_library_t *library,
                                   coakka_swift_runtime_t *runtime) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL || runtime == NULL ? COAKKA_SWIFT_STATUS_INVALID_ARG : lib->runtime_start((native_runtime_t *)runtime);
}

int32_t coakka_swift_runtime_stop(coakka_swift_runtime_library_t *library,
                                  coakka_swift_runtime_t *runtime) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL || runtime == NULL ? COAKKA_SWIFT_STATUS_INVALID_ARG : lib->runtime_stop((native_runtime_t *)runtime);
}

int32_t coakka_swift_runtime_apply_snapshot(coakka_swift_runtime_library_t *library,
    coakka_swift_runtime_t *runtime, uint64_t generation,
    const coakka_swift_route_spec_t *routes, size_t count) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL) return COAKKA_SWIFT_STATUS_INVALID_ARG;
    /* Layout-checked synchronous borrows; Core copies and validates the snapshot.
     * No redundant route/endpoint heap graph or connector policy is needed. */
    native_control_snapshot_t snapshot = {generation, routes, count};
    return lib->apply_snapshot((native_runtime_t *)runtime, &snapshot);
}

int32_t coakka_swift_runtime_submit_envelope(coakka_swift_runtime_library_t *library,
                                             coakka_swift_runtime_t *runtime,
                                             const uint8_t *buf,
                                             size_t len) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL || runtime == NULL ? COAKKA_SWIFT_STATUS_INVALID_ARG : lib->submit_envelope((native_runtime_t *)runtime, buf, len);
}

int32_t coakka_swift_runtime_get_config(coakka_swift_runtime_library_t *library,
                                        coakka_swift_runtime_t *runtime,
                                        coakka_swift_runtime_config_view_t *out_config) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || runtime == NULL || out_config == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    native_runtime_config_view_t native = {0};
    native.struct_size = sizeof(native);
    int32_t status = lib->get_config((native_runtime_t *)runtime, &native);
    if (status != COAKKA_SWIFT_OK) {
        return status;
    }
    memset(out_config, 0, sizeof(*out_config));
    out_config->struct_size = sizeof(*out_config);
    out_config->system_name = native.system_name;
    out_config->node_id = native.node_id;
    out_config->strict_no_drop = native.strict_no_drop;
    out_config->queue_capacity = native.queue_capacity;
    out_config->runtime_state = native.runtime_state;
    out_config->snapshot_present = native.snapshot_present;
    out_config->applied_generation = native.applied_generation;
    out_config->route_count = native.route_count;
    return COAKKA_SWIFT_OK;
}

int32_t coakka_swift_runtime_get_health(coakka_swift_runtime_library_t *library,
                                        coakka_swift_runtime_t *runtime,
                                        coakka_swift_runtime_health_t *out_health) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || runtime == NULL || out_health == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    memset(out_health, 0, sizeof(*out_health));
    out_health->struct_size = sizeof(*out_health);
    return lib->get_health((native_runtime_t *)runtime, out_health);
}

int32_t coakka_swift_runtime_get_stats(coakka_swift_runtime_library_t *library,
                                       coakka_swift_runtime_t *runtime,
                                       coakka_swift_runtime_stats_t *out_stats) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || runtime == NULL || out_stats == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    memset(out_stats, 0, sizeof(*out_stats));
    out_stats->struct_size = sizeof(*out_stats);
    return lib->get_stats((native_runtime_t *)runtime, out_stats);
}

int32_t coakka_swift_runtime_get_capabilities(coakka_swift_runtime_library_t *library,
                                              coakka_swift_runtime_capabilities_t *out_capabilities) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || out_capabilities == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    memset(out_capabilities, 0, sizeof(*out_capabilities));
    out_capabilities->struct_size = sizeof(*out_capabilities);
    return lib->get_capabilities(out_capabilities);
}

int32_t coakka_swift_runtime_apply_tcp_connection_options(
    coakka_swift_runtime_library_t *library,
    coakka_swift_runtime_t *runtime,
    const coakka_swift_tcp_connection_options_t *options,
    coakka_swift_tcp_connection_apply_result_t *out_result) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || runtime == NULL || options == NULL || out_result == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    return lib->apply_tcp_connection_options((native_runtime_t *)runtime, options, out_result);
}

int32_t coakka_swift_runtime_get_tcp_connection_config(
    coakka_swift_runtime_library_t *library,
    coakka_swift_runtime_t *runtime,
    coakka_swift_tcp_connection_config_t *out_config) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || runtime == NULL || out_config == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    memset(out_config, 0, sizeof(*out_config));
    out_config->struct_size = sizeof(*out_config);
    return lib->get_tcp_connection_config((native_runtime_t *)runtime, out_config);
}

int32_t coakka_swift_runtime_apply_tcp_security_options(
    coakka_swift_runtime_library_t *library,
    coakka_swift_runtime_t *runtime,
    const coakka_swift_tcp_security_options_t *options,
    coakka_swift_tcp_security_apply_result_t *out_result) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || runtime == NULL || options == NULL || out_result == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    return lib->apply_tcp_security_options((native_runtime_t *)runtime, options, out_result);
}

int32_t coakka_swift_runtime_get_tcp_security_info(
    coakka_swift_runtime_library_t *library,
    coakka_swift_runtime_t *runtime,
    coakka_swift_tcp_security_info_t *out_info) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || runtime == NULL || out_info == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    memset(out_info, 0, sizeof(*out_info));
    out_info->struct_size = sizeof(*out_info);
    return lib->get_tcp_security_info((native_runtime_t *)runtime, out_info);
}

const char *coakka_swift_transport_apply_reason_name(coakka_swift_runtime_library_t *library,
                                                     uint32_t reason) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL) {
        return "UNKNOWN";
    }
    return lib->transport_apply_reason_name(reason);
}

const char *coakka_swift_deadletter_reason_name(coakka_swift_runtime_library_t *library,
                                               uint32_t reason) {
    runtime_library_t *lib = as_library(library);
    return lib == NULL ? NULL : lib->deadletter_reason_name(reason);
}

coakka_swift_ask_client_t *coakka_swift_ask_client_create(coakka_swift_runtime_library_t *library,
                                                          coakka_swift_runtime_t *runtime,
                                                          const coakka_swift_host_handles_t *handles) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || runtime == NULL || handles == NULL) {
        return NULL;
    }
    return (coakka_swift_ask_client_t *)lib->ask_client_create((native_runtime_t *)runtime, handles);
}

void coakka_swift_ask_client_destroy(coakka_swift_runtime_library_t *library,
                                     coakka_swift_ask_client_t *client) {
    runtime_library_t *lib = as_library(library);
    if (lib != NULL && client != NULL) {
        lib->ask_client_destroy((native_ask_client_t *)client);
    }
}

int32_t coakka_swift_ask_client_begin(coakka_swift_runtime_library_t *library,
                                      coakka_swift_ask_client_t *client,
                                      const uint8_t *request_buf,
                                      size_t request_len,
                                      coakka_swift_ask_ticket_t **out_ticket) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || client == NULL || out_ticket == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    native_ask_ticket_t *ticket = NULL;
    int32_t status = lib->ask_client_begin((native_ask_client_t *)client, request_buf, request_len, &ticket);
    *out_ticket = (coakka_swift_ask_ticket_t *)ticket;
    return status;
}

int32_t coakka_swift_ask_ticket_await(coakka_swift_runtime_library_t *library,
                                      coakka_swift_ask_ticket_t *ticket,
                                      uint32_t timeout_ms,
                                      uint32_t *out_result_kind,
                                      uint8_t **out_buf,
                                      size_t *out_len) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || ticket == NULL || out_result_kind == NULL || out_buf == NULL || out_len == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    return lib->ask_ticket_await((native_ask_ticket_t *)ticket, timeout_ms, out_result_kind, out_buf, out_len);
}

const char *coakka_swift_ask_ticket_message_id(coakka_swift_runtime_library_t *library,
                                               const coakka_swift_ask_ticket_t *ticket) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || ticket == NULL) {
        return "";
    }
    return lib->ask_ticket_message_id((const native_ask_ticket_t *)ticket);
}

void coakka_swift_ask_ticket_destroy(coakka_swift_runtime_library_t *library,
                                     coakka_swift_ask_ticket_t *ticket) {
    runtime_library_t *lib = as_library(library);
    if (lib != NULL && ticket != NULL) {
        lib->ask_ticket_destroy((native_ask_ticket_t *)ticket);
    }
}

int32_t coakka_swift_build_raw_request(coakka_swift_runtime_library_t *library,
                                       const coakka_swift_raw_request_spec_t *spec,
                                       uint8_t **out_buf,
                                       size_t *out_len) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || spec == NULL || out_buf == NULL || out_len == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    return lib->build_raw_request(spec, out_buf, out_len);
}

int32_t coakka_swift_build_raw_reply(coakka_swift_runtime_library_t *library,
                                     const coakka_swift_raw_reply_spec_t *spec,
                                     uint8_t **out_buf,
                                     size_t *out_len) {
    runtime_library_t *lib = as_library(library);
    if (lib == NULL || spec == NULL || out_buf == NULL || out_len == NULL) {
        return COAKKA_SWIFT_STATUS_INVALID_ARG;
    }
    return lib->build_raw_reply(spec, out_buf, out_len);
}

void coakka_swift_client_bytes_release(coakka_swift_runtime_library_t *library,
                                       uint8_t *buf) {
    runtime_library_t *lib = as_library(library);
    if (lib != NULL && buf != NULL) {
        lib->client_bytes_release(buf);
    }
}
