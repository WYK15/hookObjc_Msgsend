#import "hookcommon.h"
#import <dlfcn.h>
#import <Foundation/Foundation.h>
#include <substrate.h>
#import "fishhook/fishhook.h"
#import <CFNetwork/CFNetwork.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#include <unistd.h>
#include <ifaddrs.h>
#include <dirent.h>
#include <CommonCrypto/CommonDigest.h>
#include <mach/mach_host.h>
#include <QuartzCore/QuartzCore.h>
#include <Security/Security.h>
#include <limits.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>

// 原始函数指针
static int (*orig_access)(const char *path, int mode);
static void *(*orig_dlopen)(const char *path, int mode);
static void *(*orig_dlsym)(void *handle, const char *symbol);
static void (*orig_res_9_init)(void);
static Method (*orig_class_getClassMethod)(Class cls, SEL name);
static SEL (*orig_sel_registerName)(const char *name);
static CFDictionaryRef (*orig_CFNetworkCopySystemProxySettings)(void);

// 文件和系统函数指针
static FILE *(*orig_fopen)(const char *path, const char *mode);
static char *(*orig_getenv)(const char *name);
static int (*orig_getifaddrs)(struct ifaddrs **ifap);
static int (*orig_stat)(const char *path, struct stat *buf);
static int (*orig_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
static int (*orig_sysctlbyname)(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
static int (*orig_uname)(struct utsname *name);
static int (*orig_isatty)(int fd);
static int (*orig_open)(const char *path, int oflag, ...);
static DIR *(*orig_opendir)(const char *filename);
static ssize_t (*orig_read)(int fd, void *buf, size_t count);

// 加密函数指针
static unsigned char *(*orig_CC_SHA256)(const void *data, CC_LONG len, unsigned char *md);

// 主机信息函数指针
static kern_return_t (*orig_host_info)(host_t host, host_flavor_t flavor, host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt);
static kern_return_t (*orig_host_statistics64)(host_t host_priv, host_flavor_t flavor, host_info64_t host_info64, mach_msg_type_number_t *host_info64Cnt);

// CoreFoundation 字符串函数指针
static CFStringRef (*orig_CFStringCreateCopy)(CFAllocatorRef alloc, CFStringRef theString);
static CFStringRef (*orig_CFStringCreateWithCString)(CFAllocatorRef alloc, const char *cStr, CFStringEncoding encoding);
static CFStringRef (*orig_CFStringCreateWithFileSystemRepresentation)(CFAllocatorRef alloc, const char *buffer);
static CFStringRef (*orig_CFStringCreateWithFormat)(CFAllocatorRef alloc, CFDictionaryRef formatOptions, CFStringRef format, ...);

// CoreFoundation URL 函数指针
static CFURLRef (*orig_CFURLCreateWithFileSystemPath)(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory);
static CFURLRef (*orig_CFURLCreateWithString)(CFAllocatorRef allocator, CFStringRef URLString, CFURLRef baseURL);

// 时间函数指针
static CFTimeInterval (*orig_CACurrentMediaTime)(void);

// Keychain 函数指针
static OSStatus (*orig_SecItemAdd)(CFDictionaryRef attributes, CFTypeRef *result);
static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef query, CFTypeRef *result);
static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef query, CFDictionaryRef attributesToUpdate);
static OSStatus (*orig_SecItemDelete)(CFDictionaryRef query);

// hook的access实现
static int new_access(const char *path, int mode) {
    if (path) {
        //NSLog(@"[HOOK] access called with path: %s, mode: %d", path, mode);
    }
    return orig_access(path, mode);
}

// hook的dlopen实现
static void *new_dlopen(const char *path, int mode) {
    if (path) {
        NSLog(@"[HOOK] dlopen called with path: %s, mode: %d", path, mode);
    }
    return orig_dlopen(path, mode);
}

// hook的dlsym实现
static void *new_dlsym(void *handle, const char *symbol) {
    if (symbol) {
        NSLog(@"[HOOK] dlsym called with symbol: %s", symbol);
    }
    return orig_dlsym(handle, symbol);
}

// 初始化access hook
void hook_access(void) {
    MSHookFunction((void *)access, (void *)new_access, (void **)&orig_access);
}

// 初始化dlopen hook
void hook_dlopen(void) {
    MSHookFunction((void *)dlopen, (void *)new_dlopen, (void **)&orig_dlopen);
}

// 初始化dlsym hook
void hook_dlsym(void) {
    MSHookFunction((void *)dlsym, (void *)new_dlsym, (void **)&orig_dlsym);
}

// hook的_res_9_init实现
static void new_res_9_init(void) {
    NSLog(@"[HOOK] _res_9_init called");
    return orig_res_9_init();
}

// 初始化_res_9_init hook
void hook_res_9_init(void) {
    void *res_9_init_ptr = dlsym(RTLD_DEFAULT, "_res_9_init");
    if (res_9_init_ptr) {
        MSHookFunction(res_9_init_ptr, (void *)new_res_9_init, (void **)&orig_res_9_init);
    }
}

// hook的class_getClassMethod实现
static Method new_class_getClassMethod(Class cls, SEL name) {
    NSLog(@"[HOOK] class_getClassMethod called for class: %s, selector: %s", 
          class_getName(cls), sel_getName(name));
    return orig_class_getClassMethod(cls, name);
}

// 初始化class_getClassMethod hook
void hook_class_getClassMethod(void) {
    MSHookFunction((void *)class_getClassMethod, (void *)new_class_getClassMethod, (void **)&orig_class_getClassMethod);
}

// hook的sel_registerName实现
static SEL new_sel_registerName(const char *name) {
    NSLog(@"[HOOK] sel_registerName called with name: %s", name);
    return orig_sel_registerName(name);
}

// 初始化sel_registerName hook
void hook_sel_registerName(void) {
    MSHookFunction((void *)sel_registerName, (void *)new_sel_registerName, (void **)&orig_sel_registerName);
}

// hook的CFNetworkCopySystemProxySettings实现
static CFDictionaryRef new_CFNetworkCopySystemProxySettings(void) {
    NSLog(@"[HOOK] CFNetworkCopySystemProxySettings called");
    CFDictionaryRef result = orig_CFNetworkCopySystemProxySettings();
    if (result) {
        NSLog(@"[HOOK] CFNetworkCopySystemProxySettings returned proxy settings");
    }
    return result;
}

// 初始化CFNetworkCopySystemProxySettings hook
void hook_CFNetworkCopySystemProxySettings(void) {
    MSHookFunction((void *)CFNetworkCopySystemProxySettings, (void *)new_CFNetworkCopySystemProxySettings, (void **)&orig_CFNetworkCopySystemProxySettings);
}

// ============ 文件和系统函数的 hook 实现 ============

// hook的fopen实现
static FILE *new_fopen(const char *path, const char *mode) {
    NSLog(@"[HOOK] fopen called with path: %s, mode: %s", path, mode);
    return orig_fopen(path, mode);
}

void hook_fopen(void) {
    MSHookFunction((void *)fopen, (void *)new_fopen, (void **)&orig_fopen);
}

// hook的getenv实现
static char *new_getenv(const char *name) {
    NSLog(@"[HOOK] getenv called with name: %s", name);
    return orig_getenv(name);
}

void hook_getenv(void) {
    MSHookFunction((void *)getenv, (void *)new_getenv, (void **)&orig_getenv);
}

// hook的getifaddrs实现
static int new_getifaddrs(struct ifaddrs **ifap) {
    NSLog(@"[HOOK] getifaddrs called");
    return orig_getifaddrs(ifap);
}

void hook_getifaddrs(void) {
    MSHookFunction((void *)getifaddrs, (void *)new_getifaddrs, (void **)&orig_getifaddrs);
}

// hook的stat实现
static int new_stat(const char *path, struct stat *buf) {
    NSLog(@"[HOOK] stat called with path: %s", path);
    return orig_stat(path, buf);
}

void hook_stat(void) {
    MSHookFunction((void *)stat, (void *)new_stat, (void **)&orig_stat);
}

// hook的sysctl实现
static int new_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    NSLog(@"[HOOK] sysctl called with namelen: %u", namelen);
    for (u_int i = 0; i < namelen; i++) {
        NSLog(@"[HOOK] sysctl name[%u] = %d", i, name[i]);
    }
    return orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
}

void hook_sysctl(void) {
    MSHookFunction((void *)sysctl, (void *)new_sysctl, (void **)&orig_sysctl);
}

// hook的sysctlbyname实现
static int new_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    NSLog(@"[HOOK] sysctlbyname called with name: %s", name);
    return orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
}

void hook_sysctlbyname(void) {
    MSHookFunction((void *)sysctlbyname, (void *)new_sysctlbyname, (void **)&orig_sysctlbyname);
}

// hook的uname实现
static int new_uname(struct utsname *name) {
    NSLog(@"[HOOK] uname called");
    return orig_uname(name);
}

void hook_uname(void) {
    MSHookFunction((void *)uname, (void *)new_uname, (void **)&orig_uname);
}

// hook的isatty实现
static int new_isatty(int fd) {
    NSLog(@"[HOOK] isatty called with fd: %d", fd);
    return orig_isatty(fd);
}

void hook_isatty(void) {
    MSHookFunction((void *)isatty, (void *)new_isatty, (void **)&orig_isatty);
}

// hook的open实现
static int new_open(const char *path, int oflag, ...) {
    mode_t mode = 0;

    // 如果有 O_CREAT，必须取第三个参数
    if (oflag & O_CREAT) {
        va_list args;
        va_start(args, oflag);
        mode = va_arg(args, int);
        va_end(args);

        NSLog(@"[hook_open] %s flags=0x%x mode=%o", path, oflag, mode);
        return orig_open(path, oflag, mode);
    }

    NSLog(@"[hook_open] %s flags=0x%x", path, oflag);
    return orig_open(path, oflag);
}

void hook_open(void) {
    MSHookFunction((void *)open, (void *)new_open, (void **)&orig_open);
}

// hook的opendir实现
static DIR *new_opendir(const char *filename) {
    NSLog(@"[HOOK] opendir called with filename: %s", filename);
    return orig_opendir(filename);
}

void hook_opendir(void) {
    MSHookFunction((void *)opendir, (void *)new_opendir, (void **)&orig_opendir);
}

// hook的read实现
static ssize_t new_read(int fd, void *buf, size_t count) {
    char path[PATH_MAX] = {0};
    NSLog(@"[HOOK] read called with fd: %d, count: %zu", fd, count);
    if (fcntl(fd, F_GETPATH, path) == 0) {
        NSLog(@"[hook_read] %s fd=%d count=%zu", path, fd, count);
    }
    return orig_read(fd, buf, count);
}

void hook_read(void) {
    MSHookFunction((void *)read, (void *)new_read, (void **)&orig_read);
}

// ============ 加密函数的 hook 实现 ============

// hook的CC_SHA256实现
static unsigned char *new_CC_SHA256(const void *data, CC_LONG len, unsigned char *md) {
    NSLog(@"[HOOK] CC_SHA256 called with len: %u", len);
    return orig_CC_SHA256(data, len, md);
}

void hook_CC_SHA256(void) {
    MSHookFunction((void *)CC_SHA256, (void *)new_CC_SHA256, (void **)&orig_CC_SHA256);
}

// ============ 主机信息函数的 hook 实现 ============

// hook的host_info实现
static kern_return_t new_host_info(host_t host, host_flavor_t flavor, host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt) {
    NSLog(@"[HOOK] host_info called with flavor: %u", flavor);
    return orig_host_info(host, flavor, host_info_out, host_info_outCnt);
}

void hook_host_info(void) {
    MSHookFunction((void *)host_info, (void *)new_host_info, (void **)&orig_host_info);
}

// hook的host_statistics64实现
static kern_return_t new_host_statistics64(host_t host_priv, host_flavor_t flavor, host_info64_t host_info64, mach_msg_type_number_t *host_info64Cnt) {
    NSLog(@"[HOOK] host_statistics64 called with flavor: %u", flavor);
    return orig_host_statistics64(host_priv, flavor, host_info64, host_info64Cnt);
}

void hook_host_statistics64(void) {
    MSHookFunction((void *)host_statistics64, (void *)new_host_statistics64, (void **)&orig_host_statistics64);
}

// ============ CoreFoundation 字符串函数的 hook 实现 ============

// hook的CFStringCreateCopy实现
static CFStringRef new_CFStringCreateCopy(CFAllocatorRef alloc, CFStringRef theString) {
    NSLog(@"[HOOK] CFStringCreateCopy called");
    return orig_CFStringCreateCopy(alloc, theString);
}

void hook_CFStringCreateCopy(void) {
    MSHookFunction((void *)CFStringCreateCopy, (void *)new_CFStringCreateCopy, (void **)&orig_CFStringCreateCopy);
}

// hook的CFStringCreateWithCString实现
static CFStringRef new_CFStringCreateWithCString(CFAllocatorRef alloc, const char *cStr, CFStringEncoding encoding) {
    NSLog(@"[HOOK] CFStringCreateWithCString called with cStr: %s", cStr);
    return orig_CFStringCreateWithCString(alloc, cStr, encoding);
}

void hook_CFStringCreateWithCString(void) {
    MSHookFunction((void *)CFStringCreateWithCString, (void *)new_CFStringCreateWithCString, (void **)&orig_CFStringCreateWithCString);
}

// hook的CFStringCreateWithFileSystemRepresentation实现
static CFStringRef new_CFStringCreateWithFileSystemRepresentation(CFAllocatorRef alloc, const char *buffer) {
    NSLog(@"[HOOK] CFStringCreateWithFileSystemRepresentation called with buffer: %s", buffer);
    return orig_CFStringCreateWithFileSystemRepresentation(alloc, buffer);
}

void hook_CFStringCreateWithFileSystemRepresentation(void) {
    MSHookFunction((void *)CFStringCreateWithFileSystemRepresentation, (void *)new_CFStringCreateWithFileSystemRepresentation, (void **)&orig_CFStringCreateWithFileSystemRepresentation);
}

// hook的CFStringCreateWithFormat实现
static CFStringRef new_CFStringCreateWithFormat(CFAllocatorRef alloc, CFDictionaryRef formatOptions, CFStringRef format, ...) {
    NSLog(@"[HOOK] CFStringCreateWithFormat called");
    va_list args;
    va_start(args, format);
    CFStringRef result = CFStringCreateWithFormatAndArguments(alloc, formatOptions, format, args);
    va_end(args);
    return result;
}

void hook_CFStringCreateWithFormat(void) {
    MSHookFunction((void *)CFStringCreateWithFormat, (void *)new_CFStringCreateWithFormat, (void **)&orig_CFStringCreateWithFormat);
}

// ============ CoreFoundation URL 函数的 hook 实现 ============

// hook的CFURLCreateWithFileSystemPath实现
static CFURLRef new_CFURLCreateWithFileSystemPath(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory) {
    NSLog(@"[HOOK] CFURLCreateWithFileSystemPath called");
    return orig_CFURLCreateWithFileSystemPath(allocator, filePath, pathStyle, isDirectory);
}

void hook_CFURLCreateWithFileSystemPath(void) {
    MSHookFunction((void *)CFURLCreateWithFileSystemPath, (void *)new_CFURLCreateWithFileSystemPath, (void **)&orig_CFURLCreateWithFileSystemPath);
}

// hook的CFURLCreateWithString实现
static CFURLRef new_CFURLCreateWithString(CFAllocatorRef allocator, CFStringRef URLString, CFURLRef baseURL) {
    NSLog(@"[HOOK] CFURLCreateWithString called");
    return orig_CFURLCreateWithString(allocator, URLString, baseURL);
}

void hook_CFURLCreateWithString(void) {
    MSHookFunction((void *)CFURLCreateWithString, (void *)new_CFURLCreateWithString, (void **)&orig_CFURLCreateWithString);
}

// ============ 时间函数的 hook 实现 ============

// hook的CACurrentMediaTime实现
static CFTimeInterval new_CACurrentMediaTime(void) {
    NSLog(@"[HOOK] CACurrentMediaTime called");
    return orig_CACurrentMediaTime();
}

void hook_CACurrentMediaTime(void) {
    MSHookFunction((void *)CACurrentMediaTime, (void *)new_CACurrentMediaTime, (void **)&orig_CACurrentMediaTime);
}

// ============ Keychain 存储和查询函数的 hook 实现 ============

// hook的SecItemAdd实现
static OSStatus new_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result) {
    NSLog(@"[HOOK] SecItemAdd called");
    return orig_SecItemAdd(attributes, result);
}

void hook_SecItemAdd(void) {
    MSHookFunction((void *)SecItemAdd, (void *)new_SecItemAdd, (void **)&orig_SecItemAdd);
}

// hook的SecItemUpdate实现
static OSStatus new_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    NSLog(@"[HOOK] SecItemUpdate called");
    return orig_SecItemUpdate(query, attributesToUpdate);
}

void hook_SecItemUpdate(void) {
    MSHookFunction((void *)SecItemUpdate, (void *)new_SecItemUpdate, (void **)&orig_SecItemUpdate);
}

// hook的SecItemDelete实现
static OSStatus new_SecItemDelete(CFDictionaryRef query) {
    NSLog(@"[HOOK] SecItemDelete called");
    return orig_SecItemDelete(query);
}

void hook_SecItemDelete(void) {
    MSHookFunction((void *)SecItemDelete, (void *)new_SecItemDelete, (void **)&orig_SecItemDelete);
}

// hook的SecItemCopyMatching实现
static OSStatus new_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    NSLog(@"[HOOK] SecItemCopyMatching called");
    return orig_SecItemCopyMatching(query, result);
}

void hook_SecItemCopyMatching(void) {
    MSHookFunction((void *)SecItemCopyMatching, (void *)new_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching);
}