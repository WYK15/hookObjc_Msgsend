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
static BOOL enableRes9InitHook = YES;
static BOOL enableClassGetClassMethodHook = NO;
static BOOL enableSelRegisterNameHook = NO;
static BOOL enableCFNetworkCopySystemProxySettingsHook = NO;

// 新增的 Hook 开关（按类别分组）
static BOOL enableSystemFunctionsHook = NO;  // 文件和系统函数
static BOOL enableCryptoFunctionsHook = NO;  // 加密函数
static BOOL enableHostInfoFunctionsHook = NO;  // 主机信息函数
static BOOL enableCFStringFunctionsHook = NO;  // CoreFoundation 字符串函数
static BOOL enableCFURLFunctionsHook = NO;  // CoreFoundation URL 函数
static BOOL enableTimeFunctionsHook = NO;  // 时间函数
static BOOL enableKeychainFunctionsHook = NO;  // Keychain 函数

// 从plist文件加载配置（统一使用一个文件）
static NSDictionary* loadPreferences() {
    NSString *prefsPath = ROOT_PATH_NS(kPreferencePath);
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:prefsPath];
    return prefs ?: @{};
}

// 加载Hook设置
static void loadHookSettings() {
    NSDictionary *prefs = loadPreferences();
    
    if (prefs) {
        enableObjcMsgSendHook = [prefs[kEnableObjcMsgSendHook] boolValue];
        enableAccessHook = [prefs[kEnableAccessHook] boolValue];
        enableDlopenHook = [prefs[kEnableDlopenHook] boolValue];
        enableRes9InitHook = [prefs[@"enableRes9Init"] boolValue];
        enableClassGetClassMethodHook = [prefs[@"enableClassGetClassMethod"] boolValue];
        enableSelRegisterNameHook = [prefs[@"enableSelRegisterName"] boolValue];
        enableCFNetworkCopySystemProxySettingsHook = [prefs[@"enableCFNetworkCopySystemProxySettings"] boolValue];
        
        // 新增的 Hook 开关配置读取
        enableSystemFunctionsHook = [prefs[@"enableSystemFunctions"] boolValue];
        enableCryptoFunctionsHook = [prefs[@"enableCryptoFunctions"] boolValue];
        enableHostInfoFunctionsHook = [prefs[@"enableHostInfoFunctions"] boolValue];
        enableCFStringFunctionsHook = [prefs[@"enableCFStringFunctions"] boolValue];
        enableCFURLFunctionsHook = [prefs[@"enableCFURLFunctions"] boolValue];
        enableTimeFunctionsHook = [prefs[@"enableTimeFunctions"] boolValue];
        enableKeychainFunctionsHook = [prefs[@"enableKeychainFunctions"] boolValue];
    }
}

// 检查全局监控是否启用
static BOOL isGlobalMonitoringEnabled() {
    NSDictionary *prefs = loadPreferences();
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
        
        NSDictionary *prefs = loadPreferences();
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
    loadHookSettings();
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
    loadHookSettings();

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
        NSLog(@"[nake] Enabling dlopen and dlsym hooks");
        hook_dlopen();
        hook_dlsym();
    }
    
    if (enableRes9InitHook) {
        NSLog(@"[nake] Enabling res9 init hook");
        hook_res_9_init();
    }
    
    if (enableClassGetClassMethodHook) {
        NSLog(@"[nake] Enabling class_getClassMethod hook");
        hook_class_getClassMethod();
    }
    
    if (enableSelRegisterNameHook) {
        NSLog(@"[nake] Enabling sel_registerName hook");
        hook_sel_registerName();
    }
    
    if (enableCFNetworkCopySystemProxySettingsHook) {
        NSLog(@"[nake] Enabling CFNetworkCopySystemProxySettings hook");
        hook_CFNetworkCopySystemProxySettings();
    }
    
    // 新增的 Hook 初始化
    if (enableSystemFunctionsHook) {
        NSLog(@"[nake] Enabling system functions hook");
        hook_fopen();
        hook_getenv();
        hook_getifaddrs();
        hook_stat();
        hook_sysctl();
        hook_sysctlbyname();
        hook_uname();
        hook_isatty();
        hook_open();
        hook_opendir();
        hook_read();
    }
    
    if (enableCryptoFunctionsHook) {
        NSLog(@"[nake] Enabling crypto functions hook");
        hook_CC_SHA256();
    }
    
    if (enableHostInfoFunctionsHook) {
        NSLog(@"[nake] Enabling host info functions hook");
        hook_host_info();
        hook_host_statistics64();
    }
    
    if (enableCFStringFunctionsHook) {
        NSLog(@"[nake] Enabling CFString functions hook");
        hook_CFStringCreateCopy();
        hook_CFStringCreateWithCString();
        hook_CFStringCreateWithFileSystemRepresentation();
        hook_CFStringCreateWithFormat();
    }
    
    if (enableCFURLFunctionsHook) {
        NSLog(@"[nake] Enabling CFURL functions hook");
        hook_CFURLCreateWithFileSystemPath();
        hook_CFURLCreateWithString();
    }
    
    if (enableTimeFunctionsHook) {
        NSLog(@"[nake] Enabling time functions hook");
        hook_CACurrentMediaTime();
    }
    
    if (enableKeychainFunctionsHook) {
        NSLog(@"[nake] Enabling keychain functions hook");
        hook_SecItemAdd();
        hook_SecItemUpdate();
        hook_SecItemDelete();
        hook_SecItemCopyMatching();
    }
    
    NSLog(@"[nake] Tweak initialization completed for %@", bundleId);
}