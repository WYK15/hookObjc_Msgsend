#import <Foundation/Foundation.h>

#ifndef HOOKCOMMON_H
#define HOOKCOMMON_H

void hook_access(void);
void hook_dlopen(void);
void hook_dlsym(void);

#endif /* HOOKCOMMON_H */