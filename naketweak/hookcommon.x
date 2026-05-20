#import "hookcommon.h"
#import <dlfcn.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <substrate.h>
#import "fishhook/fishhook.h"
#import <CFNetwork/CFNetwork.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/mount.h>
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
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <sys/ioctl.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <os/log.h>

static os_log_t hook_log = OS_LOG_DEFAULT;

// 原始函数指针
static int (*orig_access)(const char *path, int mode);
static void *(*orig_dlopen)(const char *path, int mode);
static void *(*orig_dlsym)(void *handle, const char *symbol);
static void (*orig_res_9_init)(void);
static Method (*orig_class_getClassMethod)(Class cls, SEL name);
static SEL (*orig_sel_registerName)(const char *name);
static CFDictionaryRef (*orig_CFNetworkCopySystemProxySettings)(void);
static CFDictionaryRef (*orig_CNCopyCurrentNetworkInfo)(CFStringRef interfaceName);
static CFArrayRef (*orig_CNCopySupportedInterfaces)(void);

// 文件和系统函数指针
static FILE *(*orig_fopen)(const char *path, const char *mode);
static char *(*orig_getenv)(const char *name);
static int (*orig_getifaddrs)(struct ifaddrs **ifap);
static int (*orig_gettimeofday)(struct timeval *tv, struct timezone *tz);
static long (*orig_getpagesize)(void);
static int (*orig_stat)(const char *path, struct stat *buf);
static int (*orig_statfs)(const char *path, struct statfs *buf);
static int (*orig_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
static int (*orig_sysctlbyname)(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
static int (*orig_uname)(struct utsname *name);
static int (*orig_isatty)(int fd);
static DIR *(*orig_opendir)(const char *filename);
static ssize_t (*orig_read)(int fd, void *buf, size_t count);
static uint32_t (*orig___dyld_image_count)(void);
static intptr_t (*orig___dyld_get_image_vmaddr_slide)(uint32_t image_index);
static const char *(*orig___dyld_get_image_name)(uint32_t image_index);

// 加密函数指针
static unsigned char *(*orig_CC_SHA256)(const void *data, CC_LONG len, unsigned char *md);
static int (*orig_CC_SHA1_Update)(CC_SHA1_CTX *context, const void *data, CC_LONG len);

// 主机信息函数指针
static kern_return_t (*orig_host_info)(host_t host, host_flavor_t flavor, host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt);
static kern_return_t (*orig_host_statistics64)(host_t host_priv, host_flavor_t flavor, host_info64_t host_info64, mach_msg_type_number_t *host_info64Cnt);
static kern_return_t (*orig_host_statistics)(host_t host_priv, host_flavor_t flavor, host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt);



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
        os_log(hook_log, "[HOOK] dlopen called with path: %{public}s, mode: %d", path, mode);
    }
    return orig_dlopen(path, mode);
}

// hook的dlsym实现
static void *new_dlsym(void *handle, const char *symbol) {
    if (symbol) {
        os_log(hook_log, "[HOOK] dlsym called with symbol: %{public}s", symbol);
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
    os_log(hook_log, "[HOOK] _res_9_init called");
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
    os_log(hook_log, "[HOOK] class_getClassMethod called for class: %{public}s, selector: %{public}s", 
          class_getName(cls), sel_getName(name));
    return orig_class_getClassMethod(cls, name);
}

// 初始化class_getClassMethod hook
void hook_class_getClassMethod(void) {
    MSHookFunction((void *)class_getClassMethod, (void *)new_class_getClassMethod, (void **)&orig_class_getClassMethod);
}

// hook的sel_registerName实现
static SEL new_sel_registerName(const char *name) {
    os_log(hook_log, "[HOOK] sel_registerName called with name: %{public}s", name);
    return orig_sel_registerName(name);
}

// 初始化sel_registerName hook
void hook_sel_registerName(void) {
    MSHookFunction((void *)sel_registerName, (void *)new_sel_registerName, (void **)&orig_sel_registerName);
}

// hook的CFNetworkCopySystemProxySettings实现
static CFDictionaryRef new_CFNetworkCopySystemProxySettings(void) {
    os_log(hook_log, "[HOOK] CFNetworkCopySystemProxySettings called");
    CFDictionaryRef proxySettings = orig_CFNetworkCopySystemProxySettings();
    if (proxySettings) {
        os_log(hook_log, "[HOOK] CFNetworkCopySystemProxySettings returned proxy settings");
    }
    return proxySettings;
}

// 初始化CFNetworkCopySystemProxySettings hook
void hook_CFNetworkCopySystemProxySettings(void) {
    MSHookFunction((void *)CFNetworkCopySystemProxySettings, (void *)new_CFNetworkCopySystemProxySettings, (void **)&orig_CFNetworkCopySystemProxySettings);
}

// hook的CNCopyCurrentNetworkInfo实现
static CFDictionaryRef new_CNCopyCurrentNetworkInfo(CFStringRef interfaceName) {
    os_log(hook_log, "[HOOK] CNCopyCurrentNetworkInfo called with interface: %{public}@", interfaceName);
    return orig_CNCopyCurrentNetworkInfo(interfaceName);
}

// 初始化CNCopyCurrentNetworkInfo hook
void hook_CNCopyCurrentNetworkInfo(void) {
    MSHookFunction((void *)CNCopyCurrentNetworkInfo, (void *)new_CNCopyCurrentNetworkInfo, (void **)&orig_CNCopyCurrentNetworkInfo);
}

// hook的CNCopySupportedInterfaces实现
static CFArrayRef new_CNCopySupportedInterfaces(void) {
    os_log(hook_log, "[HOOK] CNCopySupportedInterfaces called");
    return orig_CNCopySupportedInterfaces();
}

// 初始化CNCopySupportedInterfaces hook
void hook_CNCopySupportedInterfaces(void) {
    MSHookFunction((void *)CNCopySupportedInterfaces, (void *)new_CNCopySupportedInterfaces, (void **)&orig_CNCopySupportedInterfaces);
}

// ============ 文件和系统函数的 hook 实现 ============

// hook的fopen实现
static FILE *new_fopen(const char *path, const char *mode) {
    os_log(hook_log, "[HOOK] fopen called with path: %{public}s, mode: %{public}s", path, mode);
    return orig_fopen(path, mode);
}

void hook_fopen(void) {
    MSHookFunction((void *)fopen, (void *)new_fopen, (void **)&orig_fopen);
}

// hook的getenv实现
static char *new_getenv(const char *name) {
    os_log(hook_log, "[HOOK] getenv called with name: %{public}s", name);
    return orig_getenv(name);
}

void hook_getenv(void) {
    MSHookFunction((void *)getenv, (void *)new_getenv, (void **)&orig_getenv);
}

// hook的getifaddrs实现
static int new_getifaddrs(struct ifaddrs **ifap) {
    os_log(hook_log, "[HOOK] getifaddrs called");
    return orig_getifaddrs(ifap);
}

void hook_getifaddrs(void) {
    MSHookFunction((void *)getifaddrs, (void *)new_getifaddrs, (void **)&orig_getifaddrs);
}

// hook的gettimeofday实现
static int new_gettimeofday(struct timeval *tv, struct timezone *tz) {
    os_log(hook_log, "[HOOK] gettimeofday called");
    return orig_gettimeofday(tv, tz);
}

void hook_gettimeofday(void) {
    MSHookFunction((void *)gettimeofday, (void *)new_gettimeofday, (void **)&orig_gettimeofday);
}

// hook的getpagesize实现
static long new_getpagesize(void) {
    os_log(hook_log, "[HOOK] getpagesize called");
    return orig_getpagesize();
}

void hook_getpagesize(void) {
    MSHookFunction((void *)getpagesize, (void *)new_getpagesize, (void **)&orig_getpagesize);
}

// hook的stat实现
static int new_stat(const char *path, struct stat *buf) {
    os_log(hook_log, "[HOOK] stat called with path: %{public}s", path);
    return orig_stat(path, buf);
}

void hook_stat(void) {
    MSHookFunction((void *)stat, (void *)new_stat, (void **)&orig_stat);
}

// hook的statfs实现
static int new_statfs(const char *path, struct statfs *buf) {
    os_log(hook_log, "[HOOK] statfs called with path: %{public}s", path);
    return orig_statfs(path, buf);
}

void hook_statfs(void) {
    MSHookFunction((void *)statfs, (void *)new_statfs, (void **)&orig_statfs);
}

// hook的__dyld_image_count实现
static uint32_t new___dyld_image_count(void) {
    os_log(hook_log, "[HOOK] __dyld_image_count called");
    return orig___dyld_image_count();
}

void hook___dyld_image_count(void) {
    MSHookFunction(_dyld_image_count, (void *)new___dyld_image_count, (void **)&orig___dyld_image_count);
}

// hook的__dyld_get_image_vmaddr_slide实现
static intptr_t new___dyld_get_image_vmaddr_slide(uint32_t image_index) {
    os_log(hook_log, "[HOOK] __dyld_get_image_vmaddr_slide called with image_index: %u", image_index);
    return orig___dyld_get_image_vmaddr_slide(image_index);
}

void hook___dyld_get_image_vmaddr_slide(void) {
    MSHookFunction(_dyld_get_image_vmaddr_slide, (void *)new___dyld_get_image_vmaddr_slide, (void **)&orig___dyld_get_image_vmaddr_slide);
}

// hook的__dyld_get_image_name实现
static const char *new___dyld_get_image_name(uint32_t image_index) {
    const char *image_name = orig___dyld_get_image_name(image_index);
    NSLog(@"[HOOK] __dyld_get_image_name called with image_index: %u, image_name: %s", image_index, image_name);
    return image_name;
}

void hook___dyld_get_image_name(void) {
    MSHookFunction(_dyld_get_image_name, (void *)new___dyld_get_image_name, (void **)&orig___dyld_get_image_name);
}

// hook的sysctl实现
static int new_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    os_log(hook_log, "[HOOK] sysctl called with namelen: %u", namelen);
    if (name) {
        for (u_int i = 0; i < namelen && i < 10; i++) {
            os_log(hook_log, "[HOOK] sysctl name[%u] = %d", i, name[i]);
        }
    }
    return orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
}

void hook_sysctl(void) {
    MSHookFunction((void *)sysctl, (void *)new_sysctl, (void **)&orig_sysctl);
}

// hook的sysctlbyname实现
static int new_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    os_log(hook_log, "[HOOK] sysctlbyname called with name: %{public}s", name);
    return orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
}

void hook_sysctlbyname(void) {
    MSHookFunction((void *)sysctlbyname, (void *)new_sysctlbyname, (void **)&orig_sysctlbyname);
}

// hook的uname实现
static int new_uname(struct utsname *name) {
    os_log(hook_log, "[HOOK] uname called");
    return orig_uname(name);
}

void hook_uname(void) {
    MSHookFunction((void *)uname, (void *)new_uname, (void **)&orig_uname);
}

// hook的isatty实现
static int new_isatty(int fd) {
    os_log(hook_log, "[HOOK] isatty called with fd: %d", fd);
    return orig_isatty(fd);
}

void hook_isatty(void) {
    MSHookFunction((void *)isatty, (void *)new_isatty, (void **)&orig_isatty);
}

// hook的opendir实现
static DIR *new_opendir(const char *filename) {
    os_log(hook_log, "[HOOK] opendir called with filename: %{public}s", filename);
    return orig_opendir(filename);
}

void hook_opendir(void) {
    MSHookFunction((void *)opendir, (void *)new_opendir, (void **)&orig_opendir);
}

// hook的read实现
static ssize_t new_read(int fd, void *buf, size_t count) {
    char path[PATH_MAX] = {0};
    os_log(hook_log, "[HOOK] read called with fd: %d, count: %zu", fd, count);
    if (fcntl(fd, F_GETPATH, path) == 0) {
        os_log(hook_log, "[hook_read] %{public}s fd=%d count=%zu", path, fd, count);
    }
    return orig_read(fd, buf, count);
}

void hook_read(void) {
    MSHookFunction((void *)read, (void *)new_read, (void **)&orig_read);
}

// ============ 加密函数的 hook 实现 ============

// hook的CC_SHA256实现
static void *new_CC_SHA256(const void *data, size_t len, unsigned char *md) {
    os_log(hook_log, "[HOOK] CC_SHA256 called with len: %u", (unsigned int)len);
    return orig_CC_SHA256(data, len, md);
}

void hook_CC_SHA256(void) {
    MSHookFunction((void *)CC_SHA256, (void *)new_CC_SHA256, (void **)&orig_CC_SHA256);
}

// hook的CC_SHA1_Update实现
static int new_CC_SHA1_Update(CC_SHA1_CTX *c, const void *data, CC_LONG len) {
    os_log(hook_log, "[HOOK] CC_SHA1_Update called with len: %u", (unsigned int)len);
    return orig_CC_SHA1_Update(c, data, len);
}

void hook_CC_SHA1_Update(void) {
    MSHookFunction((void *)CC_SHA1_Update, (void *)new_CC_SHA1_Update, (void **)&orig_CC_SHA1_Update);
}

// ============ 主机信息函数的 hook 实现 ============

// hook的host_info实现
static kern_return_t new_host_info(host_t host, host_flavor_t flavor, host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt) {
    os_log(hook_log, "[HOOK] host_info called with flavor: %u", flavor);
    return orig_host_info(host, flavor, host_info_out, host_info_outCnt);
}

void hook_host_info(void) {
    MSHookFunction((void *)host_info, (void *)new_host_info, (void **)&orig_host_info);
}

// hook的host_statistics64实现
static kern_return_t new_host_statistics64(host_t host_priv, host_flavor_t flavor, host_info64_t info, mach_msg_type_number_t *count) {
    os_log(hook_log, "[HOOK] host_statistics64 called with flavor: %u", flavor);
    return orig_host_statistics64(host_priv, flavor, info, count);
}

void hook_host_statistics64(void) {
    MSHookFunction((void *)host_statistics64, (void *)new_host_statistics64, (void **)&orig_host_statistics64);
}

// hook的host_statistics实现
static kern_return_t new_host_statistics(host_t host_priv, host_flavor_t flavor, host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt) {
    os_log(hook_log, "[HOOK] host_statistics called with flavor: %u", flavor);
    return orig_host_statistics(host_priv, flavor, host_info_out, host_info_outCnt);
}

void hook_host_statistics(void) {
    MSHookFunction((void *)host_statistics, (void *)new_host_statistics, (void **)&orig_host_statistics);
}


// ============ CoreFoundation 字符串函数的 hook 实现 ============

// hook的CFStringCreateCopy实现
static CFStringRef new_CFStringCreateCopy(CFAllocatorRef alloc, CFStringRef theString) {
    os_log(hook_log, "[HOOK] CFStringCreateCopy called");
    return orig_CFStringCreateCopy(alloc, theString);
}

void hook_CFStringCreateCopy(void) {
    MSHookFunction((void *)CFStringCreateCopy, (void *)new_CFStringCreateCopy, (void **)&orig_CFStringCreateCopy);
}

// hook的CFStringCreateWithCString实现
static CFStringRef new_CFStringCreateWithCString(CFAllocatorRef alloc, const char *cStr, CFStringEncoding encoding) {
    os_log(hook_log, "[HOOK] CFStringCreateWithCString called with cStr: %{public}s", cStr);
    return orig_CFStringCreateWithCString(alloc, cStr, encoding);
}

void hook_CFStringCreateWithCString(void) {
    MSHookFunction((void *)CFStringCreateWithCString, (void *)new_CFStringCreateWithCString, (void **)&orig_CFStringCreateWithCString);
}

// hook的CFStringCreateWithFileSystemRepresentation实现
static CFStringRef new_CFStringCreateWithFileSystemRepresentation(CFAllocatorRef alloc, const char *buffer) {
    os_log(hook_log, "[HOOK] CFStringCreateWithFileSystemRepresentation called with buffer: %{public}s", buffer);
    return orig_CFStringCreateWithFileSystemRepresentation(alloc, buffer);
}

void hook_CFStringCreateWithFileSystemRepresentation(void) {
    MSHookFunction((void *)CFStringCreateWithFileSystemRepresentation, (void *)new_CFStringCreateWithFileSystemRepresentation, (void **)&orig_CFStringCreateWithFileSystemRepresentation);
}

// hook的CFStringCreateWithFormat实现
static CFStringRef new_CFStringCreateWithFormat(CFAllocatorRef alloc, CFDictionaryRef formatOptions, CFStringRef format, ...) {
    os_log(hook_log, "[HOOK] CFStringCreateWithFormat called");
    va_list args;
    va_start(args, format);
    CFStringRef result = CFStringCreateWithFormatAndArguments(alloc, formatOptions, format, args);
    va_end(args);
    return result;
}

void hook_CFStringCreateWithFormat(void) {
    MSHookFunction((void *)CFStringCreateWithFormat, (void *)new_CFStringCreateWithFormat, (void **)&orig_CFStringCreateWithFormat);
}

// ============ CoreFoundation String 函数的 hook 实现 ============

// hook的CFStringAppend实现
static void (*orig_CFStringAppend)(CFMutableStringRef theString, CFStringRef appendString);
static void new_CFStringAppend(CFMutableStringRef theString, CFStringRef appendString) {
    os_log(hook_log, "[HOOK] CFStringAppend called");
    return orig_CFStringAppend(theString, appendString);
}
void hook_CFStringAppend(void) {
    MSHookFunction((void *)CFStringAppend, (void *)new_CFStringAppend, (void **)&orig_CFStringAppend);
}

// hook的CFStringGetLength实现
static CFIndex (*orig_CFStringGetLength)(CFStringRef theString);
static CFIndex new_CFStringGetLength(CFStringRef theString) {
    os_log(hook_log, "[HOOK] CFStringGetLength called");
    return orig_CFStringGetLength(theString);
}
void hook_CFStringGetLength(void) {
    MSHookFunction((void *)CFStringGetLength, (void *)new_CFStringGetLength, (void **)&orig_CFStringGetLength);
}

// hook的CFStringGetCString实现
static Boolean (*orig_CFStringGetCString)(CFStringRef theString, char *buffer, CFIndex bufferSize, CFStringEncoding encoding);
static Boolean new_CFStringGetCString(CFStringRef theString, char *buffer, CFIndex bufferSize, CFStringEncoding encoding) {
    os_log(hook_log, "[HOOK] CFStringGetCString called, bufferSize: %ld", (long)bufferSize);
    return orig_CFStringGetCString(theString, buffer, bufferSize, encoding);
}
void hook_CFStringGetCString(void) {
    MSHookFunction((void *)CFStringGetCString, (void *)new_CFStringGetCString, (void **)&orig_CFStringGetCString);
}

// ============ CoreFoundation Array 函数的 hook 实现 ============

// hook的CFArrayGetCount实现
static CFIndex (*orig_CFArrayGetCount)(CFArrayRef array);
static CFIndex new_CFArrayGetCount(CFArrayRef array) {
    os_log(hook_log, "[HOOK] CFArrayGetCount called");
    return orig_CFArrayGetCount(array);
}
void hook_CFArrayGetCount(void) {
    MSHookFunction((void *)CFArrayGetCount, (void *)new_CFArrayGetCount, (void **)&orig_CFArrayGetCount);
}

// hook的CFArrayGetValueAtIndex实现
static const void *(*orig_CFArrayGetValueAtIndex)(CFArrayRef array, CFIndex idx);
static const void *new_CFArrayGetValueAtIndex(CFArrayRef array, CFIndex idx) {
    os_log(hook_log, "[HOOK] CFArrayGetValueAtIndex called, idx: %ld", (long)idx);
    return orig_CFArrayGetValueAtIndex(array, idx);
}
void hook_CFArrayGetValueAtIndex(void) {
    MSHookFunction((void *)CFArrayGetValueAtIndex, (void *)new_CFArrayGetValueAtIndex, (void **)&orig_CFArrayGetValueAtIndex);
}

// ============ CoreFoundation Data 函数的 hook 实现 ============

// hook的CFDataCreate实现
static CFDataRef (*orig_CFDataCreate)(CFAllocatorRef allocator, const UInt8 *bytes, CFIndex length);
static CFDataRef new_CFDataCreate(CFAllocatorRef allocator, const UInt8 *bytes, CFIndex length) {
    os_log(hook_log, "[HOOK] CFDataCreate called, length: %ld", (long)length);
    return orig_CFDataCreate(allocator, bytes, length);
}
void hook_CFDataCreate(void) {
    MSHookFunction((void *)CFDataCreate, (void *)new_CFDataCreate, (void **)&orig_CFDataCreate);
}

// ============ CoreFoundation Dictionary 函数的 hook 实现 ============

// hook的CFDictionaryCreateCopy实现
static CFDictionaryRef (*orig_CFDictionaryCreateCopy)(CFAllocatorRef allocator, CFDictionaryRef dict);
static CFDictionaryRef new_CFDictionaryCreateCopy(CFAllocatorRef allocator, CFDictionaryRef theDict) {
    os_log(hook_log, "[HOOK] CFDictionaryCreateCopy called");
    return orig_CFDictionaryCreateCopy(allocator, theDict);
}
void hook_CFDictionaryCreateCopy(void) {
    MSHookFunction((void *)CFDictionaryCreateCopy, (void *)new_CFDictionaryCreateCopy, (void **)&orig_CFDictionaryCreateCopy);
}

// hook的CFDictionarySetValue实现
static void (*orig_CFDictionarySetValue)(CFMutableDictionaryRef dict, const void *key, const void *value);
static void new_CFDictionarySetValue(CFMutableDictionaryRef dict, const void *key, const void *value) {
    os_log(hook_log, "[HOOK] CFDictionarySetValue called");
    orig_CFDictionarySetValue(dict, key, value);
}
void hook_CFDictionarySetValue(void) {
    MSHookFunction((void *)CFDictionarySetValue, (void *)new_CFDictionarySetValue, (void **)&orig_CFDictionarySetValue);
}

// hook的CFDictionaryGetValue实现
static const void *(*orig_CFDictionaryGetValue)(CFDictionaryRef dict, const void *key);
static const void *new_CFDictionaryGetValue(CFDictionaryRef dict, const void *key) {
    os_log(hook_log, "[HOOK] CFDictionaryGetValue called");
    return orig_CFDictionaryGetValue(dict, key);
}
void hook_CFDictionaryGetValue(void) {
    MSHookFunction((void *)CFDictionaryGetValue, (void *)new_CFDictionaryGetValue, (void **)&orig_CFDictionaryGetValue);
}

// ============ CoreFoundation UUID 函数的 hook 实现 ============

// hook的CFUUIDCreate实现
static CFUUIDRef (*orig_CFUUIDCreate)(CFAllocatorRef allocator);
static CFUUIDRef new_CFUUIDCreate(CFAllocatorRef allocator) {
    os_log(hook_log, "[HOOK] CFUUIDCreate called");
    return orig_CFUUIDCreate(allocator);
}
void hook_CFUUIDCreate(void) {
    MSHookFunction((void *)CFUUIDCreate, (void *)new_CFUUIDCreate, (void **)&orig_CFUUIDCreate);
}

// ============ CoreFoundation URL 函数的 hook 实现 ============

// hook的CFURLCreateWithFileSystemPath实现
static CFURLRef new_CFURLCreateWithFileSystemPath(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory) {
    os_log(hook_log, "[HOOK] CFURLCreateWithFileSystemPath called");
    return orig_CFURLCreateWithFileSystemPath(allocator, filePath, pathStyle, isDirectory);
}

void hook_CFURLCreateWithFileSystemPath(void) {
    MSHookFunction((void *)CFURLCreateWithFileSystemPath, (void *)new_CFURLCreateWithFileSystemPath, (void **)&orig_CFURLCreateWithFileSystemPath);
}

// hook的CFURLCreateWithString实现
static CFURLRef new_CFURLCreateWithString(CFAllocatorRef allocator, CFStringRef URLString, CFURLRef baseURL) {
    os_log(hook_log, "[HOOK] CFURLCreateWithString called");
    return orig_CFURLCreateWithString(allocator, URLString, baseURL);
}

void hook_CFURLCreateWithString(void) {
    MSHookFunction((void *)CFURLCreateWithString, (void *)new_CFURLCreateWithString, (void **)&orig_CFURLCreateWithString);
}

// ============ 时间函数的 hook 实现 ============

// hook的CACurrentMediaTime实现
static CFTimeInterval new_CACurrentMediaTime(void) {
    os_log(hook_log, "[HOOK] CACurrentMediaTime called");
    return orig_CACurrentMediaTime();
}

void hook_CACurrentMediaTime(void) {
    MSHookFunction((void *)CACurrentMediaTime, (void *)new_CACurrentMediaTime, (void **)&orig_CACurrentMediaTime);
}

// ============ Keychain 存储和查询函数的 hook 实现 ============

// hook的SecItemAdd实现
static OSStatus new_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result) {
    // 打印attributes参数
    os_log(hook_log, "[HOOK] SecItemAdd called with attributes: %{public}@", attributes);
    return orig_SecItemAdd(attributes, result);
}

void hook_SecItemAdd(void) {
    MSHookFunction((void *)SecItemAdd, (void *)new_SecItemAdd, (void **)&orig_SecItemAdd);
}

// hook的SecItemUpdate实现
static OSStatus new_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    // 打印query参数
    os_log(hook_log, "[HOOK] SecItemUpdate called with query: %{public}@", query);
    // 打印attributesToUpdate参数
    os_log(hook_log, "[HOOK] SecItemUpdate called with attributesToUpdate: %{public}@", attributesToUpdate);
    // 打印attributesToUpdate参数
    // os_log(hook_log, "[HOOK] SecItemUpdate called with attributesToUpdate: %{public}@", attributesToUpdate);
    return orig_SecItemUpdate(query, attributesToUpdate);
}

void hook_SecItemUpdate(void) {
    MSHookFunction((void *)SecItemUpdate, (void *)new_SecItemUpdate, (void **)&orig_SecItemUpdate);
}

// hook的SecItemDelete实现
static OSStatus new_SecItemDelete(CFDictionaryRef query) {
    // 打印query参数
    os_log(hook_log, "[HOOK] SecItemDelete called with query: %{public}@", query);
    return orig_SecItemDelete(query);
}

void hook_SecItemDelete(void) {
    MSHookFunction((void *)SecItemDelete, (void *)new_SecItemDelete, (void **)&orig_SecItemDelete);
}

// hook的SecItemCopyMatching实现
static OSStatus new_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    // 打印query参数
    os_log(hook_log, "[HOOK] SecItemCopyMatching called with query: %{public}@", query);
    return orig_SecItemCopyMatching(query, result);
}

void hook_SecItemCopyMatching(void) {
    MSHookFunction((void *)SecItemCopyMatching, (void *)new_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching);
}

// ============ 新增系统函数的 hook 实现 ============

// dladdr 函数指针
static int (*orig_dladdr)(const void *addr, Dl_info *info);

// hook的dladdr实现
static int new_dladdr(void *addr, Dl_info *info) {
    os_log(hook_log, "[HOOK] dladdr called with addr: %p", addr);
    return orig_dladdr(addr, info);
}

void hook_dladdr(void) {
    MSHookFunction((void *)dladdr, (void *)new_dladdr, (void **)&orig_dladdr);
}

// faccessat 函数指针
static int (*orig_faccessat)(int dirfd, const char *pathname, int mode, int flags);

// hook的faccessat实现
static int new_faccessat(int dirfd, const char *pathname, int mode, int flags) {
    os_log(hook_log, "[HOOK] faccessat called with dirfd: %d, pathname: %{public}s, mode: %d, flags: %d", dirfd, pathname, mode, flags);
    return orig_faccessat(dirfd, pathname, mode, flags);
}

void hook_faccessat(void) {
    MSHookFunction((void *)faccessat, (void *)new_faccessat, (void **)&orig_faccessat);
}

// getpid 函数指针
static pid_t (*orig_getpid)(void);

// hook的getpid实现
static pid_t new_getpid(void) {
    os_log(hook_log, "[HOOK] getpid called");
    return orig_getpid();
}

void hook_getpid(void) {
    MSHookFunction((void *)getpid, (void *)new_getpid, (void **)&orig_getpid);
}

// getppid 函数指针
static pid_t (*orig_getppid)(void);

// hook的getppid实现
static pid_t new_getppid(void) {
    os_log(hook_log, "[HOOK] getppid called");
    return orig_getppid();
}

void hook_getppid(void) {
    MSHookFunction((void *)getppid, (void *)new_getppid, (void **)&orig_getppid);
}

// getsectiondata 函数指针
typedef const char *(*getsectiondata_func_t)(const struct mach_header *, const char *, const char *, unsigned long *);
static getsectiondata_func_t orig_getsectiondata;

// hook的getsectiondata实现
static const char *new_getsectiondata(const struct mach_header *mh, const char *segname, const char *section, unsigned long *size) {
    os_log(hook_log, "[HOOK] getsectiondata called with segname: %{public}s, section: %{public}s", segname, section);
    return orig_getsectiondata(mh, segname, section, size);
}

void hook_getsectiondata(void) {
    getsectiondata_func_t func = (getsectiondata_func_t)dlsym(RTLD_DEFAULT, "getsectiondata");
    if (func) {
        MSHookFunction((void *)func, (void *)new_getsectiondata, (void **)&orig_getsectiondata);
    }
}

// ioctl 函数指针
static int (*orig_ioctl)(int fd, unsigned long request, ...);

// hook的ioctl实现
static int new_ioctl(int fd, unsigned long request, ...) {
    os_log(hook_log, "[HOOK] ioctl called with fd: %d, request: %lu", fd, request);
    return orig_ioctl(fd, request);
}

void hook_ioctl(void) {
    MSHookFunction((void *)ioctl, (void *)new_ioctl, (void **)&orig_ioctl);
}

// snprintf 函数指针
static int (*orig_vsnprintf)(char *str, size_t size, const char *format, va_list ap);

static int new_vsnprintf(char *str, size_t size, const char *format, va_list ap) {
    os_log(hook_log, "[HOOK] vsnprintf called size=%zu format=%s", size, format);
    return orig_vsnprintf(str, size, format, ap);
}

/* 

所有成熟 hook 框架（fishhook / substrate / frida）
在处理 printf 系列时，都是 hook v* 版本


orig_snprintf 期望的是 展开后的可变参数，
 但你传进去的是一个 va_list，ABI 层面完全不匹配，轻则输出异常，重则直接 crash。
 C 标准库早就帮你准备好了“可转发版本”👇
 int vsnprintf(char *str, size_t size, const char *format, va_list ap);
 hook_vsnprintf就好了
 snprintf
  ↓
vsnprintf
  ↓
__vfprintf / __sfvwrite / ...
*/
void hook_snprintf(void) {
    MSHookFunction((void *)vsnprintf,
                   (void *)new_vsnprintf,
                   (void **)&orig_vsnprintf);
}

// rand 函数指针
static int (*orig_rand)(void);

// hook的rand实现
static int new_rand(void) {
    os_log(hook_log, "[HOOK] rand called");
    return orig_rand();
}

void hook_rand(void) {
    MSHookFunction((void *)rand, (void *)new_rand, (void **)&orig_rand);
}

// readdir 函数指针
static struct dirent *(*orig_readdir)(DIR *dirp);

// hook的readdir实现
static struct dirent *new_readdir(DIR *dirp) {
    os_log(hook_log, "[HOOK] readdir called");
    return orig_readdir(dirp);
}

void hook_readdir(void) {
    MSHookFunction((void *)readdir, (void *)new_readdir, (void **)&orig_readdir);
}

// rmdir 函数指针
static int (*orig_rmdir)(const char *path);

// hook的rmdir实现
static int new_rmdir(const char *path) {
    os_log(hook_log, "[HOOK] rmdir called with path: %{public}s", path);
    return orig_rmdir(path);
}

void hook_rmdir(void) {
    MSHookFunction((void *)rmdir, (void *)new_rmdir, (void **)&orig_rmdir);
}

// mkdir 函数指针
static int (*orig_mkdir)(const char *path, mode_t mode);

// hook的mkdir实现
static int new_mkdir(const char *path, mode_t mode) {
    os_log(hook_log, "[HOOK] mkdir called with path: %{public}s, mode: %d", path, mode);
    return orig_mkdir(path, mode);
}

void hook_mkdir(void) {
    MSHookFunction((void *)mkdir, (void *)new_mkdir, (void **)&orig_mkdir);
}

// socket 函数指针
static int (*orig_socket)(int domain, int type, int protocol);

// hook的socket实现
static int new_socket(int domain, int type, int protocol) {
    os_log(hook_log, "[HOOK] socket called with domain: %d, type: %d, protocol: %d", domain, type, protocol);
    return orig_socket(domain, type, protocol);
}

void hook_socket(void) {
    MSHookFunction((void *)socket, (void *)new_socket, (void **)&orig_socket);
}

// srand 函数指针
static void (*orig_srand)(unsigned int seed);

// hook的srand实现
static void new_srand(unsigned int seed) {
    os_log(hook_log, "[HOOK] srand called with seed: %u", seed);
    return orig_srand(seed);
}

void hook_srand(void) {
    MSHookFunction((void *)srand, (void *)new_srand, (void **)&orig_srand);
}

// strcmp 函数指针
static int (*orig_strcmp)(const char *s1, const char *s2);

// hook的strcmp实现
static int new_strcmp(const char *s1, const char *s2) {
    os_log(hook_log, "[HOOK] strcmp called with s1: %{public}s, s2: %{public}s", s1, s2);
    return orig_strcmp(s1, s2);
}

void hook_strcmp(void) {
    MSHookFunction((void *)strcmp, (void *)new_strcmp, (void **)&orig_strcmp);
}

// strnstr 函数指针
static char *(*orig_strnstr)(const char *haystack, const char *needle, size_t len);

// hook的strnstr实现
static char *new_strnstr(const char *haystack, const char *needle, size_t len) {
    os_log(hook_log, "[HOOK] strnstr called with haystack: %{public}s, needle: %{public}s, len: %zu", haystack, needle, len);
    return orig_strnstr(haystack, needle, len);
}

void hook_strnstr(void) {
    MSHookFunction((void *)strnstr, (void *)new_strnstr, (void **)&orig_strnstr);
}

// sysconf 函数指针
static long (*orig_sysconf)(int name);

// hook的sysconf实现
static long new_sysconf(int name) {
    os_log(hook_log, "[HOOK] sysconf called with name: %d", name);
    return orig_sysconf(name);
}

void hook_sysconf(void) {
    MSHookFunction((void *)sysconf, (void *)new_sysconf, (void **)&orig_sysconf);
}

// time 函数指针
static time_t (*orig_time)(time_t *tloc);

// hook的time实现
static time_t new_time(time_t *tloc) {
    os_log(hook_log, "[HOOK] time called");
    return orig_time(tloc);
}

void hook_time(void) {
    MSHookFunction((void *)time, (void *)new_time, (void **)&orig_time);
}

// strcasestr 函数指针
static char *(*orig_strcasestr)(const char *haystack, const char *needle);

// hook的strcasestr实现
static char *new_strcasestr(const char *haystack, const char *needle) {
    os_log(hook_log, "[HOOK] strcasestr called with haystack: %{public}s, needle: %{public}s", haystack, needle);
    return orig_strcasestr(haystack, needle);
}

void hook_strcasestr(void) {
    MSHookFunction((void *)strcasestr, (void *)new_strcasestr, (void **)&orig_strcasestr);
}

// snprintf 函数指针（用于替换已废弃的 sprintf）
typedef int (*snprintf_func_t)(char *str, size_t size, const char *format, ...);
static snprintf_func_t orig_snprintf_func;

// hook的snprintf实现（用于替换sprintf）
static int new_sprintf_wrapper(char *str, const char *format, ...) {
    os_log(hook_log, "[HOOK] sprintf called with format: %{public}s", format);
    va_list args;
    va_start(args, format);
    int result = vsnprintf(str, 1024, format, args);
    va_end(args);
    return result;
}

void hook_sprintf(void) {
    snprintf_func_t func = (snprintf_func_t)dlsym(RTLD_DEFAULT, "sprintf");
    if (func) {
        orig_snprintf_func = func;
        MSHookFunction((void *)func, (void *)new_sprintf_wrapper, (void **)&orig_snprintf_func);
    }
}

// ============ 额外文件操作函数的 hook 实现 ============

// fstat 函数指针
static int (*orig_fstat)(int fd, struct stat *buf);

// hook的fstat实现
static int new_fstat(int fd, struct stat *buf) {
    os_log(hook_log, "[HOOK] fstat called with fd: %d", fd);
    return orig_fstat(fd, buf);
}

void hook_fstat(void) {
    MSHookFunction((void *)fstat, (void *)new_fstat, (void **)&orig_fstat);
}

// fstatat 函数指针
static int (*orig_fstatat)(int dirfd, const char *pathname, struct stat *buf, int flags);

// hook的fstatat实现
static int new_fstatat(int dirfd, const char *pathname, struct stat *buf, int flags) {
    os_log(hook_log, "[HOOK] fstatat called with dirfd: %d, pathname: %{public}s, flags: %d", dirfd, pathname, flags);
    return orig_fstatat(dirfd, pathname, buf, flags);
}

void hook_fstatat(void) {
    MSHookFunction((void *)fstatat, (void *)new_fstatat, (void **)&orig_fstatat);
}

// lstat 函数指针
static int (*orig_lstat)(const char *pathname, struct stat *buf);

// hook的lstat实现
static int new_lstat(const char *pathname, struct stat *buf) {
    os_log(hook_log, "[HOOK] lstat called with pathname: %{public}s", pathname);
    return orig_lstat(pathname, buf);
}

void hook_lstat(void) {
    MSHookFunction((void *)lstat, (void *)new_lstat, (void **)&orig_lstat);
}

// fread 函数指针
static size_t (*orig_fread)(void *ptr, size_t size, size_t nmemb, FILE *stream);

// hook的fread实现
static size_t new_fread(void *ptr, size_t size, size_t nmemb, FILE *stream) {
    os_log(hook_log, "[HOOK] fread called with size: %zu, nmemb: %zu", size, nmemb);
    return orig_fread(ptr, size, nmemb, stream);
}

void hook_fread(void) {
    MSHookFunction((void *)fread, (void *)new_fread, (void **)&orig_fread);
}

// openat 函数指针
static int (*orig_openat)(int dirfd, const char *pathname, int flags, ...);

// hook的openat实现
static int new_openat(int dirfd, const char *pathname, int flags, ...) {
    NSLog(@"[HOOK] openat called with dirfd: %d, pathname: %s, flags: %d", dirfd, pathname, flags);
    return orig_openat(dirfd, pathname, flags);
}

void hook_openat(void) {
    MSHookFunction((void *)openat, (void *)new_openat, (void **)&orig_openat);
}

// popen 函数指针
static FILE *(*orig_popen)(const char *command, const char *type);

// hook的popen实现
static FILE *new_popen(const char *command, const char *type) {
    os_log(hook_log, "[HOOK] popen called with command: %{public}s, type: %{public}s", command, type);
    return orig_popen(command, type);
}

void hook_popen(void) {
    MSHookFunction((void *)popen, (void *)new_popen, (void **)&orig_popen);
}