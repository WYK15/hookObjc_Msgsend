#import <Foundation/Foundation.h>
#import "hookobjcMsgsend.h"
#import "hookcommon.h"
#import <rootless.h>
#import "hookCrypt.h"
#import "stdstringhook.h"


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
// 系统函数独立开关
static BOOL enableFopenHook = NO;
static BOOL enableGetenvHook = NO;
static BOOL enableGetifaddrsHook = NO;
static BOOL enableStatHook = NO;
static BOOL enableStatfsHook = NO;
static BOOL enableSysctlHook = NO;
static BOOL enableSysctlbynameHook = NO;
static BOOL enableUnameHook = NO;
static BOOL enableIsattyHook = NO;
static BOOL enableOpendirHook = NO;
static BOOL enableReadHook = NO;
static BOOL enableDyldImageCountHook = NO;
static BOOL enableDyldGetImageVmaddrSlideHook = NO;
static BOOL enableDyldGetImageNameHook = NO;

// 其他类别的 Hook 开关
static BOOL enableCryptoFunctionsHook = NO;  // 加密函数
static BOOL enableHostInfoFunctionsHook = NO;  // 主机信息函数
static BOOL enableHostStatisticsHook = YES;  // host_statistics 函数
static BOOL enableCFStringFunctionsHook = NO;  // CoreFoundation 字符串函数
static BOOL enableCFURLFunctionsHook = NO;  // CoreFoundation URL 函数
static BOOL enableTimeFunctionsHook = NO;  // 时间函数
static BOOL enableKeychainFunctionsHook = NO;  // Keychain 函数

// hookCrypt 开关
static BOOL enableCCCryptHook = NO;
static BOOL enableCCCryptorCreateWithModeHook = NO;
static BOOL enableCCCryptorCreateHook = NO;
static BOOL enableCCCryptorUpdateHook = NO;
static BOOL enableCCCryptorFinalHook = NO;

// stdstringhook 开关
static BOOL enableStdstringAppendLenHook = NO;
static BOOL enableStdstringAppendHook = NO;
static BOOL enableStdstringAssignHook = NO;

// 新增系统函数开关
static BOOL enableGettimeofdayHook = NO;
static BOOL enableGetpagesizeHook = NO;
static BOOL enableCNCopyCurrentNetworkInfoHook = NO;
static BOOL enableCNCopySupportedInterfacesHook = NO;
static BOOL enableCCSHA1UpdateHook = NO;

// 新增 Hook 开关
static BOOL enableDladdrHook = YES;
static BOOL enableFaccessatHook = YES;
static BOOL enableGetpidHook = YES;
static BOOL enableGetppidHook = YES;
static BOOL enableGetsectiondataHook = YES;
static BOOL enableIoctlHook = YES;
static BOOL enableSnprintfHook = YES;
static BOOL enableRandHook = YES;
static BOOL enableReaddirHook = YES;
static BOOL enableRmdirHook = YES;
static BOOL enableMkdirHook = YES;
static BOOL enableSocketHook = YES;
static BOOL enableSrandHook = YES;
static BOOL enableStrcmpHook = YES;
static BOOL enableStrnstrHook = YES;
static BOOL enableSysconfHook = YES;
static BOOL enableTimeHook = YES;
static BOOL enableStrcasestrHook = YES;
static BOOL enableSprintfHook = YES;
static BOOL enableFstatHook = YES;
static BOOL enableFstatatHook = YES;
static BOOL enableFreadHook = YES;
static BOOL enableOpenatHook = YES;
static BOOL enablePopenHook = YES;

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
        
        // 系统函数独立开关配置读取
        enableFopenHook = [prefs[@"enableFopen"] boolValue];
        enableGetenvHook = [prefs[@"enableGetenv"] boolValue];
        enableGetifaddrsHook = [prefs[@"enableGetifaddrs"] boolValue];
        enableStatHook = [prefs[@"enableStat"] boolValue];
        enableStatfsHook = [prefs[@"enableStatfs"] boolValue];
        enableSysctlHook = [prefs[@"enableSysctl"] boolValue];
        enableSysctlbynameHook = [prefs[@"enableSysctlbyname"] boolValue];
        enableUnameHook = [prefs[@"enableUname"] boolValue];
        enableIsattyHook = [prefs[@"enableIsatty"] boolValue];
        enableOpendirHook = [prefs[@"enableOpendir"] boolValue];
        enableReadHook = [prefs[@"enableRead"] boolValue];
        enableDyldImageCountHook = [prefs[@"enableDyldImageCount"] boolValue];
        enableDyldGetImageVmaddrSlideHook = [prefs[@"enableDyldGetImageVmaddrSlide"] boolValue];
        enableDyldGetImageNameHook = [prefs[@"enableDyldGetImageName"] boolValue];
        
        // 其他类别的 Hook 开关配置读取
        enableCryptoFunctionsHook = [prefs[@"enableCryptoFunctions"] boolValue];
        enableHostInfoFunctionsHook = [prefs[@"enableHostInfoFunctions"] boolValue];
        enableHostStatisticsHook = [prefs[@"enableHostStatistics"] boolValue];
        enableCFStringFunctionsHook = [prefs[@"enableCFStringFunctions"] boolValue];
        enableCFURLFunctionsHook = [prefs[@"enableCFURLFunctions"] boolValue];
        enableTimeFunctionsHook = [prefs[@"enableTimeFunctions"] boolValue];
        enableKeychainFunctionsHook = [prefs[@"enableKeychainFunctions"] boolValue];
        
        // hookCrypt 配置读取
        enableCCCryptHook = [prefs[@"enableCCCrypt"] boolValue];
        enableCCCryptorCreateWithModeHook = [prefs[@"enableCCCryptorCreateWithMode"] boolValue];
        enableCCCryptorCreateHook = [prefs[@"enableCCCryptorCreate"] boolValue];
        enableCCCryptorUpdateHook = [prefs[@"enableCCCryptorUpdate"] boolValue];
        enableCCCryptorFinalHook = [prefs[@"enableCCCryptorFinal"] boolValue];
        
        // stdstringhook 配置读取
        enableStdstringAppendLenHook = [prefs[@"enableStdstringAppendLen"] boolValue];
        enableStdstringAppendHook = [prefs[@"enableStdstringAppend"] boolValue];
        enableStdstringAssignHook = [prefs[@"enableStdstringAssign"] boolValue];
        
        // 新增系统函数配置读取
        enableGettimeofdayHook = [prefs[@"enableGettimeofday"] boolValue];
        enableGetpagesizeHook = [prefs[@"enableGetpagesize"] boolValue];
        enableCNCopyCurrentNetworkInfoHook = [prefs[@"enableCNCopyCurrentNetworkInfo"] boolValue];
        enableCNCopySupportedInterfacesHook = [prefs[@"enableCNCopySupportedInterfaces"] boolValue];
        enableCCSHA1UpdateHook = [prefs[@"enableCCSHA1Update"] boolValue];
        
        // 新增 Hook 配置读取
        enableDladdrHook = [prefs[@"enableDladdr"] boolValue];
        enableFaccessatHook = [prefs[@"enableFaccessat"] boolValue];
        enableGetpidHook = [prefs[@"enableGetpid"] boolValue];
        enableGetppidHook = [prefs[@"enableGetppid"] boolValue];
        enableGetsectiondataHook = [prefs[@"enableGetsectiondata"] boolValue];
        enableIoctlHook = [prefs[@"enableIoctl"] boolValue];
        enableSnprintfHook = [prefs[@"enableSnprintf"] boolValue];
        enableRandHook = [prefs[@"enableRand"] boolValue];
        enableReaddirHook = [prefs[@"enableReaddir"] boolValue];
        enableRmdirHook = [prefs[@"enableRmdir"] boolValue];
        enableMkdirHook = [prefs[@"enableMkdir"] boolValue];
        enableSocketHook = [prefs[@"enableSocket"] boolValue];
        enableSrandHook = [prefs[@"enableSrand"] boolValue];
        enableStrcmpHook = [prefs[@"enableStrcmp"] boolValue];
        enableStrnstrHook = [prefs[@"enableStrnstr"] boolValue];
        enableSysconfHook = [prefs[@"enableSysconf"] boolValue];
        enableTimeHook = [prefs[@"enableTime"] boolValue];
        enableStrcasestrHook = [prefs[@"enableStrcasestr"] boolValue];
        enableSprintfHook = [prefs[@"enableSprintf"] boolValue];
        enableFstatHook = [prefs[@"enableFstat"] boolValue];
        enableFstatatHook = [prefs[@"enableFstatat"] boolValue];
        enableFreadHook = [prefs[@"enableFread"] boolValue];
        enableOpenatHook = [prefs[@"enableOpenat"] boolValue];
        enablePopenHook = [prefs[@"enablePopen"] boolValue];
    }
}

// 检查全局监控是否启用
static BOOL isGlobalMonitoringEnabled() {
    NSDictionary *prefs = loadPreferences();
    NSNumber *globalSwitch = prefs[@"global_monitoring"];
    //NSLog(@"[nake] Global monitoring check - prefs: %@", prefs, globalSwitch);
    NSLog(@"[nake] Global monitoring check - globalSwitch: %@", globalSwitch);
    return [globalSwitch boolValue];  // 默认开启
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
    
    // 系统函数独立 Hook 初始化
    if (enableFopenHook) {
        NSLog(@"[nake] Enabling fopen hook");
        hook_fopen();
    }
    
    if (enableGetenvHook) {
        NSLog(@"[nake] Enabling getenv hook");
        hook_getenv();
    }
    
    if (enableGetifaddrsHook) {
        NSLog(@"[nake] Enabling getifaddrs hook");
        hook_getifaddrs();
    }
    
    if (enableStatHook) {
        NSLog(@"[nake] Enabling stat hook");
        hook_stat();
    }
    
    if (enableStatfsHook) {
        NSLog(@"[nake] Enabling statfs hook");
        hook_statfs();
    }
    
    if (enableSysctlHook) {
        NSLog(@"[nake] Enabling sysctl hook");
        hook_sysctl();
    }
    
    if (enableSysctlbynameHook) {
        NSLog(@"[nake] Enabling sysctlbyname hook");
        hook_sysctlbyname();
    }
    
    if (enableUnameHook) {
        NSLog(@"[nake] Enabling uname hook");
        hook_uname();
    }
    
    if (enableIsattyHook) {
        NSLog(@"[nake] Enabling isatty hook");
        hook_isatty();
    }
    
    if (enableOpendirHook) {
        NSLog(@"[nake] Enabling opendir hook");
        hook_opendir();
    }
    
    if (enableReadHook) {
        NSLog(@"[nake] Enabling read hook");
        hook_read();
    }
    
    if (enableDyldImageCountHook) {
        NSLog(@"[nake] Enabling __dyld_image_count hook");
        hook___dyld_image_count();
    }
    
    if (enableDyldGetImageVmaddrSlideHook) {
        NSLog(@"[nake] Enabling __dyld_get_image_vmaddr_slide hook");
        hook___dyld_get_image_vmaddr_slide();
    }
    
    if (enableDyldGetImageNameHook) {
        NSLog(@"[nake] Enabling __dyld_get_image_name hook");
        hook___dyld_get_image_name();
    }
    
    // 其他类别的 Hook 初始化
    if (enableCryptoFunctionsHook) {
        NSLog(@"[nake] Enabling crypto functions hook");
        hook_CC_SHA256();
    }
    
    if (enableHostInfoFunctionsHook) {
        NSLog(@"[nake] Enabling host info functions hook");
        hook_host_info();
        hook_host_statistics64();
    }
    
    if (enableHostStatisticsHook) {
        NSLog(@"[nake] Enabling host statistics hook");
        hook_host_statistics();
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
    
    // hookCrypt Hook 初始化
    if (enableCCCryptHook) {
        NSLog(@"[nake] Enabling CCCrypt hook");
        hook_CCCrypt();
    }
    
    if (enableCCCryptorCreateWithModeHook) {
        NSLog(@"[nake] Enabling CCCryptorCreateWithMode hook");
        hook_CCCryptorCreateWithMode();
    }
    
    if (enableCCCryptorCreateHook) {
        NSLog(@"[nake] Enabling CCCryptorCreate hook");
        hook_CCCryptorCreate();
    }
    
    if (enableCCCryptorUpdateHook) {
        NSLog(@"[nake] Enabling CCCryptorUpdate hook");
        hook_CCCryptorUpdate();
    }
    
    if (enableCCCryptorFinalHook) {
        NSLog(@"[nake] Enabling CCCryptorFinal hook");
        hook_CCCryptorFinal();
    }
    
    // stdstringhook Hook 初始化
    if (enableStdstringAppendLenHook) {
        NSLog(@"[nake] Enabling std::string::append(len) hook");
        hook_stdstring_appendLen();
    }
    
    if (enableStdstringAppendHook) {
        NSLog(@"[nake] Enabling std::string::append(str) hook");
        hook_stdstring_append();
    }
    
    if (enableStdstringAssignHook) {
        NSLog(@"[nake] Enabling std::string::assign hook");
        hook_stdstring_assign();
    }
    
    if (enableGettimeofdayHook) {
        NSLog(@"[nake] Enabling gettimeofday hook");
        hook_gettimeofday();
    }
    
    if (enableGetpagesizeHook) {
        NSLog(@"[nake] Enabling getpagesize hook");
        hook_getpagesize();
    }
    
    if (enableCNCopyCurrentNetworkInfoHook) {
        NSLog(@"[nake] Enabling CNCopyCurrentNetworkInfo hook");
        hook_CNCopyCurrentNetworkInfo();
    }
    
    if (enableCNCopySupportedInterfacesHook) {
        NSLog(@"[nake] Enabling CNCopySupportedInterfaces hook");
        hook_CNCopySupportedInterfaces();
    }
    
    if (enableCCSHA1UpdateHook) {
        NSLog(@"[nake] Enabling CC_SHA1_Update hook");
        hook_CC_SHA1_Update();
    }
    
    // 新增 Hook 调用
    if (enableDladdrHook) {
        NSLog(@"[nake] Enabling dladdr hook");
        hook_dladdr();
    }
    
    if (enableFaccessatHook) {
        NSLog(@"[nake] Enabling faccessat hook");
        hook_faccessat();
    }
    
    if (enableGetpidHook) {
        NSLog(@"[nake] Enabling getpid hook");
        hook_getpid();
    }
    
    if (enableGetppidHook) {
        NSLog(@"[nake] Enabling getppid hook");
        hook_getppid();
    }
    
    if (enableGetsectiondataHook) {
        NSLog(@"[nake] Enabling getsectiondata hook");
        hook_getsectiondata();
    }
    
    if (enableIoctlHook) {
        NSLog(@"[nake] Enabling ioctl hook");
        hook_ioctl();
    }
    
    if (enableSnprintfHook) {
        NSLog(@"[nake] Enabling snprintf hook");
        hook_snprintf();
    }
    
    if (enableRandHook) {
        NSLog(@"[nake] Enabling rand hook");
        hook_rand();
    }
    
    if (enableReaddirHook) {
        NSLog(@"[nake] Enabling readdir hook");
        hook_readdir();
    }
    
    if (enableRmdirHook) {
        NSLog(@"[nake] Enabling rmdir hook");
        hook_rmdir();
    }
    
    if (enableMkdirHook) {
        NSLog(@"[nake] Enabling mkdir hook");
        hook_mkdir();
    }
    
    if (enableSocketHook) {
        NSLog(@"[nake] Enabling socket hook");
        hook_socket();
    }
    
    if (enableSrandHook) {
        NSLog(@"[nake] Enabling srand hook");
        hook_srand();
    }
    
    if (enableStrcmpHook) {
        NSLog(@"[nake] Enabling strcmp hook");
        hook_strcmp();
    }
    
    if (enableStrnstrHook) {
        NSLog(@"[nake] Enabling strnstr hook");
        hook_strnstr();
    }
    
    if (enableSysconfHook) {
        NSLog(@"[nake] Enabling sysconf hook");
        hook_sysconf();
    }
    
    if (enableTimeHook) {
        NSLog(@"[nake] Enabling time hook");
        hook_time();
    }
    
    if (enableStrcasestrHook) {
        NSLog(@"[nake] Enabling strcasestr hook");
        hook_strcasestr();
    }
    
    if (enableSprintfHook) {
        NSLog(@"[nake] Enabling sprintf hook");
        hook_sprintf();
    }
    
    if (enableFstatHook) {
        NSLog(@"[nake] Enabling fstat hook");
        hook_fstat();
    }
    
    if (enableFstatatHook) {
        NSLog(@"[nake] Enabling fstatat hook");
        hook_fstatat();
    }
    
    if (enableFreadHook) {
        NSLog(@"[nake] Enabling fread hook");
        hook_fread();
    }
    
    if (enableOpenatHook) {
        NSLog(@"[nake] Enabling openat hook");
        hook_openat();
    }
    
    if (enablePopenHook) {
        NSLog(@"[nake] Enabling popen hook");
        hook_popen();
    }
    
    NSLog(@"[nake] Tweak initialization completed for %@", bundleId);
}