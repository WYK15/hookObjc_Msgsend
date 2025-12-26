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
    struct rebinding res_rebind = {"_res_9_init", new_res_9_init, (void **)&orig_res_9_init};
    rebind_symbols(&res_rebind, 1);
}

// hook的class_getClassMethod实现
static Method new_class_getClassMethod(Class cls, SEL name) {
    NSLog(@"[HOOK] class_getClassMethod called for class: %s, selector: %s", 
          class_getName(cls), sel_getName(name));
    return orig_class_getClassMethod(cls, name);
}

// 初始化class_getClassMethod hook
void hook_class_getClassMethod(void) {
    struct rebinding class_rebind = {"class_getClassMethod", new_class_getClassMethod, (void **)&orig_class_getClassMethod};
    rebind_symbols(&class_rebind, 1);
}

// hook的sel_registerName实现
static SEL new_sel_registerName(const char *name) {
    NSLog(@"[HOOK] sel_registerName called with name: %s", name);
    return orig_sel_registerName(name);
}

// 初始化sel_registerName hook
void hook_sel_registerName(void) {
    struct rebinding sel_rebind = {"sel_registerName", new_sel_registerName, (void **)&orig_sel_registerName};
    rebind_symbols(&sel_rebind, 1);
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
    struct rebinding proxy_rebind = {"CFNetworkCopySystemProxySettings", new_CFNetworkCopySystemProxySettings, (void **)&orig_CFNetworkCopySystemProxySettings};
    rebind_symbols(&proxy_rebind, 1);
}

// ============ 文件和系统函数的 hook 实现 ============

// hook的fopen实现
static FILE *new_fopen(const char *path, const char *mode) {
    NSLog(@"[HOOK] fopen called with path: %s, mode: %s", path, mode);
    return orig_fopen(path, mode);
}

void hook_fopen(void) {
    struct rebinding fopen_rebind = {"fopen", new_fopen, (void **)&orig_fopen};
    rebind_symbols(&fopen_rebind, 1);
}

// hook的getenv实现
static char *new_getenv(const char *name) {
    NSLog(@"[HOOK] getenv called with name: %s", name);
    return orig_getenv(name);
}

void hook_getenv(void) {
    struct rebinding getenv_rebind = {"getenv", new_getenv, (void **)&orig_getenv};
    rebind_symbols(&getenv_rebind, 1);
}

// hook的getifaddrs实现
static int new_getifaddrs(struct ifaddrs **ifap) {
    NSLog(@"[HOOK] getifaddrs called");
    return orig_getifaddrs(ifap);
}

void hook_getifaddrs(void) {
    struct rebinding getifaddrs_rebind = {"getifaddrs", new_getifaddrs, (void **)&orig_getifaddrs};
    rebind_symbols(&getifaddrs_rebind, 1);
}

// hook的stat实现
static int new_stat(const char *path, struct stat *buf) {
    NSLog(@"[HOOK] stat called with path: %s", path);
    return orig_stat(path, buf);
}

void hook_stat(void) {
    struct rebinding stat_rebind = {"stat", new_stat, (void **)&orig_stat};
    rebind_symbols(&stat_rebind, 1);
}

// hook的sysctl实现
static int new_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    NSLog(@"[HOOK] sysctl called with namelen: %u", namelen);
    return orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
}

void hook_sysctl(void) {
    struct rebinding sysctl_rebind = {"sysctl", new_sysctl, (void **)&orig_sysctl};
    rebind_symbols(&sysctl_rebind, 1);
}

// hook的sysctlbyname实现
static int new_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    NSLog(@"[HOOK] sysctlbyname called with name: %s", name);
    return orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
}

void hook_sysctlbyname(void) {
    struct rebinding sysctlbyname_rebind = {"sysctlbyname", new_sysctlbyname, (void **)&orig_sysctlbyname};
    rebind_symbols(&sysctlbyname_rebind, 1);
}

// hook的uname实现
static int new_uname(struct utsname *name) {
    NSLog(@"[HOOK] uname called");
    return orig_uname(name);
}

void hook_uname(void) {
    struct rebinding uname_rebind = {"uname", new_uname, (void **)&orig_uname};
    rebind_symbols(&uname_rebind, 1);
}

// hook的isatty实现
static int new_isatty(int fd) {
    NSLog(@"[HOOK] isatty called with fd: %d", fd);
    return orig_isatty(fd);
}

void hook_isatty(void) {
    struct rebinding isatty_rebind = {"isatty", new_isatty, (void **)&orig_isatty};
    rebind_symbols(&isatty_rebind, 1);
}

// hook的open实现
static int new_open(const char *path, int oflag, ...) {
    va_list args;
    va_start(args, oflag);
    int mode = va_arg(args, int);
    va_end(args);
    NSLog(@"[HOOK] open called with path: %s, oflag: %d", path, oflag);
    return orig_open(path, oflag, mode);
}

void hook_open(void) {
    struct rebinding open_rebind = {"open", new_open, (void **)&orig_open};
    rebind_symbols(&open_rebind, 1);
}

// hook的opendir实现
static DIR *new_opendir(const char *filename) {
    NSLog(@"[HOOK] opendir called with filename: %s", filename);
    return orig_opendir(filename);
}

void hook_opendir(void) {
    struct rebinding opendir_rebind = {"opendir", new_opendir, (void **)&orig_opendir};
    rebind_symbols(&opendir_rebind, 1);
}

// hook的read实现
static ssize_t new_read(int fd, void *buf, size_t count) {
    NSLog(@"[HOOK] read called with fd: %d, count: %zu", fd, count);
    return orig_read(fd, buf, count);
}

void hook_read(void) {
    struct rebinding read_rebind = {"read", new_read, (void **)&orig_read};
    rebind_symbols(&read_rebind, 1);
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
    struct rebinding cfstringcopy_rebind = {"CFStringCreateCopy", new_CFStringCreateCopy, (void **)&orig_CFStringCreateCopy};
    rebind_symbols(&cfstringcopy_rebind, 1);
}

// hook的CFStringCreateWithCString实现
static CFStringRef new_CFStringCreateWithCString(CFAllocatorRef alloc, const char *cStr, CFStringEncoding encoding) {
    NSLog(@"[HOOK] CFStringCreateWithCString called with cStr: %s", cStr);
    return orig_CFStringCreateWithCString(alloc, cStr, encoding);
}

void hook_CFStringCreateWithCString(void) {
    struct rebinding cfstringcstring_rebind = {"CFStringCreateWithCString", new_CFStringCreateWithCString, (void **)&orig_CFStringCreateWithCString};
    rebind_symbols(&cfstringcstring_rebind, 1);
}

// hook的CFStringCreateWithFileSystemRepresentation实现
static CFStringRef new_CFStringCreateWithFileSystemRepresentation(CFAllocatorRef alloc, const char *buffer) {
    NSLog(@"[HOOK] CFStringCreateWithFileSystemRepresentation called with buffer: %s", buffer);
    return orig_CFStringCreateWithFileSystemRepresentation(alloc, buffer);
}

void hook_CFStringCreateWithFileSystemRepresentation(void) {
    struct rebinding cfstringfs_rebind = {"CFStringCreateWithFileSystemRepresentation", new_CFStringCreateWithFileSystemRepresentation, (void **)&orig_CFStringCreateWithFileSystemRepresentation};
    rebind_symbols(&cfstringfs_rebind, 1);
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
    struct rebinding cfstringformat_rebind = {"CFStringCreateWithFormat", new_CFStringCreateWithFormat, (void **)&orig_CFStringCreateWithFormat};
    rebind_symbols(&cfstringformat_rebind, 1);
}

// ============ CoreFoundation URL 函数的 hook 实现 ============

// hook的CFURLCreateWithFileSystemPath实现
static CFURLRef new_CFURLCreateWithFileSystemPath(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory) {
    NSLog(@"[HOOK] CFURLCreateWithFileSystemPath called");
    return orig_CFURLCreateWithFileSystemPath(allocator, filePath, pathStyle, isDirectory);
}

void hook_CFURLCreateWithFileSystemPath(void) {
    struct rebinding cfurlfs_rebind = {"CFURLCreateWithFileSystemPath", new_CFURLCreateWithFileSystemPath, (void **)&orig_CFURLCreateWithFileSystemPath};
    rebind_symbols(&cfurlfs_rebind, 1);
}

// hook的CFURLCreateWithString实现
static CFURLRef new_CFURLCreateWithString(CFAllocatorRef allocator, CFStringRef URLString, CFURLRef baseURL) {
    NSLog(@"[HOOK] CFURLCreateWithString called");
    return orig_CFURLCreateWithString(allocator, URLString, baseURL);
}

void hook_CFURLCreateWithString(void) {
    struct rebinding cfurlstring_rebind = {"CFURLCreateWithString", new_CFURLCreateWithString, (void **)&orig_CFURLCreateWithString};
    rebind_symbols(&cfurlstring_rebind, 1);
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
    struct rebinding secitemadd_rebind = {"SecItemAdd", new_SecItemAdd, (void **)&orig_SecItemAdd};
    rebind_symbols(&secitemadd_rebind, 1);
}

// hook的SecItemUpdate实现
static OSStatus new_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    NSLog(@"[HOOK] SecItemUpdate called");
    return orig_SecItemUpdate(query, attributesToUpdate);
}

void hook_SecItemUpdate(void) {
    struct rebinding secitemupdate_rebind = {"SecItemUpdate", new_SecItemUpdate, (void **)&orig_SecItemUpdate};
    rebind_symbols(&secitemupdate_rebind, 1);
}

// hook的SecItemDelete实现
static OSStatus new_SecItemDelete(CFDictionaryRef query) {
    NSLog(@"[HOOK] SecItemDelete called");
    return orig_SecItemDelete(query);
}

void hook_SecItemDelete(void) {
    struct rebinding secitemdelete_rebind = {"SecItemDelete", new_SecItemDelete, (void **)&orig_SecItemDelete};
    rebind_symbols(&secitemdelete_rebind, 1);
}

// hook的SecItemCopyMatching实现
static OSStatus new_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    NSLog(@"[HOOK] SecItemCopyMatching called");
    return orig_SecItemCopyMatching(query, result);
}

void hook_SecItemCopyMatching(void) {
    struct rebinding secitemcopy_rebind = {"SecItemCopyMatching", new_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching};
    rebind_symbols(&secitemcopy_rebind, 1);
}