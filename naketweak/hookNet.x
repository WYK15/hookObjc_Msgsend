#import "hookNet.h"
#import <substrate.h>
#import <Security/Security.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import "fishhook/fishhook.h"
#import <os/log.h>

static os_log_t hook_log = OS_LOG_DEFAULT;

static OSStatus (*orig_SSLCreateContext)(SSLContextRef *context, SSLProtocolSide protocolSide, SSLConnectionType connectionType);
static OSStatus new_SSLCreateContext(SSLContextRef *context, SSLProtocolSide protocolSide, SSLConnectionType connectionType) {
    os_log(hook_log, "[HOOK] SSLCreateContext called, protocolSide: %d, connectionType: %d", protocolSide, connectionType);
    return orig_SSLCreateContext(context, protocolSide, connectionType);
}
void hook_SSLCreateContext(void) {
    MSHookFunction((void *)SSLCreateContext, (void *)new_SSLCreateContext, (void **)&orig_SSLCreateContext);
}

static OSStatus (*orig_SSLSetConnection)(SSLContextRef context, SSLConnectionRef connection);
static OSStatus new_SSLSetConnection(SSLContextRef context, SSLConnectionRef connection) {
    os_log(hook_log, "[HOOK] SSLSetConnection called, context: %p, connection: %p", context, connection);
    return orig_SSLSetConnection(context, connection);
}
void hook_SSLSetConnection(void) {
    MSHookFunction((void *)SSLSetConnection, (void *)new_SSLSetConnection, (void **)&orig_SSLSetConnection);
}

static OSStatus (*orig_SSLWrite)(SSLContextRef context, const void *data, size_t dataLength, size_t *processed);
static OSStatus new_SSLWrite(SSLContextRef context, const void *data, size_t dataLength, size_t *processed) {
    os_log(hook_log, "[HOOK] SSLWrite called, context: %p, dataLength: %zu", context, dataLength);
    return orig_SSLWrite(context, data, dataLength, processed);
}
void hook_SSLWrite(void) {
    MSHookFunction((void *)SSLWrite, (void *)new_SSLWrite, (void **)&orig_SSLWrite);
}

static OSStatus (*orig_SSLRead)(SSLContextRef context, void *data, size_t dataLength, size_t *processed);
static OSStatus new_SSLRead(SSLContextRef context, void *data, size_t dataLength, size_t *processed) {
    os_log(hook_log, "[HOOK] SSLRead called, context: %p, dataLength: %zu", context, dataLength);
    return orig_SSLRead(context, data, dataLength, processed);
}
void hook_SSLRead(void) {
    MSHookFunction((void *)SSLRead, (void *)new_SSLRead, (void **)&orig_SSLRead);
}

static int (*orig_inet_pton)(int af, const char *src, void *dst);
static int new_inet_pton(int af, const char *src, void *dst) {
    os_log(hook_log, "[HOOK] inet_pton called, af: %d, src: %{public}s", af, src);
    return orig_inet_pton(af, src, dst);
}
void hook_inet_pton(void) {
    MSHookFunction((void *)inet_pton, (void *)new_inet_pton, (void **)&orig_inet_pton);
}
