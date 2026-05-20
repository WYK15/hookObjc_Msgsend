#include <pthread.h>
#include <substrate.h>
#include <objc/message.h>
#include <os/log.h>
#import "asmdefines.h"
#import "hookobjcMsgsend.h"
#import "fishhook/fishhook.h"
#include <execinfo.h>

static os_log_t hook_log = OS_LOG_DEFAULT;

// params: str1, str2
// return: YES if str1 == str2, NO otherwise
BOOL customStrcmp(const char *str1, const char *str2) {
    if (str1 == NULL || str2 == NULL) {
        return NO;
    }
    
    while (*str1 != '\0' && *str2 != '\0') {
        if (*str1 != *str2) {
            return NO;
        }
        str1++;
        str2++;
    }
    
    return (*str1 == '\0' && *str2 == '\0');
}



__unused static id (*orig_objc_msgSend)(id, SEL, ...);
void printSpecificParam_fish(id self, SEL _cmd, void* param1, void* param2)
{
    const char *cname = object_getClassName(self);
    const char *selector = sel_getName(_cmd);

    const char* queue_label = dispatch_queue_get_label(NULL);

    void *callstack[128];
    int frames = backtrace(callstack, 128);
    
    if (frames > 15) {
        frames -= 15;
    }

    if (strcmp(selector, "characterAtIndex:") == 0 || strcmp(selector, "appendFormat:") == 0) {
        return;
    }

    if (strcmp(selector, "initWithContentsOfFile:") == 0) {
        os_log(hook_log, "%*s[HOOK] class is _NSPlaceholder*, classname: %s, method: %s, file: %{public}@", frames, "", cname, selector, param1);
    }else if (strcmp(selector, "initWithContentsOfURL:options:error:") == 0) {
        os_log(hook_log, "%*s[HOOK] class is _NSPlaceholder*, classname: %s, method: %s, url: %{public}@", frames, "", cname, selector, param1);
    }else if (strcmp(selector, "contentsOfDirectoryAtPath:error:") == 0) {
        os_log(hook_log, "%*s[HOOK] class is _NSPlaceholder*, classname: %s, method: %s, path: %{public}@", frames, "", cname, selector, param1);
    }else {
        os_log(hook_log, "%*s[HOOK] class is _NSPlaceholder*, classname: %s, method: %s", frames, "", cname, selector);
    }

    if (strncmp(cname, "_NSPlaceholder", 14) == 0 || strncmp(cname, "__NSPlaceholder", 15) == 0) {
        return;
    }

    if ( strcmp( selector, "isEqualToString:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, str: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "fileExistsAtPath:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, path: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "setObject:forKey:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, object: %{public}@, key: %{public}@", frames, "", cname, selector, self, param1, param2);
    } else if ( strcmp( selector, "dataUsingEncoding:" ) == 0 ){
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, encoding: %lu", frames, "", cname, selector, self, (NSUInteger)param1);
    } else if ( strcmp( selector, "objectForKey:" ) == 0 ){
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, key: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "stringByAppendingString:" ) == 0 ){
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, str2: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "dataWithJSONObject:options:error:" ) == 0 ){
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, json: %@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "stringWithUTF8String:" ) == 0 ){
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, utf8str: %{public}s", frames, "", cname, selector, self, (char*)param1); 
    } else if ( strcmp( selector, "appendFormat:" ) == 0 ){
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, format: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "stringWithFormat:" ) == 0 ){
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, format: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "dictionaryWithObjectsAndKeys:" ) == 0 ){
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, objects: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "hasPrefix:" ) == 0 ){
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, prefix: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "hasSuffix:" ) == 0 ){
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, suffix: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "UTF8String" ) == 0 ){
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self);
    } else if ( strcmp( selector, "containsString:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, subStr: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "setText:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, text: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "objectForKeyedSubscript:" ) == 0 ){
        // 这里打印self使用${public}@时，出现异常，导致app崩溃，崩溃日志显示如下：
        /*
  * frame #0: 0x00000001a86789e0 libdispatch.dylib`_dispatch_once_wait$VARIANT$armv81.cold.1 + 28
    frame #1: 0x00000001a86400b8 libdispatch.dylib`_dispatch_once_wait$VARIANT$armv81 + 180
    frame #2: 0x000000010af58998 neteasemusic`___lldb_unnamed_symbol613570 + 40
    frame #3: 0x000000010af59dd8 neteasemusic`___lldb_unnamed_symbol613603 + 28
    frame #4: 0x000000010b81a494 neteasemusic`___lldb_unnamed_symbol665885 + 20
    frame #5: 0x000000010b81adb4 neteasemusic`___lldb_unnamed_symbol665902 + 68
    frame #6: 0x00000001a18d8164 CoreFoundation`-[NSDictionary descriptionWithLocale:indent:] + 1104
    frame #7: 0x000000019bc77008 Foundation`_NS_os_log_callback + 248
    frame #8: 0x00000001b7499b04 libsystem_trace.dylib`_os_log_fmt_flatten_NSCF + 60
    frame #9: 0x00000001b74992bc libsystem_trace.dylib`_os_log_fmt_flatten_object + 212
    frame #10: 0x00000001b7497164 libsystem_trace.dylib`_os_log_impl_flatten_and_send + 1840
    frame #11: 0x00000001b7495310 libsystem_trace.dylib`_os_log + 148
    frame #12: 0x00000001b749a5e0 libsystem_trace.dylib`_os_log_impl + 16
    frame #13: 0x00000001176a950c nake.dylib`printSpecificParam_fish(self=86 key/value pairs, _cmd="objectForKeyedSubscript:", param1="NECustomConfigProtocol", param2=0x0000000280525497) at hookobjcMsgsend.xm:102:9
    frame #14: 0x00000001176ac55c nake.dylib`hook_Objc_msgSend_fishhook() at hookobjcMsgsend.xm:281:5
        */
        // 因此这里修改为使用%@打印self
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, key: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "attributesOfItemAtPath:error:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, path: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "initFileURLWithPath:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, path: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "initWithFileURL:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, url: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "initWithContentsOfURL:options:error:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, url: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "valueForKey:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, key: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "URLWithString:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, urlStr: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "stringWithContentsOfFile:encoding:error:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, path: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "stringWithContentsOfURL:encoding:error:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, url: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "writeToFile:atomically:encoding:error:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, path: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "writeToFile:atomically:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, path: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "writeToURL:atomically:encoding:error:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, url: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "JSONString" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self);
    } else if ( strcmp( selector, "JSONObjectWithData:options:error:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, data: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "base64EncodedStringWithOptions:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "base64EncodedDataWithOptions:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self);
    } else if ( strcmp( selector, "initWithBase64EncodedString:options:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, base64Str: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "initWithBase64EncodedData:options:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, data: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "MD5String" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self);
    } else if ( strcmp( selector, "SHA256String" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self);
    } else if ( strcmp( selector, "HMACWithAlgorithm:key:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, key: %{public}@", frames, "", cname, selector, self, param2);
    } else if ( strcmp( selector, "substringFromIndex:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, index: %lu", frames, "", cname, selector, self, (NSUInteger)param1);
    } else if ( strcmp( selector, "substringToIndex:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, index: %lu", frames, "", cname, selector, self, (NSUInteger)param1);
    } else if ( strcmp( selector, "substringWithRange:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, location: %lu, length: %lu", frames, "", cname, selector, self, (NSUInteger)param1, (NSUInteger)param2);
    } else if ( strcmp( selector, "rangeOfString:" ) == 0) {
        // 这个打印日志太多了，根据条件打印
        //os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, searchStr: %@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "componentsSeparatedByString:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, separator: %@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "stringByReplacingOccurrencesOfString:withString:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, target: %@, replacement: %@", frames, "", cname, selector, self, param1, param2);
    } else if ( strcmp( selector, "lowercaseString" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self);
    } else if ( strcmp( selector, "uppercaseString" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self);
    } else if ( strcmp( selector, "intValue" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "integerValue" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self);
    } else if ( strcmp( selector, "floatValue" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "doubleValue" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "boolValue" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "arrayWithArray:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, array: %@", frames, "", cname, selector, self, param1);  
    } else if ( strcmp( selector, "arrayWithObjects:count:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, count: %lu", frames, "", cname, selector, self, (NSUInteger)param2);
    } else if ( strcmp( selector, "addObject:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, object: %@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "removeObject:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, object: %@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "objectAtIndex:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, index: %lu", frames, "", cname, selector, self, (NSUInteger)param1);
    } else if ( strcmp( selector, "count" ) == 0) {
        /*
        使用%{public}@打印self时，出现崩溃，崩溃日志显示如下：
        * thread #19, queue = 'com.netease.urs.init (QOS: UNSPECIFIED)', stop reason = EXC_BREAKPOINT (code=1, subcode=0x1ec5dcf18)
  * frame #0: 0x00000001ec5dcf18 libsystem_platform.dylib`_os_unfair_lock_recursive_abort + 36
    frame #1: 0x00000001ec5dc1ac libsystem_platform.dylib`_os_unfair_lock_lock_slow + 280
    frame #2: 0x00000001a3878380 UIKitCore`+[UIScreen mainScreen] + 168
    frame #3: 0x00000001a3878148 UIKitCore`_UIScreenForcedMainScreenScale + 44
    frame #4: 0x00000001a3a51680 UIKitCore`-[UIScreenMode _sizeWithLevel:] + 56
    frame #5: 0x00000001a41ebf38 UIKitCore`-[UIScreenMode description] + 92
    frame #6: 0x00000001a881b298 BaseBoard`-[BSDescriptionBuilder appendObject:withName:skipIfNil:] + 316
    frame #7: 0x00000001a41e8a14 UIKitCore`-[UIScreen succinctDescriptionBuilder] + 116
    frame #8: 0x00000001a41e8978 UIKitCore`-[UIScreen succinctDescription] + 16
    frame #9: 0x00000001a18d7b34 CoreFoundation`-[NSArray descriptionWithLocale:indent:] + 460
    frame #10: 0x000000019bc77008 Foundation`_NS_os_log_callback + 248
    frame #11: 0x00000001b7499b04 libsystem_trace.dylib`_os_log_fmt_flatten_NSCF + 60
    frame #12: 0x00000001b74992bc libsystem_trace.dylib`_os_log_fmt_flatten_object + 212
    frame #13: 0x00000001b7497164 libsystem_trace.dylib`_os_log_impl_flatten_and_send + 1840
    frame #14: 0x00000001b7495310 libsystem_trace.dylib`_os_log + 148
    frame #15: 0x00000001b749a5e0 libsystem_trace.dylib`_os_log_impl + 16
    frame #16: 0x0000000112edaddc nake.dylib`printSpecificParam_fish(self=1 element, _cmd="count", param1=0x0000000000000000, param2=0x0000000000000001) at hookobjcMsgsend.xm:179:9
    frame #17: 0x0000000112edc55c nake.dylib`hook_Objc_msgSend_fishhook() at hookobjcMsgsend.xm:281:5
        // 因此这里修改为使用%@打印self
        */
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self);
    } else if ( strcmp( selector, "allKeys" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "allValues" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "removeObjectForKey:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, key: %{public}@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "removeAllObjects" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self);
    } else if ( strcmp( selector, "length" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self);
    } else if ( strcmp( selector, "characterAtIndex:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, index: %lu", frames, "", cname, selector, self, (NSUInteger)param1);
    } else if ( strcmp( selector, "init" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s", frames, "", cname, selector); 
    } else if ( strcmp( selector, "alloc" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "new" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "copy" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "mutableCopy" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "description" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "debugDescription" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self); 
    } else if ( strcmp( selector, "isEqual:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, other: %@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "hash" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@", frames, "", cname, selector, self);
    } else if ( strcmp( selector, "isKindOfClass:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, class: %@", frames, "", cname, selector, self, param1);
    } else if ( strcmp( selector, "isMemberOfClass:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, class: %@", frames, "", cname, selector, self, param1); 
    } else if ( strcmp( selector, "respondsToSelector:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, selector: %s", frames, "", cname, selector, self, sel_getName((SEL)param1));
    } else if ( strcmp( selector, "performSelector:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, selector: %s", frames, "", cname, selector, self, sel_getName((SEL)param1));
    } else if ( strcmp( selector, "performSelector:withObject:" ) == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, self: %{public}@, selector: %s, object: %@", frames, "", cname, selector, self, sel_getName((SEL)param1), param2);
    } else if (strcmp (selector, "dictionaryWithContentsOfFile:") == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, file: %{public}@", frames, "", cname, selector, param1);
    } else if (strcmp (selector, "attributesOfFileSystemForPath:") == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, path: %{public}@", frames, "", cname, selector, param1);
    } else if (strcmp (selector, "attributesOfFileSystemForPath:error:") == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, path: %{public}@", frames, "", cname, selector, param1);
    } else if (strcmp (selector, "dataWithContentsOfFile:") == 0) {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s, path: %{public}@", frames, "", cname, selector, param1);
    } 
    else {
        os_log(hook_log, "%*s[HOOK] class: %s, method: %s", frames, "", cname, selector);
    }
}

static int strlen_SOLO(const char *str) {
    int len = 0;
    while (*str++) {
        len++;
    }
    return len;
}


static const char* blackMethod[] = {"dealloc", "_xref_dispose", "mainScreen"};
static BOOL isBlackMethod(SEL _cmd) {
    // return YES;
    if (_cmd == NULL) {
        return NO;
    }
    char *cmdAddr = (char*)_cmd;
    for (int i = 0; i < sizeof(blackMethod) / sizeof(blackMethod[0]); i++) {
        int len1 = strlen_SOLO((const char*)cmdAddr);
        const char* blackMethodName = blackMethod[i];
        int len2 = strlen_SOLO(blackMethodName);
        if (len1 != len2) {
            continue;
        }
        BOOL found = YES;
        for(int j = 0; j < len1; j++) {
            if (cmdAddr[j] != blackMethodName[j]) {
                found = NO;
                break;
            }
        }
        if (found) {
            //os_log(hook_log, "blackMethod detected : %s",blackMethodName);
            return YES;
        }
    }
    return NO;
}


//ok - fishhook
__attribute__((__naked__))
static void hook_Objc_msgSend_fishhook() {
    // before之前保存objc_msgSend的参数
    saveLR()
    save()

     // 判断是否为黑名单方法
    __asm volatile ("mov x0, x1\n");
    call(blr, &isBlackMethod)
    //judge x0 is true, if true, call(blr, &before_objc_msgSend_fishhook)
    __asm volatile ("cbnz x0, 1f\n");
    load()
    save()

    call(blr, &printSpecificParam_fish)
   
    __asm volatile ("1:\n");
    // 恢复objc_msgSend参数，并执行
    load()
    
    // Call through to the original objc_msgSend.
    // blr会把当前PC+4回写到X30
    // br 直接无条件跳转到origin_objc_msgSend
    loadLR()
    call(br, orig_objc_msgSend)
}

static int (*orig_mincore)(void *addr, size_t len, unsigned char *flags);
int hook_mincore(void *addr, size_t len, unsigned char *flags) {
    os_log(hook_log, "[HOOK] mincore: %p, %zu, %p", addr, len, flags);
    return orig_mincore(addr, len, flags);
}


// hook kern_return_t vm_region_recurse_64(vm_map_read_t target_task, vm_address_t *address, vm_size_t *size, natural_t *nesting_depth, vm_region_recurse_info_t info, mach_msg_type_number_t *infoCnt);
static kern_return_t (*orig_vm_region_recurse_64)(vm_map_read_t target_task, vm_address_t *address, vm_size_t *size, natural_t *nesting_depth, vm_region_recurse_info_t info, mach_msg_type_number_t *infoCnt);
kern_return_t hook_vm_region_recurse_64(vm_map_read_t target_task, vm_address_t *address, vm_size_t *size, natural_t *nesting_depth, vm_region_recurse_info_t info, mach_msg_type_number_t *infoCnt) {
    os_log(hook_log, "[HOOK] vm_region_recurse_64: %u, %p, %p, %p, %p, %p", target_task, address, size, nesting_depth, info, infoCnt);
    return orig_vm_region_recurse_64(target_task, address, size, nesting_depth, info, infoCnt);
}


void doHookObjcMsgsend(void) {
    // fishhook
    //  hook mincore
    struct rebinding rebindings[1] = {
        {"objc_msgSend", (void *)hook_Objc_msgSend_fishhook, (void **)&orig_objc_msgSend},
        //{"mincore", (void *)hook_mincore, (void **)&orig_mincore},
        //{"vm_region_recurse_64", (void *)hook_vm_region_recurse_64, (void **)&orig_vm_region_recurse_64},
    };

    
    rebind_symbols(rebindings, 1);
}