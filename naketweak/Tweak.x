#import <Foundation/Foundation.h>
#import "hookobjcMsgsend.h"
#import "hookcommon.h"
#import <rootless.h>
#import "hookCrypt.h"
#import "hookNet.h"
#import "stdstringhook.h"
#import <os/log.h>

static os_log_t nake_log = OS_LOG_DEFAULT;


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
static BOOL enableLstatHook = YES;
static BOOL enableFreadHook = YES;
static BOOL enableOpenatHook = YES;
static BOOL enablePopenHook = YES;

// hookCrypt 变量
static BOOL enableCCHmacHook = YES;
static BOOL enableCCHmacUpdateHook = YES;
static BOOL enableCCMD5Hook = YES;
static BOOL enableCCMD5UpdateHook = YES;

// hookNet 变量
static BOOL enableSSLCreateContextHook = YES;
static BOOL enableSSLSetConnectionHook = YES;
static BOOL enableSSLWriteHook = YES;
static BOOL enableSSLReadHook = YES;
static BOOL enableInetPtonHook = YES;

// hookcommon 扩展变量
static BOOL enableCFStringAppendHook = YES;
static BOOL enableCFStringGetLengthHook = YES;
static BOOL enableCFStringGetCStringHook = YES;
static BOOL enableCFArrayGetCountHook = YES;
static BOOL enableCFArrayGetValueAtIndexHook = YES;
static BOOL enableCFDataCreateHook = YES;
static BOOL enableCFDictionaryCreateCopyHook = YES;
static BOOL enableCFDictionarySetValueHook = YES;
static BOOL enableCFDictionaryGetValueHook = YES;
static BOOL enableCFUUIDCreateHook = YES;

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
        enableLstatHook = [prefs[@"enableLstat"] boolValue];
        enableFreadHook = [prefs[@"enableFread"] boolValue];
        enableOpenatHook = [prefs[@"enableOpenat"] boolValue];
        enablePopenHook = [prefs[@"enablePopen"] boolValue];
        
        // hookCrypt 配置读取
        enableCCHmacHook = [prefs[@"enableCCHmac"] boolValue];
        enableCCHmacUpdateHook = [prefs[@"enableCCHmacUpdate"] boolValue];
        enableCCMD5Hook = [prefs[@"enableCCMD5"] boolValue];
        enableCCMD5UpdateHook = [prefs[@"enableCCMD5Update"] boolValue];
        
        // hookNet 配置读取
        enableSSLCreateContextHook = [prefs[@"enableSSLCreateContext"] boolValue];
        enableSSLSetConnectionHook = [prefs[@"enableSSLSetConnection"] boolValue];
        enableSSLWriteHook = [prefs[@"enableSSLWrite"] boolValue];
        enableSSLReadHook = [prefs[@"enableSSLRead"] boolValue];
        enableInetPtonHook = [prefs[@"enableInetPton"] boolValue];
        
        // hookcommon 扩展配置读取
        enableCFStringAppendHook = [prefs[@"enableCFStringAppend"] boolValue];
        enableCFStringGetLengthHook = [prefs[@"enableCFStringGetLength"] boolValue];
        enableCFStringGetCStringHook = [prefs[@"enableCFStringGetCString"] boolValue];
        enableCFArrayGetCountHook = [prefs[@"enableCFArrayGetCount"] boolValue];
        enableCFArrayGetValueAtIndexHook = [prefs[@"enableCFArrayGetValueAtIndex"] boolValue];
        enableCFDataCreateHook = [prefs[@"enableCFDataCreate"] boolValue];
        enableCFDictionaryCreateCopyHook = [prefs[@"enableCFDictionaryCreateCopy"] boolValue];
        enableCFDictionarySetValueHook = [prefs[@"enableCFDictionarySetValue"] boolValue];
        enableCFDictionaryGetValueHook = [prefs[@"enableCFDictionaryGetValue"] boolValue];
        enableCFUUIDCreateHook = [prefs[@"enableCFUUIDCreate"] boolValue];
    }
}

// 检查全局监控是否启用
static BOOL isGlobalMonitoringEnabled() {
    NSDictionary *prefs = loadPreferences();
    NSNumber *globalSwitch = prefs[@"global_monitoring"];
    os_log(nake_log, "[nake] Global monitoring check - globalSwitch: %{public}@", globalSwitch);
    return [globalSwitch boolValue];
}

// 检查应用是否被启用
static BOOL isAppEnabled(NSString *bundleId) {
    @try {
        if (!bundleId) return NO;  // 没有bundleId默认不启用
        
        // 首先检查全局开关
        if (!isGlobalMonitoringEnabled()) {
            os_log(nake_log, "[nake] Global monitoring is disabled");
            return NO;
        }
        
        NSDictionary *prefs = loadPreferences();
        // NSLog(@"[nake] prefs : %@",prefs);

        NSString *key = [NSString stringWithFormat:@"app_switch_%@", bundleId];
        NSNumber *appSwitch = prefs[key];
        
        BOOL isEnabled = [appSwitch boolValue];
        os_log(nake_log, "[nake] App %{public}@ switch state: %{public}@", bundleId, isEnabled ? @"ENABLED" : @"DISABLED");
        return isEnabled;
        
    } @catch (NSException *exception) {
        os_log(nake_log, "[nake] Error checking app enabled status for %{public}@: %{public}@", bundleId, exception);
        return NO;
    }
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    os_log(nake_log, "[nake] Preferences changed, reloading settings...");
    loadHookSettings();
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    os_log(nake_log, "[nake] Reloaded preferences for %{public}@ - ObjcMsgSend: %d, Access: %d, Dlopen: %d", 
          bundleId, enableObjcMsgSendHook, enableAccessHook, enableDlopenHook);
}

%ctor {    
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    os_log(nake_log, "[nake] Initializing tweak for app: %{public}@", bundleId);
    
    if (!isAppEnabled(bundleId)) {
        os_log(nake_log, "[nake] App %{public}@ is disabled, skipping hook initialization", bundleId);
        return;
    }

    // 加载初始设置
    loadHookSettings();

    os_log(nake_log, "[nake] Hook preferences - ObjcMsgSend: %d, Access: %d, Dlopen: %d", 
          enableObjcMsgSendHook, enableAccessHook, enableDlopenHook);
    
    // 根据设置启用相应的hook
    if (enableObjcMsgSendHook) {
        os_log(nake_log, "[nake] Enabling objc_msgSend hook");
        doHookObjcMsgsend();
    }
    
    if (enableAccessHook) {
        os_log(nake_log, "[nake] Enabling access hook");
        hook_access();
    }
    
    if (enableDlopenHook) {
        os_log(nake_log, "[nake] Enabling dlopen and dlsym hooks");
        hook_dlopen();
        hook_dlsym();
    }
    
    if (enableRes9InitHook) {
        os_log(nake_log, "[nake] Enabling res9 init hook");
        hook_res_9_init();
    }
    
    if (enableClassGetClassMethodHook) {
        os_log(nake_log, "[nake] Enabling class_getClassMethod hook");
        hook_class_getClassMethod();
    }
    
    if (enableSelRegisterNameHook) {
        os_log(nake_log, "[nake] Enabling sel_registerName hook");
        hook_sel_registerName();
    }
    
    if (enableCFNetworkCopySystemProxySettingsHook) {
        os_log(nake_log, "[nake] Enabling CFNetworkCopySystemProxySettings hook");
        hook_CFNetworkCopySystemProxySettings();
    }
    
    // 系统函数独立 Hook 初始化
    if (enableFopenHook) {
        os_log(nake_log, "[nake] Enabling fopen hook");
        hook_fopen();
    }
    
    if (enableGetenvHook) {
        os_log(nake_log, "[nake] Enabling getenv hook");
        hook_getenv();
    }
    
    if (enableGetifaddrsHook) {
        os_log(nake_log, "[nake] Enabling getifaddrs hook");
        hook_getifaddrs();
    }
    
    if (enableStatHook) {
        os_log(nake_log, "[nake] Enabling stat hook");
        hook_stat();
    }
    
    if (enableStatfsHook) {
        os_log(nake_log, "[nake] Enabling statfs hook");
        hook_statfs();
    }
    
    if (enableSysctlHook) {
        os_log(nake_log, "[nake] Enabling sysctl hook");
        hook_sysctl();
    }
    
    if (enableSysctlbynameHook) {
        os_log(nake_log, "[nake] Enabling sysctlbyname hook");
        hook_sysctlbyname();
    }
    
    if (enableUnameHook) {
        os_log(nake_log, "[nake] Enabling uname hook");
        hook_uname();
    }
    
    if (enableIsattyHook) {
        os_log(nake_log, "[nake] Enabling isatty hook");
        hook_isatty();
    }
    
    if (enableOpendirHook) {
        os_log(nake_log, "[nake] Enabling opendir hook");
        hook_opendir();
    }
    
    if (enableReadHook) {
        os_log(nake_log, "[nake] Enabling read hook");
        hook_read();
    }
    
    if (enableDyldImageCountHook) {
        os_log(nake_log, "[nake] Enabling __dyld_image_count hook");
        hook___dyld_image_count();
    }
    
    if (enableDyldGetImageVmaddrSlideHook) {
        os_log(nake_log, "[nake] Enabling __dyld_get_image_vmaddr_slide hook");
        hook___dyld_get_image_vmaddr_slide();
    }
    
    if (enableDyldGetImageNameHook) {
        os_log(nake_log, "[nake] Enabling __dyld_get_image_name hook");
        hook___dyld_get_image_name();
    }
    
    // 其他类别的 Hook 初始化
    if (enableCryptoFunctionsHook) {
        os_log(nake_log, "[nake] Enabling crypto functions hook");
        hook_CC_SHA256();
    }
    
    if (enableHostInfoFunctionsHook) {
        os_log(nake_log, "[nake] Enabling host info functions hook");
        hook_host_info();
        hook_host_statistics64();
    }
    
    if (enableHostStatisticsHook) {
        os_log(nake_log, "[nake] Enabling host statistics hook");
        hook_host_statistics();
    }
    
    if (enableCFStringFunctionsHook) {
        os_log(nake_log, "[nake] Enabling CFString functions hook");
        hook_CFStringCreateCopy();
        hook_CFStringCreateWithCString();
        hook_CFStringCreateWithFileSystemRepresentation();
        hook_CFStringCreateWithFormat();
    }
    
    if (enableCFURLFunctionsHook) {
        os_log(nake_log, "[nake] Enabling CFURL functions hook");
        hook_CFURLCreateWithFileSystemPath();
        hook_CFURLCreateWithString();
    }
    
    if (enableTimeFunctionsHook) {
        os_log(nake_log, "[nake] Enabling time functions hook");
        hook_CACurrentMediaTime();
    }
    
    if (enableKeychainFunctionsHook) {
        os_log(nake_log, "[nake] Enabling keychain functions hook");
        hook_SecItemAdd();
        hook_SecItemUpdate();
        hook_SecItemDelete();
        hook_SecItemCopyMatching();
    }
    
    // hookCrypt Hook 初始化
    if (enableCCCryptHook) {
        os_log(nake_log, "[nake] Enabling CCCrypt hook");
        hook_CCCrypt();
    }
    
    if (enableCCCryptorCreateWithModeHook) {
        os_log(nake_log, "[nake] Enabling CCCryptorCreateWithMode hook");
        hook_CCCryptorCreateWithMode();
    }
    
    if (enableCCCryptorCreateHook) {
        os_log(nake_log, "[nake] Enabling CCCryptorCreate hook");
        hook_CCCryptorCreate();
    }
    
    if (enableCCCryptorUpdateHook) {
        os_log(nake_log, "[nake] Enabling CCCryptorUpdate hook");
        hook_CCCryptorUpdate();
    }
    
    if (enableCCCryptorFinalHook) {
        os_log(nake_log, "[nake] Enabling CCCryptorFinal hook");
        hook_CCCryptorFinal();
    }
    
    // stdstringhook Hook 初始化
    if (enableStdstringAppendLenHook) {
        os_log(nake_log, "[nake] Enabling std::string::append(len) hook");
        hook_stdstring_appendLen();
    }
    
    if (enableStdstringAppendHook) {
        os_log(nake_log, "[nake] Enabling std::string::append(str) hook");
        hook_stdstring_append();
    }
    
    if (enableStdstringAssignHook) {
        os_log(nake_log, "[nake] Enabling std::string::assign hook");
        hook_stdstring_assign();
    }
    
    if (enableGettimeofdayHook) {
        os_log(nake_log, "[nake] Enabling gettimeofday hook");
        hook_gettimeofday();
    }
    
    if (enableGetpagesizeHook) {
        os_log(nake_log, "[nake] Enabling getpagesize hook");
        hook_getpagesize();
    }
    
    if (enableCNCopyCurrentNetworkInfoHook) {
        os_log(nake_log, "[nake] Enabling CNCopyCurrentNetworkInfo hook");
        hook_CNCopyCurrentNetworkInfo();
    }
    
    if (enableCNCopySupportedInterfacesHook) {
        os_log(nake_log, "[nake] Enabling CNCopySupportedInterfaces hook");
        hook_CNCopySupportedInterfaces();
    }
    
    if (enableCCSHA1UpdateHook) {
        os_log(nake_log, "[nake] Enabling CC_SHA1_Update hook");
        hook_CC_SHA1_Update();
    }
    
    // 新增 Hook 调用
    if (enableDladdrHook) {
        os_log(nake_log, "[nake] Enabling dladdr hook");
        hook_dladdr();
    }
    
    if (enableFaccessatHook) {
        os_log(nake_log, "[nake] Enabling faccessat hook");
        hook_faccessat();
    }
    
    if (enableGetpidHook) {
        os_log(nake_log, "[nake] Enabling getpid hook");
        hook_getpid();
    }
    
    if (enableGetppidHook) {
        os_log(nake_log, "[nake] Enabling getppid hook");
        hook_getppid();
    }
    
    if (enableGetsectiondataHook) {
        os_log(nake_log, "[nake] Enabling getsectiondata hook");
        hook_getsectiondata();
    }
    
    if (enableIoctlHook) {
        os_log(nake_log, "[nake] Enabling ioctl hook");
        hook_ioctl();
    }
    
    if (enableSnprintfHook) {
        os_log(nake_log, "[nake] Enabling snprintf hook");
        hook_snprintf();
    }
    
    if (enableRandHook) {
        os_log(nake_log, "[nake] Enabling rand hook");
        hook_rand();
    }
    
    if (enableReaddirHook) {
        os_log(nake_log, "[nake] Enabling readdir hook");
        hook_readdir();
    }
    
    if (enableRmdirHook) {
        os_log(nake_log, "[nake] Enabling rmdir hook");
        hook_rmdir();
    }
    
    if (enableMkdirHook) {
        os_log(nake_log, "[nake] Enabling mkdir hook");
        hook_mkdir();
    }
    
    if (enableSocketHook) {
        os_log(nake_log, "[nake] Enabling socket hook");
        hook_socket();
    }
    
    if (enableSrandHook) {
        os_log(nake_log, "[nake] Enabling srand hook");
        hook_srand();
    }
    
    if (enableStrcmpHook) {
        os_log(nake_log, "[nake] Enabling strcmp hook");
        hook_strcmp();
    }
    
    if (enableStrnstrHook) {
        os_log(nake_log, "[nake] Enabling strnstr hook");
        hook_strnstr();
    }
    
    if (enableSysconfHook) {
        os_log(nake_log, "[nake] Enabling sysconf hook");
        hook_sysconf();
    }
    
    if (enableTimeHook) {
        os_log(nake_log, "[nake] Enabling time hook");
        hook_time();
    }
    
    if (enableStrcasestrHook) {
        os_log(nake_log, "[nake] Enabling strcasestr hook");
        hook_strcasestr();
    }
    
    if (enableSprintfHook) {
        os_log(nake_log, "[nake] Enabling sprintf hook");
        hook_sprintf();
    }
    
    if (enableFstatHook) {
        os_log(nake_log, "[nake] Enabling fstat hook");
        hook_fstat();
    }
    
    if (enableFstatatHook) {
        os_log(nake_log, "[nake] Enabling fstatat hook");
        hook_fstatat();
    }
    
    if (enableLstatHook) {
        os_log(nake_log, "[nake] Enabling lstat hook");
        hook_lstat();
    }
    
    if (enableFreadHook) {
        os_log(nake_log, "[nake] Enabling fread hook");
        hook_fread();
    }
    
    if (enableOpenatHook) {
        os_log(nake_log, "[nake] Enabling openat hook");
        hook_openat();
    }
    
    if (enablePopenHook) {
        os_log(nake_log, "[nake] Enabling popen hook");
        hook_popen();
    }
    
    // hookCrypt Hook 调用
    if (enableCCHmacHook) {
        os_log(nake_log, "[nake] Enabling CCHmac hook");
        hook_CCHmac();
    }
    if (enableCCHmacUpdateHook) {
        os_log(nake_log, "[nake] Enabling CCHmacUpdate hook");
        hook_CCHmacUpdate();
    }
    if (enableCCMD5Hook) {
        os_log(nake_log, "[nake] Enabling CC_MD5 hook");
        hook_CC_MD5();
    }
    if (enableCCMD5UpdateHook) {
        os_log(nake_log, "[nake] Enabling CC_MD5_Update hook");
        hook_CC_MD5_Update();
    }
    
    // hookNet Hook 调用
    if (enableSSLCreateContextHook) {
        os_log(nake_log, "[nake] Enabling SSLCreateContext hook");
        hook_SSLCreateContext();
    }
    if (enableSSLSetConnectionHook) {
        os_log(nake_log, "[nake] Enabling SSLSetConnection hook");
        hook_SSLSetConnection();
    }
    if (enableSSLWriteHook) {
        os_log(nake_log, "[nake] Enabling SSLWrite hook");
        hook_SSLWrite();
    }
    if (enableSSLReadHook) {
        os_log(nake_log, "[nake] Enabling SSLRead hook");
        hook_SSLRead();
    }
    if (enableInetPtonHook) {
        os_log(nake_log, "[nake] Enabling inet_pton hook");
        hook_inet_pton();
    }
    
    // hookcommon 扩展 Hook 调用
    if (enableCFStringAppendHook) {
        os_log(nake_log, "[nake] Enabling CFStringAppend hook");
        hook_CFStringAppend();
    }
    if (enableCFStringGetLengthHook) {
        os_log(nake_log, "[nake] Enabling CFStringGetLength hook");
        hook_CFStringGetLength();
    }
    if (enableCFStringGetCStringHook) {
        os_log(nake_log, "[nake] Enabling CFStringGetCString hook");
        hook_CFStringGetCString();
    }
    if (enableCFArrayGetCountHook) {
        os_log(nake_log, "[nake] Enabling CFArrayGetCount hook");
        hook_CFArrayGetCount();
    }
    if (enableCFArrayGetValueAtIndexHook) {
        os_log(nake_log, "[nake] Enabling CFArrayGetValueAtIndex hook");
        hook_CFArrayGetValueAtIndex();
    }
    if (enableCFDataCreateHook) {
        os_log(nake_log, "[nake] Enabling CFDataCreate hook");
        hook_CFDataCreate();
    }
    if (enableCFDictionaryCreateCopyHook) {
        os_log(nake_log, "[nake] Enabling CFDictionaryCreateCopy hook");
        hook_CFDictionaryCreateCopy();
    }
    if (enableCFDictionarySetValueHook) {
        os_log(nake_log, "[nake] Enabling CFDictionarySetValue hook");
        hook_CFDictionarySetValue();
    }
    if (enableCFDictionaryGetValueHook) {
        os_log(nake_log, "[nake] Enabling CFDictionaryGetValue hook");
        hook_CFDictionaryGetValue();
    }
    if (enableCFUUIDCreateHook) {
        os_log(nake_log, "[nake] Enabling CFUUIDCreate hook");
        hook_CFUUIDCreate();
    }
    
    os_log(nake_log, "[nake] Tweak initialization completed for %{public}@", bundleId);
}