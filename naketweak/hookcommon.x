#import "hookcommon.h"
#import <dlfcn.h>
#import <Foundation/Foundation.h>
#include <substrate.h>
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

// hook的CNCopyCurrentNetworkInfo实现
static CFDictionaryRef new_CNCopyCurrentNetworkInfo(CFStringRef interfaceName) {
    NSLog(@"[HOOK] CNCopyCurrentNetworkInfo called with interface: %@", interfaceName);
    return orig_CNCopyCurrentNetworkInfo(interfaceName);
}

// 初始化CNCopyCurrentNetworkInfo hook
void hook_CNCopyCurrentNetworkInfo(void) {
    MSHookFunction((void *)CNCopyCurrentNetworkInfo, (void *)new_CNCopyCurrentNetworkInfo, (void **)&orig_CNCopyCurrentNetworkInfo);
}

// hook的CNCopySupportedInterfaces实现
static CFArrayRef new_CNCopySupportedInterfaces(void) {
    NSLog(@"[HOOK] CNCopySupportedInterfaces called");
    return orig_CNCopySupportedInterfaces();
}

// 初始化CNCopySupportedInterfaces hook
void hook_CNCopySupportedInterfaces(void) {
    MSHookFunction((void *)CNCopySupportedInterfaces, (void *)new_CNCopySupportedInterfaces, (void **)&orig_CNCopySupportedInterfaces);
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

// hook的gettimeofday实现
static int new_gettimeofday(struct timeval *tv, struct timezone *tz) {
    NSLog(@"[HOOK] gettimeofday called");
    return orig_gettimeofday(tv, tz);
}

void hook_gettimeofday(void) {
    MSHookFunction((void *)gettimeofday, (void *)new_gettimeofday, (void **)&orig_gettimeofday);
}

// hook的getpagesize实现
static long new_getpagesize(void) {
    NSLog(@"[HOOK] getpagesize called");
    return orig_getpagesize();
}

void hook_getpagesize(void) {
    MSHookFunction((void *)getpagesize, (void *)new_getpagesize, (void **)&orig_getpagesize);
}

// hook的stat实现
static int new_stat(const char *path, struct stat *buf) {
    NSLog(@"[HOOK] stat called with path: %s", path);
    return orig_stat(path, buf);
}

void hook_stat(void) {
    MSHookFunction((void *)stat, (void *)new_stat, (void **)&orig_stat);
}

// hook的statfs实现
static int new_statfs(const char *path, struct statfs *buf) {
    NSLog(@"[HOOK] statfs called with path: %s", path);
    return orig_statfs(path, buf);
}

void hook_statfs(void) {
    MSHookFunction((void *)statfs, (void *)new_statfs, (void **)&orig_statfs);
}

// hook的__dyld_image_count实现
static uint32_t new___dyld_image_count(void) {
    NSLog(@"[HOOK] __dyld_image_count called");
    return orig___dyld_image_count();
}

void hook___dyld_image_count(void) {
    MSHookFunction(_dyld_image_count, (void *)new___dyld_image_count, (void **)&orig___dyld_image_count);
}

// hook的__dyld_get_image_vmaddr_slide实现
static intptr_t new___dyld_get_image_vmaddr_slide(uint32_t image_index) {
    NSLog(@"[HOOK] __dyld_get_image_vmaddr_slide called with image_index: %u", image_index);
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

// hook的CC_SHA1_Update实现
static int new_CC_SHA1_Update(CC_SHA1_CTX *context, const void *data, CC_LONG len) {
    NSLog(@"[HOOK] CC_SHA1_Update called with len: %u", len);
    return orig_CC_SHA1_Update(context, data, len);
}

void hook_CC_SHA1_Update(void) {
    MSHookFunction((void *)CC_SHA1_Update, (void *)new_CC_SHA1_Update, (void **)&orig_CC_SHA1_Update);
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

// hook的host_statistics实现
static kern_return_t new_host_statistics(host_t host_priv, host_flavor_t flavor, host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt) {
    NSLog(@"[HOOK] host_statistics called with flavor: %u", flavor);
    return orig_host_statistics(host_priv, flavor, host_info_out, host_info_outCnt);
}

void hook_host_statistics(void) {
    MSHookFunction((void *)host_statistics, (void *)new_host_statistics, (void **)&orig_host_statistics);
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

// ============ 新增系统函数的 hook 实现 ============

// dladdr 函数指针
static int (*orig_dladdr)(const void *addr, Dl_info *info);

// hook的dladdr实现
static int new_dladdr(const void *addr, Dl_info *info) {
    NSLog(@"[HOOK] dladdr called with addr: %p", addr);
    return orig_dladdr(addr, info);
}

void hook_dladdr(void) {
    MSHookFunction((void *)dladdr, (void *)new_dladdr, (void **)&orig_dladdr);
}

// faccessat 函数指针
static int (*orig_faccessat)(int dirfd, const char *pathname, int mode, int flags);

// hook的faccessat实现
static int new_faccessat(int dirfd, const char *pathname, int mode, int flags) {
    NSLog(@"[HOOK] faccessat called with dirfd: %d, pathname: %s, mode: %d, flags: %d", dirfd, pathname, mode, flags);
    return orig_faccessat(dirfd, pathname, mode, flags);
}

void hook_faccessat(void) {
    MSHookFunction((void *)faccessat, (void *)new_faccessat, (void **)&orig_faccessat);
}

// getpid 函数指针
static pid_t (*orig_getpid)(void);

// hook的getpid实现
static pid_t new_getpid(void) {
    NSLog(@"[HOOK] getpid called");
    return orig_getpid();
}

void hook_getpid(void) {
    MSHookFunction((void *)getpid, (void *)new_getpid, (void **)&orig_getpid);
}

// getppid 函数指针
static pid_t (*orig_getppid)(void);

// hook的getppid实现
static pid_t new_getppid(void) {
    NSLog(@"[HOOK] getppid called");
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
    NSLog(@"[HOOK] getsectiondata called with segname: %s, section: %s", segname, section);
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
    NSLog(@"[HOOK] ioctl called with fd: %d, request: %lu", fd, request);
    return orig_ioctl(fd, request);
}

void hook_ioctl(void) {
    MSHookFunction((void *)ioctl, (void *)new_ioctl, (void **)&orig_ioctl);
}

// snprintf 函数指针
static int (*orig_vsnprintf)(char *str, size_t size, const char *format, va_list ap);

static int new_vsnprintf(char *str, size_t size, const char *format, va_list ap) {
    NSLog(@"[HOOK] vsnprintf called size=%zu format=%s", size, format);
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
    NSLog(@"[HOOK] rand called");
    return orig_rand();
}

void hook_rand(void) {
    MSHookFunction((void *)rand, (void *)new_rand, (void **)&orig_rand);
}

// readdir 函数指针
static struct dirent *(*orig_readdir)(DIR *dirp);

// hook的readdir实现
static struct dirent *new_readdir(DIR *dirp) {
    NSLog(@"[HOOK] readdir called");
    return orig_readdir(dirp);
}

void hook_readdir(void) {
    MSHookFunction((void *)readdir, (void *)new_readdir, (void **)&orig_readdir);
}

// rmdir 函数指针
static int (*orig_rmdir)(const char *path);

// hook的rmdir实现
static int new_rmdir(const char *path) {
    NSLog(@"[HOOK] rmdir called with path: %s", path);
    return orig_rmdir(path);
}

void hook_rmdir(void) {
    MSHookFunction((void *)rmdir, (void *)new_rmdir, (void **)&orig_rmdir);
}

// mkdir 函数指针
static int (*orig_mkdir)(const char *path, mode_t mode);

// hook的mkdir实现
static int new_mkdir(const char *path, mode_t mode) {
    NSLog(@"[HOOK] mkdir called with path: %s, mode: %d", path, mode);
    return orig_mkdir(path, mode);
}

void hook_mkdir(void) {
    MSHookFunction((void *)mkdir, (void *)new_mkdir, (void **)&orig_mkdir);
}

// socket 函数指针
static int (*orig_socket)(int domain, int type, int protocol);

// hook的socket实现
static int new_socket(int domain, int type, int protocol) {
    NSLog(@"[HOOK] socket called with domain: %d, type: %d, protocol: %d", domain, type, protocol);
    return orig_socket(domain, type, protocol);
}

void hook_socket(void) {
    MSHookFunction((void *)socket, (void *)new_socket, (void **)&orig_socket);
}

// srand 函数指针
static void (*orig_srand)(unsigned int seed);

// hook的srand实现
static void new_srand(unsigned int seed) {
    NSLog(@"[HOOK] srand called with seed: %u", seed);
    return orig_srand(seed);
}

void hook_srand(void) {
    MSHookFunction((void *)srand, (void *)new_srand, (void **)&orig_srand);
}

// strcmp 函数指针
static int (*orig_strcmp)(const char *s1, const char *s2);

// hook的strcmp实现
static int new_strcmp(const char *s1, const char *s2) {
    NSLog(@"[HOOK] strcmp called with s1: %s, s2: %s", s1, s2);
    return orig_strcmp(s1, s2);
}

void hook_strcmp(void) {
    MSHookFunction((void *)strcmp, (void *)new_strcmp, (void **)&orig_strcmp);
}

// strnstr 函数指针
static char *(*orig_strnstr)(const char *haystack, const char *needle, size_t len);

// hook的strnstr实现
static char *new_strnstr(const char *haystack, const char *needle, size_t len) {
    NSLog(@"[HOOK] strnstr called with haystack: %s, needle: %s, len: %zu", haystack, needle, len);
    return orig_strnstr(haystack, needle, len);
}

void hook_strnstr(void) {
    MSHookFunction((void *)strnstr, (void *)new_strnstr, (void **)&orig_strnstr);
}

// sysconf 函数指针
static long (*orig_sysconf)(int name);

// hook的sysconf实现
static long new_sysconf(int name) {
    NSLog(@"[HOOK] sysconf called with name: %d", name);
    return orig_sysconf(name);
}

void hook_sysconf(void) {
    MSHookFunction((void *)sysconf, (void *)new_sysconf, (void **)&orig_sysconf);
}

// time 函数指针
static time_t (*orig_time)(time_t *tloc);

// hook的time实现
static time_t new_time(time_t *tloc) {
    NSLog(@"[HOOK] time called");
    return orig_time(tloc);
}

void hook_time(void) {
    MSHookFunction((void *)time, (void *)new_time, (void **)&orig_time);
}

// strcasestr 函数指针
static char *(*orig_strcasestr)(const char *haystack, const char *needle);

// hook的strcasestr实现
static char *new_strcasestr(const char *haystack, const char *needle) {
    NSLog(@"[HOOK] strcasestr called with haystack: %s, needle: %s", haystack, needle);
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
    NSLog(@"[HOOK] sprintf called with format: %s", format);
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
    NSLog(@"[HOOK] fstat called with fd: %d", fd);
    return orig_fstat(fd, buf);
}

void hook_fstat(void) {
    MSHookFunction((void *)fstat, (void *)new_fstat, (void **)&orig_fstat);
}

// fstatat 函数指针
static int (*orig_fstatat)(int dirfd, const char *pathname, struct stat *buf, int flags);

// hook的fstatat实现
static int new_fstatat(int dirfd, const char *pathname, struct stat *buf, int flags) {
    NSLog(@"[HOOK] fstatat called with dirfd: %d, pathname: %s, flags: %d", dirfd, pathname, flags);
    return orig_fstatat(dirfd, pathname, buf, flags);
}

void hook_fstatat(void) {
    MSHookFunction((void *)fstatat, (void *)new_fstatat, (void **)&orig_fstatat);
}

// lstat 函数指针
static int (*orig_lstat)(const char *pathname, struct stat *buf);

// hook的lstat实现
static int new_lstat(const char *pathname, struct stat *buf) {
    NSLog(@"[HOOK] lstat called with pathname: %s", pathname);
    return orig_lstat(pathname, buf);
}

void hook_lstat(void) {
    MSHookFunction((void *)lstat, (void *)new_lstat, (void **)&orig_lstat);
}

// fread 函数指针
static size_t (*orig_fread)(void *ptr, size_t size, size_t nmemb, FILE *stream);

// hook的fread实现
static size_t new_fread(void *ptr, size_t size, size_t nmemb, FILE *stream) {
    NSLog(@"[HOOK] fread called with size: %zu, nmemb: %zu", size, nmemb);
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
    NSLog(@"[HOOK] popen called with command: %s, type: %s", command, type);
    return orig_popen(command, type);
}

void hook_popen(void) {
    MSHookFunction((void *)popen, (void *)new_popen, (void **)&orig_popen);
}