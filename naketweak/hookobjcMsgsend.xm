#include <pthread.h>
#include <substrate.h>
#include <objc/message.h>
#import "asmdefines.h"
#import "hookobjcMsgsend.h"
#import "fishhook/fishhook.h"

__unused static id (*orig_objc_msgSend)(id, SEL, ...);
void printSpecificParam_fish(id self, SEL _cmd, void* param1, void* param2)
{
    const char *cname = object_getClassName(self);
    const char * selector = sel_getName(_cmd);
    if (strncmp(cname, "_NSPlaceholder", 14) == 0 || strncmp(cname, "__NSPlaceholder", 15) == 0) {
        NSLog(@"[HOOK] selfclass is _NSPlaceholder*, classname: %s, method: %s", cname, selector);
        return;
    }

    if ( strcmp( selector, "isEqualToString:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, str: %@", self, selector, param1);
    } else if ( strcmp( selector, "fileExistsAtPath:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, path: %@", self, selector, param1);
    } else if ( strcmp( selector, "setObject:forKey:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, object: %@, key: %@", self, selector, param1, param2);
    } else if ( strcmp( selector, "dataUsingEncoding:" ) == 0 ){
        NSLog(@"[HOOK] class: %@, method: %s, encoding: %lu", self, selector, (NSUInteger)param1);
    } else if ( strcmp( selector, "objectForKey:" ) == 0 ){
        NSLog(@"[HOOK] class: %@, method: %s, key: %@", self, selector, param1);
    } else if ( strcmp( selector, "stringByAppendingString:" ) == 0 ){
        NSLog(@"[HOOK] class: %@, method: %s, self: %@, str2: %@", self, selector, self, param1);
    } else if ( strcmp( selector, "dataWithJSONObject:options:error:" ) == 0 ){
        NSLog(@"[HOOK] class: %@, method: %s, json: %@", self, selector, param1);
    } else if ( strcmp( selector, "stringWithUTF8String:" ) == 0 ){
        NSLog(@"[HOOK] class: %@, method: %s, utf8str: %s", self, selector, (char*)param1);
    } else if ( strcmp( selector, "appendFormat:" ) == 0 ){
        NSLog(@"[HOOK] class: %@, method: %s, format: %@", self, selector, param1);
    } else if ( strcmp( selector, "stringWithFormat:" ) == 0 ){
        NSLog(@"[HOOK] class: %@, method: %s, format: %@", self, selector, param1);
    } else if ( strcmp( selector, "dictionaryWithObjectsAndKeys:" ) == 0 ){
        NSLog(@"[HOOK] class: %@, method: %s, objects: %@", self, selector, param1);
    } else if ( strcmp( selector, "hasPrefix:" ) == 0 ){
        NSLog(@"[HOOK] class: %@, method: %s, prefix: %@", self, selector, param1);
    } else if ( strcmp( selector, "hasSuffix:" ) == 0 ){
        NSLog(@"[HOOK] class: %@, method: %s, suffix: %@", self, selector, param1);
    } else if ( strcmp( selector, "UTF8String" ) == 0 ){
        NSLog(@"[HOOK] class: %@, method: %s", self, selector);
    } else if ( strcmp( selector, "containsString:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, subStr: %@", self, selector, param1);
    } else if ( strcmp( selector, "setText:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, text: %@", self, selector, param1);
    } else if ( strcmp( selector, "objectForKeyedSubscript:" ) == 0 ){
        NSLog(@"[HOOK] class: %@, method: %s, key: %@", self, selector, param1);
    } else if ( strcmp( selector, "attributesOfItemAtPath:error:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, path: %@", self, selector, param1);
    } else if ( strcmp( selector, "initFileURLWithPath:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, path: %@", self, selector, param1);
    } else if ( strcmp( selector, "initWithFileURL:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, url: %@", self, selector, param1);
    } else if ( strcmp( selector, "initWithContentsOfURL:options:error:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, url: %@", self, selector, param1);
    } else if ( strcmp( selector, "valueForKey:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, key: %@", self, selector, param1);
    } else if ( strcmp( selector, "URLWithString:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, urlStr: %@", self, selector, param1);
    } else if ( strcmp( selector, "stringWithContentsOfFile:encoding:error:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, path: %@", self, selector, param1);
    } else if ( strcmp( selector, "stringWithContentsOfURL:encoding:error:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, url: %@", self, selector, param1);
    } else if ( strcmp( selector, "writeToFile:atomically:encoding:error:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, path: %@", self, selector, param1);
    } else if ( strcmp( selector, "writeToURL:atomically:encoding:error:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, url: %@", self, selector, param1);
    } else if ( strcmp( selector, "JSONString" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "JSONObjectWithData:options:error:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, data: %@", self, selector, param1);
    } else if ( strcmp( selector, "base64EncodedStringWithOptions:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "base64EncodedDataWithOptions:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "initWithBase64EncodedString:options:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, base64Str: %@", self, selector, param1);
    } else if ( strcmp( selector, "initWithBase64EncodedData:options:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, data: %@", self, selector, param1);
    } else if ( strcmp( selector, "MD5String" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "SHA256String" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "HMACWithAlgorithm:key:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, key: %@", self, selector, param2);
    } else if ( strcmp( selector, "substringFromIndex:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@, index: %lu", self, selector, self, (NSUInteger)param1);
    } else if ( strcmp( selector, "substringToIndex:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@, index: %lu", self, selector, self, (NSUInteger)param1);
    } else if ( strcmp( selector, "substringWithRange:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, location: %lu, length: %lu", self, selector, (NSUInteger)param1, (NSUInteger)param2);
    } else if ( strcmp( selector, "rangeOfString:" ) == 0) {
        // 这个打印日志太多了，根据条件打印
        //NSLog(@"[HOOK] class: %@, method: %s, self: %@, searchStr: %@", self, selector, self, param1);
    } else if ( strcmp( selector, "componentsSeparatedByString:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, separator: %@", self, selector, param1);
    } else if ( strcmp( selector, "stringByReplacingOccurrencesOfString:withString:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, target: %@, replacement: %@", self, selector, param1, param2);
    } else if ( strcmp( selector, "lowercaseString" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "uppercaseString" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "intValue" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "integerValue" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "floatValue" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "doubleValue" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "boolValue" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "arrayWithArray:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, array: %@", self, selector, param1);
    } else if ( strcmp( selector, "arrayWithObjects:count:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, count: %lu", self, selector, (NSUInteger)param2);
    } else if ( strcmp( selector, "addObject:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, object: %@", self, selector, param1);
    } else if ( strcmp( selector, "removeObject:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, object: %@", self, selector, param1);
    } else if ( strcmp( selector, "objectAtIndex:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, index: %lu", self, selector, (NSUInteger)param1);
    } else if ( strcmp( selector, "count" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "allKeys" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "allValues" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "removeObjectForKey:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, key: %@", self, selector, param1);
    } else if ( strcmp( selector, "removeAllObjects" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s", self, selector);
    } else if ( strcmp( selector, "length" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "characterAtIndex:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, index: %lu", self, selector, (NSUInteger)param1);
    } else if ( strcmp( selector, "init" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s", self, selector);
    } else if ( strcmp( selector, "alloc" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s", self, selector);
    } else if ( strcmp( selector, "new" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s", self, selector);
    } else if ( strcmp( selector, "copy" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "mutableCopy" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "description" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "debugDescription" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "isEqual:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@, other: %@", self, selector, self, param1);
    } else if ( strcmp( selector, "hash" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, self: %@", self, selector, self);
    } else if ( strcmp( selector, "isKindOfClass:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, class: %@", self, selector, param1);
    } else if ( strcmp( selector, "isMemberOfClass:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, class: %@", self, selector, param1);
    } else if ( strcmp( selector, "respondsToSelector:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, selector: %s", self, selector, sel_getName((SEL)param1));
    } else if ( strcmp( selector, "performSelector:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, selector: %s", self, selector, sel_getName((SEL)param1));
    } else if ( strcmp( selector, "performSelector:withObject:" ) == 0) {
        NSLog(@"[HOOK] class: %@, method: %s, selector: %s, object: %@", self, selector, sel_getName((SEL)param1), param2);
    } else {
        const char * className = object_getClassName(self);
        NSLog(@"[HOOK] class: %s, method: %s", className, selector);
    }
}

static int strlen_SOLO(const char *str) {
    int len = 0;
    while (*str++) {
        len++;
    }
    return len;
}


static const char* blackMethod[] = {"dealloc", "_xref_dispose"};
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
            //NSLog(@"blackMethod detected : %s",blackMethodName);
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


void doHookObjcMsgsend(void) {
    // fishhook
    struct rebinding rebindings[1] = {
        {"objc_msgSend", (void *)hook_Objc_msgSend_fishhook, (void **)&orig_objc_msgSend},
    };
    rebind_symbols(rebindings, 1);
}