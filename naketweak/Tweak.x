#import <Foundation/Foundation.h>
#import "hookobjcMsgsend.h"
#import "hookcommon.h"
#import <rootless.h>


// 定义偏好设置的键
static NSString *const kPreferencePath = @"/var/mobile/Library/Preferences/com.rainl.nakePref.plist";
static NSString *const kEnableObjcMsgSendHook = @"EnableObjcMsgSendHook";
static NSString *const kEnableAccessHook = @"EnableAccessHook";
static NSString *const kEnableDlopenHook = @"EnableDlopenHook";

// 默认设置
static BOOL enableObjcMsgSendHook = YES;
static BOOL enableAccessHook = YES;
static BOOL enableDlopenHook = YES;

// 加载偏好设置
static void loadPreferences() {
    NSString *nakedPref = ROOT_PATH_NS(kPreferencePath);
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:nakedPref];
    
    if (prefs) {
        enableObjcMsgSendHook = [prefs[kEnableObjcMsgSendHook] boolValue];
        enableAccessHook = [prefs[kEnableAccessHook] boolValue];
        enableDlopenHook = [prefs[kEnableDlopenHook] boolValue];
    }
}

// 设置变更通知回调
static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSLog(@"prefsChanged!!!");
    loadPreferences();
}

%ctor {    
    // 加载初始设置
    loadPreferences();

    //
    NSLog(@"enableObjcMsgSendHook : %d, enableAccessHook : %d, enableDlopenHook : %d", enableObjcMsgSendHook, enableAccessHook, enableDlopenHook);
    
    
    // 根据设置启用相应的hook
    if (enableObjcMsgSendHook) {
        doHookObjcMsgsend();
    }
    
    if (enableAccessHook) {
        hook_access();
    }
    
    if (enableDlopenHook) {
        // 需要实现dlopen的hook函数
        // hook_dlopen();
    }
}