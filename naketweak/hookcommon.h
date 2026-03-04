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
void hook_CNCopyCurrentNetworkInfo(void);
void hook_CNCopySupportedInterfaces(void);
void hook_gettimeofday(void);
void hook_getpagesize(void);
void hook_dladdr(void);
void hook_faccessat(void);
void hook_getpid(void);
void hook_getppid(void);
void hook_getsectiondata(void);
void hook_ioctl(void);
void hook_snprintf(void);
void hook_rand(void);
void hook_readdir(void);
void hook_rmdir(void);
void hook_mkdir(void);
void hook_socket(void);
void hook_srand(void);
void hook_strcmp(void);
void hook_strnstr(void);
void hook_sysconf(void);
void hook_time(void);
void hook_strcasestr(void);
void hook_sprintf(void);

// 文件和系统函数
void hook_fopen(void);
void hook_fread(void);
void hook_openat(void);
void hook_fstat(void);
void hook_fstatat(void);
void hook_lstat(void);
void hook_popen(void);
void hook_getenv(void);
void hook_getifaddrs(void);
void hook_stat(void);
void hook_statfs(void);
void hook_sysctl(void);
void hook_sysctlbyname(void);
void hook_uname(void);
void hook_isatty(void);
void hook_opendir(void);
void hook_read(void);
void hook___dyld_image_count(void);
void hook___dyld_get_image_vmaddr_slide(void);
void hook___dyld_get_image_name(void);

// 加密函数
void hook_CC_SHA256(void);
void hook_CC_SHA1_Update(void);

// 主机信息函数
void hook_host_info(void);
void hook_host_statistics64(void);
void hook_host_statistics(void);

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