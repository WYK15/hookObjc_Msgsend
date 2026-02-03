#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#ifndef STDSTRINGHOOK_H
#define STDSTRINGHOOK_H

#ifdef __cplusplus
extern "C" {
#endif

extern void hook_stdstring_appendLen(void);
extern void hook_stdstring_append(void);
extern void hook_stdstring_assign(void);

#ifdef __cplusplus
}
#endif

#endif /* STDSTRINGHOOK_H */
