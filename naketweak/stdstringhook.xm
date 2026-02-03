
#import <Foundation/Foundation.h>
#import "stdstringhook.h"
#import <dlfcn.h>
#include <stddef.h>
#include <substrate.h>

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
    // 可以在这里打印日志或者修改参数
    // 注意：s 可能不是 null-terminated 的，必须根据 n 来读取
    NSLog(@"[HOOK] Hooked append_len, append_s : %s , len : %zu", s, n);
    
    // 调用原始实现
    return orig_append_len(this_ptr, s, n);
}
// Hook: append(const char* s)
void* my_append_str(void* this_ptr, const char* s) {
    if (s) {
        NSLog(@"[HOOK] Hooked append_str: %s", s);
    }
    return orig_append_str(this_ptr, s);
}
// Hook: assign(const char* s, size_t n)
void* my_assign_len(void* this_ptr, const char* s, size_t n) {
    if (s) {
        NSLog(@"[HOOK] Hooked assign_str: %s : n : %zu", s, n);
    }
    return orig_assign_len(this_ptr, s, n);
}

void hook_stdstring_appendLen(void){
    NSLog(@"[nake-debug] hook_stdstring_appendLen CALLED");
    // std::append(const char* s, size_t n)
    const char* symbol_name_append_len = "_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKcm";
    
    // 在所有加载的动态库中查找 (RTLD_DEFAULT)
    void* append_len_addr = dlsym(RTLD_DEFAULT, symbol_name_append_len);

    // 如果找不到，尝试加两个下划线 (对应你 nm 的输出)
    if (!append_len_addr) {
        const char* symbol_name_append_len_2 = "__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKcm";
        append_len_addr = dlsym(RTLD_DEFAULT, symbol_name_append_len_2);
    }
    if (!append_len_addr) {
        NSLog(@"❌ [HOOK] Error: 找不到 std::string::append 的符号地址");
    }else {
        NSLog(@"✅[HOOK] 成功找到 std::string::append 的符号地址: %p", append_len_addr);
        MSHookFunction(append_len_addr, (void *)my_append_len, (void **)&orig_append_len);
    }
}

void hook_stdstring_append(void){
    // std::append(const char* s)
    const char *symbol_name_append_str = "_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc";
    void *append_str_addr = dlsym(RTLD_DEFAULT, symbol_name_append_str);
    if (!append_str_addr) {
        const char* symbol_name_append_str_2 = "__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc";
        append_str_addr = dlsym(RTLD_DEFAULT, symbol_name_append_str_2);
    }
    if (!append_str_addr) {
        NSLog(@"❌ [HOOK] Error: 找不到 std::string::append 的符号地址");
    }else {
        NSLog(@"✅[HOOK] 成功找到 std::string::append 的符号地址: %p", append_str_addr);
        MSHookFunction(append_str_addr, (void *)my_append_str, (void **)&orig_append_str);
    }
}

void hook_stdstring_assign(void){
    // std::assign(const char* s, size_t n)
    const char *symbol_name_assign_len = "_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6assignEPKcm";
    void *assign_len_addr = dlsym(RTLD_DEFAULT, symbol_name_assign_len);
    if (!assign_len_addr) {
        const char* symbol_name_assign_len_2 = "__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6assignEPKcm";
        assign_len_addr = dlsym(RTLD_DEFAULT, symbol_name_assign_len_2);
    }
    if (!assign_len_addr) {
        NSLog(@"❌ [HOOK] Error: 找不到 std::string::assign 的符号地址");
    }else {
        NSLog(@"✅[HOOK] 成功找到 std::string::assign 的符号地址: %p", assign_len_addr);
        MSHookFunction(assign_len_addr, (void *)my_assign_len, (void **)&orig_assign_len);
    }
}
