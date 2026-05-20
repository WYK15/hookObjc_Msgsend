#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#ifndef HOOKNET_H
#define HOOKNET_H

void hook_SSLCreateContext(void);
void hook_SSLSetConnection(void);
void hook_SSLWrite(void);
void hook_SSLRead(void);
void hook_inet_pton(void);

#endif /* HOOKNET_H */
