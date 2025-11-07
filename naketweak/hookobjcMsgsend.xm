#include <pthread.h>
#include <substrate.h>
#include <objc/message.h>
#import "asmdefines.h"
#import "hookobjcMsgsend.h"
#import "fishhook/fishhook.h"

__unused static id (*orig_objc_msgSend)(id, SEL, ...);
void printSpecificParam_fish(id self, SEL _cmd, void* param1, void* param2)
{
    //const char * className = object_getClassName(self);
    const char * selector = sel_getName(_cmd);
    //NSLog(@"class : %s, methodname : %s",className,selector);
    if ( strcmp( selector, "isEqualToString:" ) == 0) {
        NSLog(@"[ENABLED] methodname : %s, self : %@, param1 : %@",selector,self, param1);
    } else if ( strcmp( selector, "fileExistsAtPath:" ) == 0) {
        NSLog(@"[ENABLED] methodname : %s, param1 : %@",selector,param1);
    } else if ( strcmp( selector, "setObject:forKey:" ) == 0) {
        NSLog(@"[ENABLED] json : %@, methodname : %s, object : %@, key : %@",self, selector,param1,param2);
    } else if ( strcmp( selector, "dataUsingEncoding:" ) == 0 ){
        NSLog(@"[ENABLED] self : %@, methodname : %s",self,selector);
    } else if ( strcmp( selector, "objectForKey:" ) == 0 ){
        NSLog(@"[ENABLED] self : %@, methodname : %s, key : %@",self, selector,param1);
    } else if ( strcmp( selector, "stringByAppendingString:" ) == 0 ){
        NSLog(@"[ENABLED] self : %@, methodname : %s,str2 : %@",self, selector,param1);
    } else if ( strcmp( selector, "dataWithJSONObject:options:error:" ) == 0 ){
        NSLog(@"[ENABLED] methodname : %s,json : %@",selector,param1);
    } else if ( strcmp( selector, "stringWithUTF8String:" ) == 0 ){
        NSLog(@"[ENABLED] methodname : %s,utf8str : %s",selector,(char*)param1);
    } else if ( strcmp( selector, "appendFormat:" ) == 0 ){
        NSLog(@"[ENABLED] self : %@, methodname : %s,format : %@",self, selector,param1);
    } else if ( strcmp( selector, "dictionaryWithObjectsAndKeys:" ) == 0 ){
        //NSLog(@"class : %s, methodname : %s,object : %@, keys : %@",className,selector,param1,param2);
    } else if ( strcmp( selector, "hasPrefix:" ) == 0 ){
        NSLog(@"[ENABLED] self : %@, methodname : %s,prefix : %@",self, selector,param1);
    } else if ( strcmp( selector, "UTF8String" ) == 0 ){
        NSLog(@"[ENABLED] self : %@, methodname : %s",self, selector);
    } else if ( strcmp( selector, "containsString:" ) == 0) {
        NSLog(@"[ENABLED] self : %@, methodname : %s, subStr : %@",self, selector,param1);
    } else if ( strcmp( selector, "setText:" ) == 0) {
        NSLog(@"[ENABLED] self : %@, methodname : %s, text : %@",self, selector,param1);
    } else {
        NSLog(@"[ENABLED] methodname : %s",selector);
        //NSLog(@"class : %s, methodname : %s",className,selector);
    }
}

static int strlen_SOLO(const char *str) {
    int len = 0;
    while (*str++) {
        len++;
    }
    return len;
}


//ok - fishhook
__attribute__((__naked__))
static void hook_Objc_msgSend_fishhook() {
    // before之前保存objc_msgSend的参数
    saveLR()
    save()

    call(blr, &printSpecificParam_fish)
   
    //__asm volatile ("1:\n");
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