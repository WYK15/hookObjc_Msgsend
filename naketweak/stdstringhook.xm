
#import <Foundation/Foundation.h>
#import "stdstringhook.h"
#import <dlfcn.h>
#include <stddef.h>
#include <substrate.h>
#import <os/log.h>

static os_log_t hook_log = OS_LOG_DEFAULT;

// --- 原始函数指针定义 ---
// 注意：第一个参数必须是 void* (代表 this 指针)
// 返回值通常是 std::string&，这里用 void* 代替
// 1. append(const char* s, size_t n)
static void* (*orig_append_len)(void* this_ptr, const char* s, size_t n);
// 2. append(const char* s)
static void* (*orig_append_str)(void* this_ptr, const char* s);
// 3. assign(const char* s, size_t n)
static void* (*orig_assign_len)(void* this_ptr, const char* s, size_t n);
// --- 你的 Hook 实现 ---
// Hook: append(const char* s, size_t n)
void* my_append_len(void* this_ptr, const char* s, size_t n) {
    os_log(hook_log, "[HOOK] Hooked append_len, append_s : %{public}s , len : %zu", s, n);
    return orig_append_len(this_ptr, s, n);
}
// Hook: append(const char* s)
void* my_append_str(void* this_ptr, const char* s) {
    if (s) {
        os_log(hook_log, "[HOOK] Hooked append_str: %{public}s", s);
    }
    return orig_append_str(this_ptr, s);
}
// Hook: assign(const char* s, size_t n)
void* my_assign_len(void* this_ptr, const char* s, size_t n) {
    if (s) {
        os_log(hook_log, "[HOOK] Hooked assign_str: %{public}s : n : %zu", s, n);
    }
    return orig_assign_len(this_ptr, s, n);
}

void hook_stdstring_appendLen(void){
    os_log(hook_log, "[nake-debug] hook_stdstring_appendLen CALLED");
    const char* symbol_name_append_len = "_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKcm";
    
    void* append_len_addr = dlsym(RTLD_DEFAULT, symbol_name_append_len);

    if (!append_len_addr) {
        const char* symbol_name_append_len_2 = "__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKcm";
        append_len_addr = dlsym(RTLD_DEFAULT, symbol_name_append_len_2);
    }
    if (!append_len_addr) {
        os_log(hook_log, "❌ [HOOK] Error: 找不到 std::string::append 的符号地址");
    }else {
        os_log(hook_log, "✅[HOOK] 成功找到 std::string::append 的符号地址: %p", append_len_addr);
        MSHookFunction(append_len_addr, (void *)my_append_len, (void **)&orig_append_len);
    }
}

void hook_stdstring_append(void){
    const char *symbol_name_append_str = "_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc";
    void *append_str_addr = dlsym(RTLD_DEFAULT, symbol_name_append_str);
    if (!append_str_addr) {
        const char* symbol_name_append_str_2 = "__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc";
        append_str_addr = dlsym(RTLD_DEFAULT, symbol_name_append_str_2);
    }
    if (!append_str_addr) {
        os_log(hook_log, "❌ [HOOK] Error: 找不到 std::string::append 的符号地址");
    }else {
        os_log(hook_log, "✅[HOOK] 成功找到 std::string::append 的符号地址: %p", append_str_addr);
        MSHookFunction(append_str_addr, (void *)my_append_str, (void **)&orig_append_str);
    }
}

void hook_stdstring_assign(void){
    const char *symbol_name_assign_len = "_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6assignEPKcm";
    void *assign_len_addr = dlsym(RTLD_DEFAULT, symbol_name_assign_len);
    if (!assign_len_addr) {
        const char* symbol_name_assign_len_2 = "__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6assignEPKcm";
        assign_len_addr = dlsym(RTLD_DEFAULT, symbol_name_assign_len_2);
    }
    if (!assign_len_addr) {
        os_log(hook_log, "❌ [HOOK] Error: 找不到 std::string::assign 的符号地址");
    }else {
        os_log(hook_log, "✅[HOOK] 成功找到 std::string::assign 的符号地址: %p", assign_len_addr);
        MSHookFunction(assign_len_addr, (void *)my_assign_len, (void **)&orig_assign_len);
    }
}
