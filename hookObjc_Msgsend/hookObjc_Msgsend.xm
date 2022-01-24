// See http://iphonedevwiki.net/index.php/Logos

// 参考 https://github.com/cxr0715/hook_objc_msgSend

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

//hook使用，线程私有变量
//每个线程都可以通过 pthread_setspecific 和 pthread_getspecific 获取和设置 key值 对应的值，但是每个线程获取的值不同
static pthread_key_t _thread_key;


// 用户保存每个线程的调用栈的lr
// 例如，当A方法利用blr调用B方法时,将A方法的blr的下一条指令地址（即PC+4回写到X30）入栈，作为返回地址
// 每个线程均维护一个这样的栈，结合上面的pthread_key_t即可实现，不同线程用相同的key值获取不同的value值
typedef struct thread_call_stack {

    uintptr_t *lrArrs;
    int index;
    
    void init()
    {
        lrArrs = new uintptr_t[100]; //假设本线程有100层调用栈
        index = 1;
    }

    void push(uintptr_t p)
    {
        lrArrs[index++] = p; //入栈
    }

    uintptr_t pop()
    {
        return lrArrs[--index]; //出栈
    }
} thread_call_stack;


__unused static id (*orig_objc_msgSend)(id, SEL, ...);

//replacement objc_msgSend (arm64)
// https://blog.nelhage.com/2010/10/amd64-and-va_arg/
// http://infocenter.arm.com/help/topic/com.arm.doc.ihi0055b/IHI0055B_aapcs64.pdf
// https://developer.apple.com/library/ios/documentation/Xcode/Conceptual/iPhoneOSABIReference/Articles/ARM64FunctionCallingConventions.html
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

//stp q6, q7, [sp, #-32]! ，偏移寻址的标记后多了一个 !，在执行完上文的 stp 指令后，还会使 sp 寄存器也产生偏移。

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

/* inline hook的before
 //inline hook不能使用直接或间接的调用OC方法
 // 注：如果是使用inline hook，那么此方法内调用的函数，不能是OC函数，即不能再经过objc_msgSend，原因如下：
 // inline hook修改了原始的函数，br跳转到了myhook。如果myhook中再次回调原始函数的起始处，会形成循环。
 // 在myHook中使用blr跳转到origin方法中，origin又br跳转到myHook中，如此便形成循环，所以打破循环，在myhook中不能调用经过原始函数
 // 修改方式 : 不直接调用oc方法，而是汇编设置好 x0 - x8寄存器，直接blr跳转到orig_objc_msgSend
 //fishhook的方式可以在此函数中调用OC方法，因为fishhook并没有修改原始的objc_msgSend函数
 

 */
// 此方法不能接收self,其中不能直接或者调用OC方法，NSlog也不可以
void before_objc_msgSend_inline(SEL _cmd, uintptr_t lr)
{
    thread_call_stack *cs = (thread_call_stack *) pthread_getspecific(_thread_key);
    if (cs == NULL) {
        cs = (thread_call_stack *) malloc(sizeof(thread_call_stack));
        cs->init();
        pthread_setspecific(_thread_key, cs);
    }
    cs->push(lr);
    // 此方法中暂只能使用C方法,使用OC方法可能会导致寄存器异常导致崩溃，经测试，发生在相同方法调用相同方法时崩溃
    // NSlog不能用
//    const char * className = object_getClassName(self);
    const char * selector = sel_getName(_cmd);
//    if ( strcmp( selector, "isEqualToString:" ) == 0) {
//        //NSLog(@"class : %s, methodname : %s, param1 : %@",className,selector,param1);
//        printf("class : %s, methodname : %s",className,selector);
//    }
//    else if ( strcmp( selector, "fileExistsAtPath:" ) == 0) {
//        printf("class : %s, methodname : %s",className,selector);
//        //NSLog(@"class : %s, methodname : %s, param1 : %@",className,selector,param1);
//    }
//    else if ( strcmp( selector, "setObject:forKey:" ) == 0) {
//        printf("class : %s, methodname : %s",className,selector);
//        //NSLog(@"class : %s, methodname : %s, object : %@, key : %@",className,selector,param1,param2);
//    }else if ( strcmp( selector, "dataUsingEncoding:" ) == 0 ){
//        printf("class : %s, methodname : %s",className,selector);
//        //NSLog(@"class : %@, methodname : %s",self,selector);
//    } else {
//        printf("class : %s, methodname : %s",className,selector);
//        //NSLog(@"class : %s, methodname : %s",className,selector);
//    }
    
    //push_call_record(self, object_getClass(self), _cmd, lr);
    //NSLog(@"before msgsend!!");
    printf("before msgsend!!, selector : %s",selector);
    //exit(0);
    //return;
}


uintptr_t after_objc_msgSend_inline()
{
    thread_call_stack *cs = (thread_call_stack *) pthread_getspecific(_thread_key);
    return cs->pop();
}


//self 参数，不必要时，需要去掉，否则可能会崩溃。
//不会崩溃的修改方式为：
void printSpecificParam_fish( SEL _cmd, uintptr_t param1, uintptr_t param2,uintptr_t lr)
//void printSpecificParam_fish(id self, SEL _cmd, uintptr_t param1, uintptr_t param2,uintptr_t lr)
{
    // 此方法中暂只能使用C方法,使用OC方法可能会导致寄存器异常导致崩溃，经测试，发生在相同方法调用相同方法时崩溃
    // NSlog可以用
    //const char * className = object_getClassName(self);
    const char * selector = sel_getName(_cmd);
    //NSLog(@"class : %s, methodname : %s",className,selector);
    if ( strcmp( selector, "isEqualToString:" ) == 0) {
        NSLog(@"methodname : %s, param1 : %@",selector,param1);
        //NSLog(@"class : %s, methodname : %s, param1 : %@",className,selector,param1);
    }
    else if ( strcmp( selector, "fileExistsAtPath:" ) == 0) {
        NSLog(@"methodname : %s, param1 : %@",selector,param1);
        //NSLog(@"class : %s, methodname : %s, param1 : %@",className,selector,param1);
    }
    else if ( strcmp( selector, "setObject:forKey:" ) == 0) {
        NSLog(@"json : %@, methodname : %s, object : %@, key : %@",@"notAvailable",selector,param1,param2);
        //NSLog(@"json : %@, methodname : %s, object : %@, key : %@",self,selector,param1,param2);
    }else if ( strcmp( selector, "dataUsingEncoding:" ) == 0 ){
        NSLog(@"class : %@, methodname : %s",@"notAvailable",selector);
        //NSLog(@"class : %@, methodname : %s",self,selector);
    }else if ( strcmp( selector, "objectForKey:" ) == 0 ){
        NSLog(@"methodname : %s, key : %@",selector,param1);
        //NSLog(@"json : %@, methodname : %s, key : %@",self,selector,param1);
    } else if ( strcmp( selector, "stringByAppendingString:" ) == 0 ){
        NSLog(@"methodname : %s,str2 : %@",selector,param1);
        //NSLog(@"str1 : %@, methodname : %s,str2 : %@",self,selector,param1);
    } else if ( strcmp( selector, "dataWithJSONObject:options:error:" ) == 0 ){
        NSLog(@"methodname : %s,json : %@",selector,param1);
       // NSLog(@"class : %s, methodname : %s,json : %@",className,selector,param1);
    } else if ( strcmp( selector, "stringWithUTF8String:" ) == 0 ){
        NSLog(@"methodname : %s,utf8str : %s",selector,param1);
       // NSLog(@"class : %s, methodname : %s,utf8str : %s",className,selector,param1);
    } else if ( strcmp( selector, "appendFormat:" ) == 0 ){
        NSLog(@"methodname : %s,format : %@",selector,param1);
        //NSLog(@"class : %s, methodname : %s,format : %@",className,selector,param1);
    } else if ( strcmp( selector, "dictionaryWithObjectsAndKeys:" ) == 0 ){
        //NSLog(@"class : %s, methodname : %s,object : %@, keys : %@",className,selector,param1,param2);
    } else if ( strcmp( selector, "hasPrefix:" ) == 0 ){
        NSLog(@"methodname : %s,prefix : %@",selector,param1);
        //NSLog(@"class : %s, methodname : %s,prefix : %@",className,selector,param1);
    } else {
        NSLog(@"methodname : %s",selector);
        //NSLog(@"class : %s, methodname : %s",className,selector);
    }
}


 void before_objc_msgSend_fishhook( SEL _cmd, uintptr_t param1, uintptr_t param2,uintptr_t lr)
//void before_objc_msgSend_fishhook(id self, SEL _cmd, uintptr_t param1, uintptr_t param2, uintptr_t lr)
{
    //if (self) {
        printSpecificParam_fish(_cmd, param1, param2,lr);
        //printSpecificParam_fish(self, _cmd, param1, param2,lr);
    //}
    
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

// inline hook的myhook
// TODO，现在只实现了在objc_msgSend方法前hook
__attribute__((__naked__))
static void hook_Objc_msgSend_inline() {

    // before之前保存objc_msgSend的参数
    save()
    
    //设置before_objc_msgSend_inline的入参，不能传入x0。因为x0会增加引用计数，导致调用OC的objc_retain，造成循环
    __asm volatile ("mov x0, x1\n");
    __asm volatile ("mov x1, lr\n");

    call(blr, &before_objc_msgSend_inline)
    
    // 恢复objc_msgSend参数，并执行
    load()
    
    // Call through to the original objc_msgSend.
    // blr会把当前PC+4回写到X30
    call(blr, orig_objc_msgSend)

    // 保存objc_msgSend的执行结果
    save()
    
    // after_objc_msgSend的返回参数即为本线程的最顶层的lr出栈
    call(blr, &after_objc_msgSend_inline)
    
    // restore lr
    __asm volatile ("mov lr, x0\n");
    
    //加载orig_objc_msgSend结果
    load()

    ret()
}


//ok - fishhook
__attribute__((__naked__))
static void hook_Objc_msgSend_fishhook() {
    // before之前保存objc_msgSend的参数
    save()
    
    __asm volatile ("mov x0, x1\n");
    __asm volatile ("mov x1, x2\n");
    __asm volatile ("mov x2, x3\n");
    __asm volatile ("mov x3, lr\n");

    call(blr, &before_objc_msgSend_fishhook)
    
    // 恢复objc_msgSend参数，并执行
    load()
    
    // Call through to the original objc_msgSend.
    // blr会把当前PC+4回写到X30
    call(blr, orig_objc_msgSend)

    // 保存objc_msgSend的执行结果
    save()
    
    // after_objc_msgSend的返回参数即为本线程的最顶层的lr出栈
    call(blr, &after_objc_msgSend_fishhook)
    
    // restore lr
    __asm volatile ("mov lr, x0\n");
    
    //加载orig_objc_msgSend结果
    load()

    ret()
}

%ctor
{
    // 1. 使用 作者的 代码，fishhook，成功
    //smCallTraceStart();
    
    // 2. 自己研究，inline hook，会修改objc_msgSend原始方法的前3条指令
    // 函数中不能调用OC函数
//    pthread_key_create(&_thread_key, &release_stack);
//    MSHookFunction((void*)&objc_msgSend,(void*)&hook_Objc_msgSend_inline,(void**)&orig_objc_msgSend);

    // 3. 自己研究
    // 借鉴作者代码，使用线程私有变量pthread_key_t，保证多线程安全，成功
    // hook中只能使用C函数
    // fishhook
    pthread_key_create(&_thread_key, &release_stack);
    rebind_symbols((struct rebinding[1]){
        {"objc_msgSend", (void *)hook_Objc_msgSend_fishhook, (void **)&orig_objc_msgSend},
    }, 1);
    
}
