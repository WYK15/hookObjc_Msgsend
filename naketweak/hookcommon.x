#import "hookcommon.h"
#import <dlfcn.h>
#import <Foundation/Foundation.h>
#include <substrate.h>

// 原始函数指针
static int (*orig_access)(const char *path, int mode);
static void *(*orig_dlopen)(const char *path, int mode);

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

// 初始化access hook
void hook_access(void) {
    MSHookFunction((void *)access, (void *)new_access, (void **)&orig_access);
}

// 初始化dlopen hook
void hook_dlopen(void) {
    MSHookFunction((void *)dlopen, (void *)new_dlopen, (void **)&orig_dlopen);
}