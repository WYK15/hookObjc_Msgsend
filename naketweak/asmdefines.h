
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
"stp x26, x27, [sp, #-16]!\n" \
"stp x24, x25, [sp, #-16]!\n" \
"stp x22, x23, [sp, #-16]!\n" \
"stp x20, x21, [sp, #-16]!\n" \
"stp x18, x19, [sp, #-16]!\n" \
"stp x16, x17, [sp, #-16]!\n" \
"stp x14, x15, [sp, #-16]!\n" \
"stp x12, x13, [sp, #-16]!\n" \
"stp x10, x11, [sp, #-16]!\n" \
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
"ldp x8, x9, [sp], #16\n" \
"ldp x10, x11, [sp], #16\n" \
"ldp x12, x13, [sp], #16\n" \
"ldp x14, x15, [sp], #16\n" \
"ldp x16, x17, [sp], #16\n" \
"ldp x18, x19, [sp], #16\n" \
"ldp x20, x21, [sp], #16\n" \
"ldp x22, x23, [sp], #16\n" \
"ldp x24, x25, [sp], #16\n" \
"ldp x26, x27, [sp], #16\n" );

#define saveLR() \
__asm volatile ( \
"stp x30, xzr, [sp, #-16]!\n" );  // 使用xzr填充，保持16字节对齐

#define loadLR() \
__asm volatile ( \
"ldp x30, xzr, [sp], #16\n" );    // 配对恢复，保持栈平衡

#define link(b, value) \
__asm volatile ("stp x8, lr, [sp, #-16]!\n"); \
__asm volatile ("sub sp, sp, #16\n"); \
call(b, value); \
__asm volatile ("add sp, sp, #16\n"); \
__asm volatile ("ldp x8, lr, [sp], #16\n");

#define ret() __asm volatile ("ret\n");