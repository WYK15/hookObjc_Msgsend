#line 1 "/Users/wangyankun/Documents/hooks/hookObjc_Msgsend/hookObjc_Msgsend/hookObjc_Msgsend.xm"




#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#include <objc/message.h>
#include <substrate.h>
#include <stdio.h>
#include <pthread.h>

#import "fishhook/fishhook.h"

#import "TSHookMSG.h"

#import <sys/sysctl.h>



static pthread_key_t _thread_key;





typedef struct thread_call_stack {

    uintptr_t *lrArrs;
    int index;
    
    void init()
    {
        lrArrs = new uintptr_t[100]; 
        index = 1;
    }

    void push(uintptr_t p)
    {
        lrArrs[index++] = p; 
    }

    uintptr_t pop()
    {
        return lrArrs[--index]; 
    }
} thread_call_stack;


__unused static id (*orig_objc_msgSend)(id, SEL, ...);





#define call(b, value) \
__asm volatile ("stp x8, x9, [sp, #-16]!\n"); \
__asm volatile ("mov x12, %0\n" :: "r"(value)); \
__asm volatile ("ldp x8, x9, [sp], #16\n"); \
__asm volatile (#b " x12\n");

#define save() \
__asm volatile ( \
"stp x8, x9, [sp, #-16]!\n" \
"stp x6, x7, [sp, #-16]!\n" \
"stp x4, x5, [sp, #-16]!\n" \
"stp x2, x3, [sp, #-16]!\n" \
"stp x0, x1, [sp, #-16]!\n" \
"stp q6, q7, [sp, #-32]!\n" \
"stp q4, q5, [sp, #-32]!\n" \
"stp q2, q3, [sp, #-32]!\n" \
"stp q0, q1, [sp, #-32]!\n" );



#define load() \
__asm volatile ( \
"ldp q0, q1, [sp], #32\n" \
"ldp q2, q3, [sp], #32\n" \
"ldp q4, q5, [sp], #32\n" \
"ldp q6, q7, [sp], #32\n" \
"ldp x0, x1, [sp], #16\n" \
"ldp x2, x3, [sp], #16\n" \
"ldp x4, x5, [sp], #16\n" \
"ldp x6, x7, [sp], #16\n" \
"ldp x8, x9, [sp], #16\n" );

#define link(b, value) \
__asm volatile ("stp x8, lr, [sp, #-16]!\n"); \
__asm volatile ("sub sp, sp, #16\n"); \
call(b, value); \
__asm volatile ("add sp, sp, #16\n"); \
__asm volatile ("ldp x8, lr, [sp], #16\n");

#define ret() __asm volatile ("ret\n");












void before_objc_msgSend_inline(SEL _cmd, uintptr_t lr)
{
    thread_call_stack *cs = (thread_call_stack *) pthread_getspecific(_thread_key);
    if (cs == NULL) {
        cs = (thread_call_stack *) malloc(sizeof(thread_call_stack));
        cs->init();
        pthread_setspecific(_thread_key, cs);
    }
    cs->push(lr);
    
    

    const char * selector = sel_getName(_cmd);


















    
    
    
    printf("before msgsend!!, selector : %s",selector);
    
    
}


uintptr_t after_objc_msgSend_inline()
{
    thread_call_stack *cs = (thread_call_stack *) pthread_getspecific(_thread_key);
    return cs->pop();
}




void printSpecificParam_fish( SEL _cmd, uintptr_t param1, uintptr_t param2,uintptr_t lr)

{
    
    
    
    const char * selector = sel_getName(_cmd);
    
    if ( strcmp( selector, "isEqualToString:" ) == 0) {
        NSLog(@"methodname : %s, param1 : %@",selector,param1);
        
    }
    else if ( strcmp( selector, "fileExistsAtPath:" ) == 0) {
        NSLog(@"methodname : %s, param1 : %@",selector,param1);
        
    }
    else if ( strcmp( selector, "setObject:forKey:" ) == 0) {
        NSLog(@"json : %@, methodname : %s, object : %@, key : %@",@"notAvailable",selector,param1,param2);
        
    }else if ( strcmp( selector, "dataUsingEncoding:" ) == 0 ){
        NSLog(@"class : %@, methodname : %s",@"notAvailable",selector);
        
    }else if ( strcmp( selector, "objectForKey:" ) == 0 ){
        NSLog(@"methodname : %s, key : %@",selector,param1);
        
    } else if ( strcmp( selector, "stringByAppendingString:" ) == 0 ){
        NSLog(@"methodname : %s,str2 : %@",selector,param1);
        
    } else if ( strcmp( selector, "dataWithJSONObject:options:error:" ) == 0 ){
        NSLog(@"methodname : %s,json : %@",selector,param1);
       
    } else if ( strcmp( selector, "stringWithUTF8String:" ) == 0 ){
        NSLog(@"methodname : %s,utf8str : %s",selector,param1);
       
    } else if ( strcmp( selector, "appendFormat:" ) == 0 ){
        NSLog(@"methodname : %s,format : %@",selector,param1);
        
    } else if ( strcmp( selector, "dictionaryWithObjectsAndKeys:" ) == 0 ){
        
    } else if ( strcmp( selector, "hasPrefix:" ) == 0 ){
        NSLog(@"methodname : %s,prefix : %@",selector,param1);
        
    } else {
        NSLog(@"methodname : %s",selector);
        
    }
}


 void before_objc_msgSend_fishhook( SEL _cmd, uintptr_t param1, uintptr_t param2,uintptr_t lr)

{
    
        printSpecificParam_fish(_cmd, param1, param2,lr);
        
    
    
    thread_call_stack *cs = (thread_call_stack *) pthread_getspecific(_thread_key);
    if (cs == NULL) {
        cs = (thread_call_stack *) malloc(sizeof(thread_call_stack));
        cs->init();
        pthread_setspecific(_thread_key, cs);
    }
    cs->push(lr);
    
    NSLog(@"before msgsend!!");
}


uintptr_t after_objc_msgSend_fishhook()
{
    NSLog(@"after msgsend!!");
    thread_call_stack *cs = (thread_call_stack *) pthread_getspecific(_thread_key);
    return cs->pop();
}


static void release_stack(void *ptr) {
    thread_call_stack *cs = (thread_call_stack *) ptr;
    if (!cs) return;
    free(cs);
}



__attribute__((__naked__))
static void hook_Objc_msgSend_inline() {

    
    save()
    
    
    __asm volatile ("mov x0, x1\n");
    __asm volatile ("mov x1, lr\n");

    call(blr, &before_objc_msgSend_inline)
    
    
    load()
    
    
    
    call(blr, orig_objc_msgSend)

    
    save()
    
    
    call(blr, &after_objc_msgSend_inline)
    
    
    __asm volatile ("mov lr, x0\n");
    
    
    load()

    ret()
}



__attribute__((__naked__))
static void hook_Objc_msgSend_fishhook() {
    
    save()
    
    __asm volatile ("mov x0, x1\n");
    __asm volatile ("mov x1, x2\n");
    __asm volatile ("mov x2, x3\n");
    __asm volatile ("mov x3, lr\n");

    call(blr, &before_objc_msgSend_fishhook)
    
    
    load()
    
    
    
    call(blr, orig_objc_msgSend)

    
    save()
    
    
    call(blr, &after_objc_msgSend_fishhook)
    
    
    __asm volatile ("mov lr, x0\n");
    
    
    load()

    ret()
}

static __attribute__((constructor)) void _logosLocalCtor_950a4152(int __unused argc, char __unused **argv, char __unused **envp)
{
    
    
    
    
    



    
    
    
    
    pthread_key_create(&_thread_key, &release_stack);
    rebind_symbols((struct rebinding[1]){
        {"objc_msgSend", (void *)hook_Objc_msgSend_fishhook, (void **)&orig_objc_msgSend},
    }, 1);
    
}
