#import "NKARootViewController.h"
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <rootless.h>

// 前向声明
@interface NKAAppListViewController : UITableViewController
@property(nonatomic, strong) NSArray *appList;
@end

// 偏好设置路径（统一使用一个文件，宏自动包含 ROOT_PATH_NS）
#define kPreferencePath                                                        \
  ROOT_PATH_NS(@"/var/mobile/Library/Preferences/com.rainl.nakePref.plist")

// Hook 控制键
static NSString *const kEnableObjcMsgSendHook = @"EnableObjcMsgSendHook";
static NSString *const kEnableAccessHook = @"EnableAccessHook";
static NSString *const kEnableDlopenHook =
    @"EnableDlopenHook"; // 包含 dlopen 和 dlsym
static NSString *const kEnableRes9InitHook = @"EnableRes9InitHook";
static NSString *const kEnableClassGetClassMethodHook = @"enableClassGetClassMethod";
static NSString *const kEnableSelRegisterNameHook = @"enableSelRegisterName";
static NSString *const kEnableCFNetworkCopySystemProxySettingsHook = @"enableCFNetworkCopySystemProxySettings";

// 新增的 Hook 控制键（按类别分组）
// 系统函数独立控制键
static NSString *const kEnableFopenHook = @"enableFopen";
static NSString *const kEnableGetenvHook = @"enableGetenv";
static NSString *const kEnableGetifaddrsHook = @"enableGetifaddrs";
static NSString *const kEnableStatHook = @"enableStat";
static NSString *const kEnableStatfsHook = @"enableStatfs";
static NSString *const kEnableSysctlHook = @"enableSysctl";
static NSString *const kEnableSysctlbynameHook = @"enableSysctlbyname";
static NSString *const kEnableUnameHook = @"enableUname";
static NSString *const kEnableIsattyHook = @"enableIsatty";
static NSString *const kEnableOpendirHook = @"enableOpendir";
static NSString *const kEnableReadHook = @"enableRead";
static NSString *const kEnableDyldImageCountHook = @"enableDyldImageCount";
static NSString *const kEnableDyldGetImageVmaddrSlideHook = @"enableDyldGetImageVmaddrSlide";
static NSString *const kEnableDyldGetImageNameHook = @"enableDyldGetImageName";

// 其他类别的 Hook 控制键
static NSString *const kEnableCryptoFunctionsHook = @"enableCryptoFunctions";
static NSString *const kEnableHostInfoFunctionsHook = @"enableHostInfoFunctions";
static NSString *const kEnableHostStatisticsHook = @"enableHostStatistics";
static NSString *const kEnableCFStringFunctionsHook = @"enableCFStringFunctions";
static NSString *const kEnableCFURLFunctionsHook = @"enableCFURLFunctions";
static NSString *const kEnableTimeFunctionsHook = @"enableTimeFunctions";
static NSString *const kEnableKeychainFunctionsHook = @"enableKeychainFunctions";

// 新增系统函数控制键
static NSString *const kEnableGettimeofdayHook = @"enableGettimeofday";
static NSString *const kEnableGetpagesizeHook = @"enableGetpagesize";
static NSString *const kEnableCNCopyCurrentNetworkInfoHook = @"enableCNCopyCurrentNetworkInfo";
static NSString *const kEnableCNCopySupportedInterfacesHook = @"enableCNCopySupportedInterfaces";
static NSString *const kEnableCCSHA1UpdateHook = @"enableCCSHA1Update";

// 新增 Hook 控制键
static NSString *const kEnableDladdrHook = @"enableDladdr";
static NSString *const kEnableFaccessatHook = @"enableFaccessat";
static NSString *const kEnableGetpidHook = @"enableGetpid";
static NSString *const kEnableGetppidHook = @"enableGetppid";
static NSString *const kEnableGetsectiondataHook = @"enableGetsectiondata";
static NSString *const kEnableIoctlHook = @"enableIoctl";
static NSString *const kEnableSnprintfHook = @"enableSnprintf";
static NSString *const kEnableRandHook = @"enableRand";
static NSString *const kEnableReaddirHook = @"enableReaddir";
static NSString *const kEnableRmdirHook = @"enableRmdir";
static NSString *const kEnableMkdirHook = @"enableMkdir";
static NSString *const kEnableSocketHook = @"enableSocket";
static NSString *const kEnableSrandHook = @"enableSrand";
static NSString *const kEnableStrcmpHook = @"enableStrcmp";
static NSString *const kEnableStrnstrHook = @"enableStrnstr";
static NSString *const kEnableSysconfHook = @"enableSysconf";
static NSString *const kEnableTimeHook = @"enableTime";
static NSString *const kEnableStrcasestrHook = @"enableStrcasestr";
static NSString *const kEnableSprintfHook = @"enableSprintf";
static NSString *const kEnableFstatHook = @"enableFstat";
static NSString *const kEnableFstatatHook = @"enableFstatat";
static NSString *const kEnableLstatHook = @"enableLstat";
static NSString *const kEnableFreadHook = @"enableFread";
static NSString *const kEnableOpenatHook = @"enableOpenat";
static NSString *const kEnablePopenHook = @"enablePopen";

// hookCrypt 控制键
static NSString *const kEnableCCCryptHook = @"enableCCCrypt";
static NSString *const kEnableCCCryptorCreateWithModeHook = @"enableCCCryptorCreateWithMode";
static NSString *const kEnableCCCryptorCreateHook = @"enableCCCryptorCreate";
static NSString *const kEnableCCCryptorUpdateHook = @"enableCCCryptorUpdate";
static NSString *const kEnableCCCryptorFinalHook = @"enableCCCryptorFinal";
static NSString *const kEnableCCHmacHook = @"enableCCHmac";
static NSString *const kEnableCCHmacUpdateHook = @"enableCCHmacUpdate";
static NSString *const kEnableCCMD5Hook = @"enableCCMD5";
static NSString *const kEnableCCMD5UpdateHook = @"enableCCMD5Update";

// hookNet 控制键
static NSString *const kEnableSSLCreateContextHook = @"enableSSLCreateContext";
static NSString *const kEnableSSLSetConnectionHook = @"enableSSLSetConnection";
static NSString *const kEnableSSLWriteHook = @"enableSSLWrite";
static NSString *const kEnableSSLReadHook = @"enableSSLRead";
static NSString *const kEnableInetPtonHook = @"enableInetPton";

// hookcommon 扩展控制键
static NSString *const kEnableCFStringAppendHook = @"enableCFStringAppend";
static NSString *const kEnableCFStringGetLengthHook = @"enableCFStringGetLength";
static NSString *const kEnableCFStringGetCStringHook = @"enableCFStringGetCString";
static NSString *const kEnableCFArrayGetCountHook = @"enableCFArrayGetCount";
static NSString *const kEnableCFArrayGetValueAtIndexHook = @"enableCFArrayGetValueAtIndex";
static NSString *const kEnableCFDataCreateHook = @"enableCFDataCreate";
static NSString *const kEnableCFDictionaryCreateCopyHook = @"enableCFDictionaryCreateCopy";
static NSString *const kEnableCFDictionarySetValueHook = @"enableCFDictionarySetValue";
static NSString *const kEnableCFDictionaryGetValueHook = @"enableCFDictionaryGetValue";
static NSString *const kEnableCFUUIDCreateHook = @"enableCFUUIDCreate";

// stdstringhook 控制键
static NSString *const kEnableStdstringAppendLenHook = @"enableStdstringAppendLen";
static NSString *const kEnableStdstringAppendHook = @"enableStdstringAppend";
static NSString *const kEnableStdstringAssignHook = @"enableStdstringAssign";

@interface NKARootViewController ()
@end

@implementation NKARootViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = @"Nake Hook 设置";
  self.tableView.allowsSelection = YES;
}

#pragma mark - Preference Management

- (NSMutableDictionary *)loadPreferences {
  NSMutableDictionary *prefs =
      [NSMutableDictionary dictionaryWithContentsOfFile:kPreferencePath];
  return prefs ?: [NSMutableDictionary dictionary];
}

- (void)savePreferences:(NSDictionary *)prefs {
  [prefs writeToFile:kPreferencePath atomically:YES];
  NSLog(@"[nakeapp] Saved preferences: %@", prefs);
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2; // Hook 控制 + 应用列表
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return 85; // 7个原有 Hook 开关 + 14个系统函数独立开关 + 7个其他类别 Hook 开关 + 8个新Hook开关 + 5个新增Hook开关 + 24个新增Hook开关 + 1个lstat开关 + 19个新Hook开关
  } else {
    return 2; // 全局开关 + 查看应用列表按钮
  }
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return @"Hook 控制";
  } else {
    return @"应用列表";
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == 0) {
    // Hook 控制开关
    static NSString *SwitchCellIdentifier = @"SwitchCell";
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:SwitchCellIdentifier];

    if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:SwitchCellIdentifier];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    // 移除旧的 switch（如果存在）
    for (UIView *subview in cell.contentView.subviews) {
      if ([subview isKindOfClass:[UISwitch class]]) {
        [subview removeFromSuperview];
      }
    }

    NSString *title;
    NSString *key;
    NSInteger tag;

    switch (indexPath.row) {
    case 0:
      title = @"启用 objc_msgSend Hook";
      key = kEnableObjcMsgSendHook;
      tag = 100;
      break;
    case 1:
      title = @"启用 access Hook";
      key = kEnableAccessHook;
      tag = 101;
      break;
    case 2:
      title = @"启用 dlopen/dlsym Hook";
      key = kEnableDlopenHook;
      tag = 102;
      break;
    case 3:
      title = @"启用 _res_9_init Hook";
      key = kEnableRes9InitHook;
      tag = 103;
      break;
    case 4:
      title = @"启用 class_getClassMethod Hook";
      key = kEnableClassGetClassMethodHook;
      tag = 104;
      break;
    case 5:
      title = @"启用 sel_registerName Hook";
      key = kEnableSelRegisterNameHook;
      tag = 105;
      break;
    case 6:
      title = @"启用 CFNetworkCopySystemProxySettings Hook";
      key = kEnableCFNetworkCopySystemProxySettingsHook;
      tag = 106;
      break;
    // 系统函数独立开关
    case 7:
      title = @"启用 fopen Hook";
      key = kEnableFopenHook;
      tag = 107;
      break;
    case 8:
      title = @"启用 getenv Hook";
      key = kEnableGetenvHook;
      tag = 108;
      break;
    case 9:
      title = @"启用 getifaddrs Hook";
      key = kEnableGetifaddrsHook;
      tag = 109;
      break;
    case 10:
      title = @"启用 stat Hook";
      key = kEnableStatHook;
      tag = 110;
      break;
    case 11:
      title = @"启用 statfs Hook";
      key = kEnableStatfsHook;
      tag = 111;
      break;
    case 12:
      title = @"启用 sysctl Hook";
      key = kEnableSysctlHook;
      tag = 112;
      break;
    case 13:
      title = @"启用 sysctlbyname Hook";
      key = kEnableSysctlbynameHook;
      tag = 113;
      break;
    case 14:
      title = @"启用 uname Hook";
      key = kEnableUnameHook;
      tag = 114;
      break;
    case 15:
      title = @"启用 isatty Hook";
      key = kEnableIsattyHook;
      tag = 115;
      break;
    case 16:
      title = @"启用 opendir Hook";
      key = kEnableOpendirHook;
      tag = 116;
      break;
    case 17:
      title = @"启用 read Hook";
      key = kEnableReadHook;
      tag = 117;
      break;
    case 18:
      title = @"启用 __dyld_image_count Hook";
      key = kEnableDyldImageCountHook;
      tag = 118;
      break;
    case 19:
      title = @"启用 __dyld_get_image_vmaddr_slide Hook";
      key = kEnableDyldGetImageVmaddrSlideHook;
      tag = 119;
      break;
    case 20:
      title = @"启用 __dyld_get_image_name Hook";
      key = kEnableDyldGetImageNameHook;
      tag = 140;
      break;
    // 其他类别的 Hook 开关
    case 21:
      title = @"启用加密函数 Hook (CC_SHA256)";
      key = kEnableCryptoFunctionsHook;
      tag = 120;
      break;
    case 22:
      title = @"启用主机信息 Hook (host_info, etc.)";
      key = kEnableHostInfoFunctionsHook;
      tag = 121;
      break;
    case 23:
      title = @"启用 host_statistics Hook";
      key = kEnableHostStatisticsHook;
      tag = 134;
      break;
    case 24:
      title = @"启用 CFString Hook";
      key = kEnableCFStringFunctionsHook;
      tag = 122;
      break;
    case 25:
      title = @"启用 CFURL Hook";
      key = kEnableCFURLFunctionsHook;
      tag = 123;
      break;
    case 26:
      title = @"启用时间函数 Hook (CACurrentMediaTime)";
      key = kEnableTimeFunctionsHook;
      tag = 124;
      break;
    case 27:
      title = @"启用 Keychain Hook";
      key = kEnableKeychainFunctionsHook;
      tag = 125;
      break;
    case 28:
      title = @"启用 CCCrypt Hook";
      key = kEnableCCCryptHook;
      tag = 126;
      break;
    case 29:
      title = @"启用 CCCryptorCreateWithMode Hook";
      key = kEnableCCCryptorCreateWithModeHook;
      tag = 127;
      break;
    case 30:
      title = @"启用 CCCryptorCreate Hook";
      key = kEnableCCCryptorCreateHook;
      tag = 128;
      break;
    case 31:
      title = @"启用 CCCryptorUpdate Hook";
      key = kEnableCCCryptorUpdateHook;
      tag = 129;
      break;
    case 32:
      title = @"启用 CCCryptorFinal Hook";
      key = kEnableCCCryptorFinalHook;
      tag = 130;
      break;
    case 33:
      title = @"启用 std::string::append(len) Hook";
      key = kEnableStdstringAppendLenHook;
      tag = 131;
      break;
    case 34:
      title = @"启用 std::string::append(str) Hook";
      key = kEnableStdstringAppendHook;
      tag = 132;
      break;
    case 35:
      title = @"启用 std::string::assign Hook";
      key = kEnableStdstringAssignHook;
      tag = 133;
      break;
    case 36:
      title = @"启用 gettimeofday Hook";
      key = kEnableGettimeofdayHook;
      tag = 135;
      break;
    case 37:
      title = @"启用 getpagesize Hook";
      key = kEnableGetpagesizeHook;
      tag = 136;
      break;
    case 38:
      title = @"启用 CNCopyCurrentNetworkInfo Hook";
      key = kEnableCNCopyCurrentNetworkInfoHook;
      tag = 137;
      break;
    case 39:
      title = @"启用 CNCopySupportedInterfaces Hook";
      key = kEnableCNCopySupportedInterfacesHook;
      tag = 138;
      break;
    case 40:
      title = @"启用 CC_SHA1_Update Hook";
      key = kEnableCCSHA1UpdateHook;
      tag = 139;
      break;
    case 41:
      title = @"启用 dladdr Hook";
      key = kEnableDladdrHook;
      tag = 141;
      break;
    case 42:
      title = @"启用 faccessat Hook";
      key = kEnableFaccessatHook;
      tag = 142;
      break;
    case 43:
      title = @"启用 getpid Hook";
      key = kEnableGetpidHook;
      tag = 143;
      break;
    case 44:
      title = @"启用 getppid Hook";
      key = kEnableGetppidHook;
      tag = 144;
      break;
    case 45:
      title = @"启用 getsectiondata Hook";
      key = kEnableGetsectiondataHook;
      tag = 145;
      break;
    case 46:
      title = @"启用 ioctl Hook";
      key = kEnableIoctlHook;
      tag = 146;
      break;
    case 47:
      title = @"启用 snprintf Hook";
      key = kEnableSnprintfHook;
      tag = 147;
      break;
    case 48:
      title = @"启用 rand Hook";
      key = kEnableRandHook;
      tag = 148;
      break;
    case 49:
      title = @"启用 readdir Hook";
      key = kEnableReaddirHook;
      tag = 149;
      break;
    case 50:
      title = @"启用 rmdir Hook";
      key = kEnableRmdirHook;
      tag = 150;
      break;
    case 51:
      title = @"启用 mkdir Hook";
      key = kEnableMkdirHook;
      tag = 151;
      break;
    case 52:
      title = @"启用 socket Hook";
      key = kEnableSocketHook;
      tag = 152;
      break;
    case 53:
      title = @"启用 srand Hook";
      key = kEnableSrandHook;
      tag = 153;
      break;
    case 54:
      title = @"启用 strcmp Hook";
      key = kEnableStrcmpHook;
      tag = 154;
      break;
    case 55:
      title = @"启用 strnstr Hook";
      key = kEnableStrnstrHook;
      tag = 155;
      break;
    case 56:
      title = @"启用 sysconf Hook";
      key = kEnableSysconfHook;
      tag = 156;
      break;
    case 57:
      title = @"启用 time Hook";
      key = kEnableTimeHook;
      tag = 157;
      break;
    case 58:
      title = @"启用 strcasestr Hook";
      key = kEnableStrcasestrHook;
      tag = 158;
      break;
    case 59:
      title = @"启用 sprintf Hook";
      key = kEnableSprintfHook;
      tag = 159;
      break;
    case 60:
      title = @"启用 fstat Hook";
      key = kEnableFstatHook;
      tag = 160;
      break;
    case 61:
      title = @"启用 fstatat Hook";
      key = kEnableFstatatHook;
      tag = 161;
      break;
    case 62:
      title = @"启用 lstat Hook";
      key = kEnableLstatHook;
      tag = 165;
      break;
    case 63:
      title = @"启用 fread Hook";
      key = kEnableFreadHook;
      tag = 162;
      break;
    case 64:
      title = @"启用 openat Hook";
      key = kEnableOpenatHook;
      tag = 163;
      break;
    case 65:
      title = @"启用 popen Hook";
      key = kEnablePopenHook;
      tag = 164;
      break;
    case 66:
      title = @"启用 CCHmac Hook";
      key = kEnableCCHmacHook;
      tag = 170;
      break;
    case 67:
      title = @"启用 CCHmacUpdate Hook";
      key = kEnableCCHmacUpdateHook;
      tag = 171;
      break;
    case 68:
      title = @"启用 CC_MD5 Hook";
      key = kEnableCCMD5Hook;
      tag = 172;
      break;
    case 69:
      title = @"启用 CC_MD5_Update Hook";
      key = kEnableCCMD5UpdateHook;
      tag = 173;
      break;
    case 70:
      title = @"启用 SSLCreateContext Hook";
      key = kEnableSSLCreateContextHook;
      tag = 174;
      break;
    case 71:
      title = @"启用 SSLSetConnection Hook";
      key = kEnableSSLSetConnectionHook;
      tag = 175;
      break;
    case 72:
      title = @"启用 SSLWrite Hook";
      key = kEnableSSLWriteHook;
      tag = 176;
      break;
    case 73:
      title = @"启用 SSLRead Hook";
      key = kEnableSSLReadHook;
      tag = 177;
      break;
    case 74:
      title = @"启用 inet_pton Hook";
      key = kEnableInetPtonHook;
      tag = 178;
      break;
    case 75:
      title = @"启用 CFStringAppend Hook";
      key = kEnableCFStringAppendHook;
      tag = 180;
      break;
    case 76:
      title = @"启用 CFStringGetLength Hook";
      key = kEnableCFStringGetLengthHook;
      tag = 181;
      break;
    case 77:
      title = @"启用 CFStringGetCString Hook";
      key = kEnableCFStringGetCStringHook;
      tag = 182;
      break;
    case 78:
      title = @"启用 CFArrayGetCount Hook";
      key = kEnableCFArrayGetCountHook;
      tag = 183;
      break;
    case 79:
      title = @"启用 CFArrayGetValueAtIndex Hook";
      key = kEnableCFArrayGetValueAtIndexHook;
      tag = 184;
      break;
    case 80:
      title = @"启用 CFDataCreate Hook";
      key = kEnableCFDataCreateHook;
      tag = 185;
      break;
    case 81:
      title = @"启用 CFDictionaryCreateCopy Hook";
      key = kEnableCFDictionaryCreateCopyHook;
      tag = 186;
      break;
    case 82:
      title = @"启用 CFDictionarySetValue Hook";
      key = kEnableCFDictionarySetValueHook;
      tag = 187;
      break;
    case 83:
      title = @"启用 CFDictionaryGetValue Hook";
      key = kEnableCFDictionaryGetValueHook;
      tag = 188;
      break;
    case 84:
      title = @"启用 CFUUIDCreate Hook";
      key = kEnableCFUUIDCreateHook;
      tag = 189;
      break;
    default:
      title = @"";
      key = @"";
      tag = 0;
      break;
    }

    cell.textLabel.text = title;

    UISwitch *switchControl = [[UISwitch alloc] init];
    switchControl.tag = tag;

    NSDictionary *prefs = [self loadPreferences];
    NSNumber *value = prefs[key];
    
    BOOL defaultValue = YES;
    if (tag == 105 || tag == 108 || tag == 115 || tag == 116 || tag == 122 || tag == 123) {
        defaultValue = NO;
    }
    
    switchControl.on = value ? [value boolValue] : defaultValue;

    [switchControl addTarget:self
                      action:@selector(hookSwitchChanged:)
            forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switchControl;
    
    // 保存switch引用
    switch (tag) {
      case 100:
        self.objcMsgSendSwitch = switchControl;
        break;
      case 101:
        self.accessSwitch = switchControl;
        break;
      case 102:
        self.dlopenSwitch = switchControl;
        break;
      case 103:
        self.res9InitSwitch = switchControl;
        break;
      case 104:
      self.classGetClassMethodSwitch = switchControl;
      break;
    case 105:
      self.selRegisterNameSwitch = switchControl;
      break;
    case 106:
      self.cfNetworkCopySystemProxySettingsSwitch = switchControl;
      break;
    // 系统函数独立switch引用
    case 107:
      self.fopenSwitch = switchControl;
      break;
    case 108:
      self.getenvSwitch = switchControl;
      break;
    case 109:
      self.getifaddrsSwitch = switchControl;
      break;
    case 110:
      self.statSwitch = switchControl;
      break;
    case 111:
      self.statfsSwitch = switchControl;
      break;
    case 112:
      self.sysctlSwitch = switchControl;
      break;
    case 113:
      self.sysctlbynameSwitch = switchControl;
      break;
    case 114:
      self.unameSwitch = switchControl;
      break;
    case 115:
      self.isattySwitch = switchControl;
      break;
    case 116:
      self.opendirSwitch = switchControl;
      break;
    case 117:
      self.readSwitch = switchControl;
      break;
    case 118:
      self.dyldImageCountSwitch = switchControl;
      break;
    case 119:
      self.dyldGetImageVmaddrSlideSwitch = switchControl;
      break;
    case 140:
      self.dyldGetImageNameSwitch = switchControl;
      break;
    // 其他类别的switch引用
    case 120:
      self.cryptoFunctionsSwitch = switchControl;
      break;
    case 121:
      self.hostInfoFunctionsSwitch = switchControl;
      break;
    case 134:
      self.hostStatisticsSwitch = switchControl;
      break;
    case 122:
      self.cfStringFunctionsSwitch = switchControl;
      break;
    case 123:
      self.cfURLFunctionsSwitch = switchControl;
      break;
    case 124:
      self.timeFunctionsSwitch = switchControl;
      break;
    case 125:
      self.keychainFunctionsSwitch = switchControl;
      break;
    case 126:
      self.cccryptSwitch = switchControl;
      break;
    case 127:
      self.cccryptorCreateWithModeSwitch = switchControl;
      break;
    case 128:
      self.cccryptorCreateSwitch = switchControl;
      break;
    case 129:
      self.cccryptorUpdateSwitch = switchControl;
      break;
    case 130:
      self.cccryptorFinalSwitch = switchControl;
      break;
    case 131:
      self.stdstringAppendLenSwitch = switchControl;
      break;
    case 132:
      self.stdstringAppendSwitch = switchControl;
      break;
    case 133:
      self.stdstringAssignSwitch = switchControl;
      break;
    case 135:
      self.gettimeofdaySwitch = switchControl;
      break;
    case 136:
      self.getpagesizeSwitch = switchControl;
      break;
    case 137:
      self.cnCopyCurrentNetworkInfoSwitch = switchControl;
      break;
    case 138:
      self.cnCopySupportedInterfacesSwitch = switchControl;
      break;
    case 139:
      self.ccSHA1UpdateSwitch = switchControl;
      break;
    case 141:
      self.dladdrSwitch = switchControl;
      break;
    case 142:
      self.faccessatSwitch = switchControl;
      break;
    case 143:
      self.getpidSwitch = switchControl;
      break;
    case 144:
      self.getppidSwitch = switchControl;
      break;
    case 145:
      self.getsectiondataSwitch = switchControl;
      break;
    case 146:
      self.ioctlSwitch = switchControl;
      break;
    case 147:
      self.snprintfSwitch = switchControl;
      break;
    case 148:
      self.randSwitch = switchControl;
      break;
    case 149:
      self.readdirSwitch = switchControl;
      break;
    case 150:
      self.rmdirSwitch = switchControl;
      break;
    case 151:
      self.mkdirSwitch = switchControl;
      break;
    case 152:
      self.socketSwitch = switchControl;
      break;
    case 153:
      self.srandSwitch = switchControl;
      break;
    case 154:
      self.strcmpSwitch = switchControl;
      break;
    case 155:
      self.strnstrSwitch = switchControl;
      break;
    case 156:
      self.sysconfSwitch = switchControl;
      break;
    case 157:
      self.timeSwitch = switchControl;
      break;
    case 158:
      self.strcasestrSwitch = switchControl;
      break;
    case 159:
      self.sprintfSwitch = switchControl;
      break;
    case 160:
      self.fstatSwitch = switchControl;
      break;
    case 161:
      self.fstatatSwitch = switchControl;
      break;
    case 162:
      self.freadSwitch = switchControl;
      break;
    case 163:
      self.openatSwitch = switchControl;
      break;
    case 164:
      self.popenSwitch = switchControl;
      break;
    default:
      break;
    }

    return cell;

  } else {
    // 应用列表部分
    if (indexPath.row == 0) {
      // 全局监控开关
      static NSString *GlobalSwitchCellIdentifier = @"GlobalSwitchCell";
      UITableViewCell *cell = [tableView
          dequeueReusableCellWithIdentifier:GlobalSwitchCellIdentifier];

      if (!cell) {
        cell =
            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:GlobalSwitchCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
      }

      // 移除旧的 switch
      for (UIView *subview in cell.contentView.subviews) {
        if ([subview isKindOfClass:[UISwitch class]]) {
          [subview removeFromSuperview];
        }
      }

      cell.textLabel.text = @"全局监控开关";

      UISwitch *switchControl = [[UISwitch alloc] init];
      switchControl.tag = 200;

      NSDictionary *prefs = [self loadPreferences];
      NSNumber *value = prefs[@"global_monitoring"];
      switchControl.on = value ? [value boolValue] : YES; // 默认开启

      [switchControl addTarget:self
                        action:@selector(globalSwitchChanged:)
              forControlEvents:UIControlEventValueChanged];
      cell.accessoryView = switchControl;

      return cell;

    } else {
      // 查看应用列表按钮
      static NSString *ButtonCellIdentifier = @"ButtonCell";
      UITableViewCell *cell =
          [tableView dequeueReusableCellWithIdentifier:ButtonCellIdentifier];

      if (!cell) {
        cell =
            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:ButtonCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }

      cell.textLabel.text = @"查看已安装应用";
      cell.textLabel.textColor = [UIColor systemBlueColor];

      return cell;
    }
  }
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  if (indexPath.section == 1 && indexPath.row == 1) {
    // 点击"查看已安装应用"
    [self showAppList];
  }
}

#pragma mark - Switch Actions

- (void)hookSwitchChanged:(UISwitch *)sender {
  NSMutableDictionary *prefs = [self loadPreferences];

  NSString *key;
  switch (sender.tag) {
  case 100:
    key = kEnableObjcMsgSendHook;
    break;
  case 101:
    key = kEnableAccessHook;
    break;
  case 102:
    key = kEnableDlopenHook;
    break;
  case 103:
    key = kEnableRes9InitHook;
    break;
  case 104:
    key = kEnableClassGetClassMethodHook;
    break;
  case 105:
    key = kEnableSelRegisterNameHook;
    break;
  case 106:
    key = kEnableCFNetworkCopySystemProxySettingsHook;
    break;
  // 系统函数独立开关
  case 107:
    key = kEnableFopenHook;
    break;
  case 108:
    key = kEnableGetenvHook;
    break;
  case 109:
    key = kEnableGetifaddrsHook;
    break;
  case 110:
    key = kEnableStatHook;
    break;
  case 111:
    key = kEnableStatfsHook;
    break;
  case 112:
    key = kEnableSysctlHook;
    break;
  case 113:
    key = kEnableSysctlbynameHook;
    break;
  case 114:
      key = kEnableUnameHook;
      break;
    case 115:
      key = kEnableIsattyHook;
      break;
    case 116:
      key = kEnableOpendirHook;
      break;
    case 117:
      key = kEnableReadHook;
      break;
    case 118:
      key = kEnableDyldImageCountHook;
      break;
    case 119:
      key = kEnableDyldGetImageVmaddrSlideHook;
      break;
    case 140:
      key = kEnableDyldGetImageNameHook;
      break;
    // 其他类别的 Hook 开关
    case 120:
      key = kEnableCryptoFunctionsHook;
      break;
    case 121:
      key = kEnableHostInfoFunctionsHook;
      break;
    case 134:
      key = kEnableHostStatisticsHook;
      break;
    case 122:
      key = kEnableCFStringFunctionsHook;
      break;
    case 123:
      key = kEnableCFURLFunctionsHook;
      break;
    case 124:
      key = kEnableTimeFunctionsHook;
      break;
    case 125:
      key = kEnableKeychainFunctionsHook;
      break;
    case 126:
      key = kEnableCCCryptHook;
      break;
    case 127:
      key = kEnableCCCryptorCreateWithModeHook;
      break;
    case 128:
      key = kEnableCCCryptorCreateHook;
      break;
    case 129:
      key = kEnableCCCryptorUpdateHook;
      break;
    case 130:
      key = kEnableCCCryptorFinalHook;
      break;
    case 131:
      key = kEnableStdstringAppendLenHook;
      break;
    case 132:
      key = kEnableStdstringAppendHook;
      break;
    case 133:
      key = kEnableStdstringAssignHook;
      break;
    case 135:
      key = kEnableGettimeofdayHook;
      break;
    case 136:
      key = kEnableGetpagesizeHook;
      break;
    case 137:
      key = kEnableCNCopyCurrentNetworkInfoHook;
      break;
    case 138:
      key = kEnableCNCopySupportedInterfacesHook;
      break;
    case 139:
      key = kEnableCCSHA1UpdateHook;
      break;
    case 141:
      key = kEnableDladdrHook;
      break;
    case 142:
      key = kEnableFaccessatHook;
      break;
    case 143:
      key = kEnableGetpidHook;
      break;
    case 144:
      key = kEnableGetppidHook;
      break;
    case 145:
      key = kEnableGetsectiondataHook;
      break;
    case 146:
      key = kEnableIoctlHook;
      break;
    case 147:
      key = kEnableSnprintfHook;
      break;
    case 148:
      key = kEnableRandHook;
      break;
    case 149:
      key = kEnableReaddirHook;
      break;
    case 150:
      key = kEnableRmdirHook;
      break;
    case 151:
      key = kEnableMkdirHook;
      break;
    case 152:
      key = kEnableSocketHook;
      break;
    case 153:
      key = kEnableSrandHook;
      break;
    case 154:
      key = kEnableStrcmpHook;
      break;
    case 155:
      key = kEnableStrnstrHook;
      break;
    case 156:
      key = kEnableSysconfHook;
      break;
    case 157:
      key = kEnableTimeHook;
      break;
    case 158:
      key = kEnableStrcasestrHook;
      break;
    case 159:
      key = kEnableSprintfHook;
      break;
    case 160:
      key = kEnableFstatHook;
      break;
    case 161:
      key = kEnableFstatatHook;
      break;
    case 162:
      key = kEnableFreadHook;
      break;
    case 163:
      key = kEnableOpenatHook;
      break;
    case 164:
      key = kEnablePopenHook;
      break;
    case 165:
      key = kEnableLstatHook;
      break;
    case 170:
      key = kEnableCCHmacHook;
      break;
    case 171:
      key = kEnableCCHmacUpdateHook;
      break;
    case 172:
      key = kEnableCCMD5Hook;
      break;
    case 173:
      key = kEnableCCMD5UpdateHook;
      break;
    case 174:
      key = kEnableSSLCreateContextHook;
      break;
    case 175:
      key = kEnableSSLSetConnectionHook;
      break;
    case 176:
      key = kEnableSSLWriteHook;
      break;
    case 177:
      key = kEnableSSLReadHook;
      break;
    case 178:
      key = kEnableInetPtonHook;
      break;
    case 180:
      key = kEnableCFStringAppendHook;
      break;
    case 181:
      key = kEnableCFStringGetLengthHook;
      break;
    case 182:
      key = kEnableCFStringGetCStringHook;
      break;
    case 183:
      key = kEnableCFArrayGetCountHook;
      break;
    case 184:
      key = kEnableCFArrayGetValueAtIndexHook;
      break;
    case 185:
      key = kEnableCFDataCreateHook;
      break;
    case 186:
      key = kEnableCFDictionaryCreateCopyHook;
      break;
    case 187:
      key = kEnableCFDictionarySetValueHook;
      break;
    case 188:
      key = kEnableCFDictionaryGetValueHook;
      break;
    case 189:
      key = kEnableCFUUIDCreateHook;
      break;
  default:
    return;
  }

  prefs[key] = @(sender.on);
  [self savePreferences:prefs];

  NSLog(@"[nakeapp] Hook switch changed: %@ = %@", key,
        sender.on ? @"ON" : @"OFF");
}

- (void)globalSwitchChanged:(UISwitch *)sender {
  NSMutableDictionary *prefs = [self loadPreferences];
  prefs[@"global_monitoring"] = @(sender.on);
  [self savePreferences:prefs];

  NSLog(@"[nakeapp] Global monitoring %@",
        sender.on ? @"ENABLED" : @"DISABLED");
}

#pragma mark - App List

- (void)showAppList {
  UITableViewController *appListController =
      [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
  appListController.title = @"应用列表";

  NSMutableArray *appList = [NSMutableArray array];

  @try {
    LSApplicationWorkspace *workspace =
        [LSApplicationWorkspace defaultWorkspace];
    NSArray *applications = [workspace allApplications];

    for (LSApplicationProxy *app in applications) {
      NSString *bundleId = [app applicationIdentifier] ?: @"Unknown";
      BOOL isSystem = [bundleId hasPrefix:@"com.apple"];
      if (isSystem) {
        continue;
      }

      NSString *appName = [app localizedName] ?: bundleId;
      NSDictionary *appInfo = @{@"name" : appName, @"bundleId" : bundleId};
      [appList addObject:appInfo];
    }

    // 按名称排序
    [appList sortUsingComparator:^NSComparisonResult(NSDictionary *obj1,
                                                     NSDictionary *obj2) {
      return [obj1[@"name"] compare:obj2[@"name"]];
    }];

  } @catch (NSException *exception) {
    NSLog(@"[nakeapp] Error getting app list: %@", exception);
  }

  // 创建应用列表视图控制器
  NKAAppListViewController *listVC =
      [[NKAAppListViewController alloc] initWithStyle:UITableViewStyleGrouped];
  listVC.appList = appList;
  listVC.title = [NSString
      stringWithFormat:@"已安装应用 (%lu个)", (unsigned long)appList.count];

  [self.navigationController pushViewController:listVC animated:YES];
}

@end

#pragma mark - App List View Controller

@implementation NKAAppListViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return self.appList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"AppCell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                  reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }

  // 移除旧的 switch
  for (UIView *subview in cell.contentView.subviews) {
    if ([subview isKindOfClass:[UISwitch class]]) {
      [subview removeFromSuperview];
    }
  }

  NSDictionary *appInfo = self.appList[indexPath.row];
  NSString *appName = appInfo[@"name"];
  NSString *bundleId = appInfo[@"bundleId"];

  cell.textLabel.text = appName;
  cell.detailTextLabel.text = bundleId;
  cell.detailTextLabel.textColor = [UIColor grayColor];

  UISwitch *switchControl = [[UISwitch alloc] init];
  switchControl.tag = indexPath.row;

  // 读取当前状态
  NSDictionary *prefs =
      [NSDictionary dictionaryWithContentsOfFile:kPreferencePath];
  NSString *key = [NSString stringWithFormat:@"app_switch_%@", bundleId];
  NSNumber *value = prefs[key];
  switchControl.on = value ? [value boolValue] : NO; // 默认关闭

  [switchControl addTarget:self
                    action:@selector(appSwitchChanged:)
          forControlEvents:UIControlEventValueChanged];
  cell.accessoryView = switchControl;

  return cell;
}

- (void)appSwitchChanged:(UISwitch *)sender {
  NSInteger index = sender.tag;
  if (index < 0 || index >= self.appList.count) {
    return;
  }

  NSDictionary *appInfo = self.appList[index];
  NSString *bundleId = appInfo[@"bundleId"];

  NSMutableDictionary *prefs =
      [NSMutableDictionary dictionaryWithContentsOfFile:kPreferencePath];
  if (!prefs) {
    prefs = [NSMutableDictionary dictionary];
  }

  NSString *key = [NSString stringWithFormat:@"app_switch_%@", bundleId];
  prefs[key] = @(sender.on);
  [prefs writeToFile:kPreferencePath atomically:YES];

  NSLog(@"[nakeapp] App switch changed: %@ = %@", bundleId,
        sender.on ? @"ON" : @"OFF");
}

@end
