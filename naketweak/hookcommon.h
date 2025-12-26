#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#ifndef HOOKCOMMON_H
#define HOOKCOMMON_H

void hook_access(void);
void hook_dlopen(void);
void hook_dlsym(void);
void hook_res_9_init(void);
void hook_class_getClassMethod(void);
void hook_sel_registerName(void);
void hook_CFNetworkCopySystemProxySettings(void);

// 文件和系统函数
void hook_fopen(void);
void hook_getenv(void);
void hook_getifaddrs(void);
void hook_stat(void);
void hook_sysctl(void);
void hook_sysctlbyname(void);
void hook_uname(void);
void hook_isatty(void);
void hook_open(void);
void hook_opendir(void);
void hook_read(void);

// 加密函数
void hook_CC_SHA256(void);

// 主机信息函数
void hook_host_info(void);
void hook_host_statistics64(void);

// CoreFoundation 字符串函数
void hook_CFStringCreateCopy(void);
void hook_CFStringCreateWithCString(void);
void hook_CFStringCreateWithFileSystemRepresentation(void);
void hook_CFStringCreateWithFormat(void);

// CoreFoundation URL 函数
void hook_CFURLCreateWithFileSystemPath(void);
void hook_CFURLCreateWithString(void);

// 时间函数
void hook_CACurrentMediaTime(void);

// Keychain 函数
void hook_SecItemAdd(void);
void hook_SecItemCopyMatching(void);
void hook_SecItemUpdate(void);
void hook_SecItemDelete(void);

#endif /* HOOKCOMMON_H */