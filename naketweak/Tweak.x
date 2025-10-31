#import <Foundation/Foundation.h>
#import "hookobjcMsgsend.h"
#import "hookcommon.h"
#import <rootless.h>


// 定义偏好设置的键
static NSString *const kPreferencePath = @"/var/mobile/Library/Preferences/com.rainl.nakePref.plist";
static NSString *const kPreferenceAppPath = @"/var/mobile/Library/Preferences/com.rainl.nake.apps.plist";
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

// 从plist文件加载配置
static NSDictionary* loadAppPreferences() {
    NSString *prefsPath = ROOT_PATH_NS(kPreferenceAppPath);
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:prefsPath];
    return prefs ?: @{};
}

// 检查全局监控是否启用
static BOOL isGlobalMonitoringEnabled() {
    NSDictionary *prefs = loadAppPreferences();
    NSNumber *globalSwitch = prefs[@"global_monitoring"];
    return globalSwitch ? [globalSwitch boolValue] : YES;  // 默认开启
}

// 检查应用是否被启用
static BOOL isAppEnabled(NSString *bundleId) {
    @try {
        if (!bundleId) return NO;  // 没有bundleId默认不启用
        
        // 首先检查全局开关
        if (!isGlobalMonitoringEnabled()) {
            NSLog(@"[nake] Global monitoring is disabled");
            return NO;
        }
        
        NSDictionary *prefs = loadAppPreferences();
        // NSLog(@"[nake] prefs : %@",prefs);

        NSString *key = [NSString stringWithFormat:@"app_switch_%@", bundleId];
        NSNumber *appSwitch = prefs[key];
        
        // 如果没有设置过，默认不启用（安全考虑）
        BOOL isEnabled = appSwitch ? [appSwitch boolValue] : NO;
        NSLog(@"[nake] App %@ switch state: %@", bundleId, isEnabled ? @"ENABLED" : @"DISABLED");
        
        return isEnabled;
        
    } @catch (NSException *exception) {
        NSLog(@"[nake] Error checking app enabled status for %@: %@", bundleId, exception);
        return NO;  // 出错时默认不启用
    }
}

// 设置变更通知回调
static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSLog(@"[nake] Preferences changed, reloading settings...");
    loadPreferences();
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSLog(@"[nake] Reloaded preferences for %@ - ObjcMsgSend: %d, Access: %d, Dlopen: %d", 
          bundleId, enableObjcMsgSendHook, enableAccessHook, enableDlopenHook);
}

%ctor {    
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSLog(@"[nake] Initializing tweak for app: %@", bundleId);
    
    if (!isAppEnabled(bundleId)) {
        NSLog(@"[nake] App %@ is disabled, skipping hook initialization", bundleId);
        return;
    }

    // 加载初始设置
    loadPreferences();

    NSLog(@"[nake] Hook preferences - ObjcMsgSend: %d, Access: %d, Dlopen: %d", 
          enableObjcMsgSendHook, enableAccessHook, enableDlopenHook);
    
    // 根据设置启用相应的hook
    if (enableObjcMsgSendHook) {
        NSLog(@"[nake] Enabling objc_msgSend hook");
        doHookObjcMsgsend();
    }
    
    if (enableAccessHook) {
        NSLog(@"[nake] Enabling access hook");
        hook_access();
    }
    
    if (enableDlopenHook) {
        NSLog(@"[nake] dlopen hook not implemented yet");
        // 需要实现dlopen的hook函数
        // hook_dlopen();
    }
    
    NSLog(@"[nake] Tweak initialization completed for %@", bundleId);
}