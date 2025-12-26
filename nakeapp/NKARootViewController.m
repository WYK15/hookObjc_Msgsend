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
static NSString *const kEnableSystemFunctionsHook = @"enableSystemFunctions";
static NSString *const kEnableCryptoFunctionsHook = @"enableCryptoFunctions";
static NSString *const kEnableHostInfoFunctionsHook = @"enableHostInfoFunctions";
static NSString *const kEnableCFStringFunctionsHook = @"enableCFStringFunctions";
static NSString *const kEnableCFURLFunctionsHook = @"enableCFURLFunctions";
static NSString *const kEnableTimeFunctionsHook = @"enableTimeFunctions";
static NSString *const kEnableKeychainFunctionsHook = @"enableKeychainFunctions";

@interface NKARootViewController ()
@property (nonatomic, strong) UISwitch *objcMsgSendSwitch;
@property (nonatomic, strong) UISwitch *accessSwitch;
@property (nonatomic, strong) UISwitch *dlopenSwitch;
@property (nonatomic, strong) UISwitch *res9InitSwitch;
@property (nonatomic, strong) UISwitch *classGetClassMethodSwitch;
@property (nonatomic, strong) UISwitch *selRegisterNameSwitch;
@property (nonatomic, strong) UISwitch *cfNetworkCopySystemProxySettingsSwitch;

// 新增的 Hook 开关属性
@property (nonatomic, strong) UISwitch *systemFunctionsSwitch;
@property (nonatomic, strong) UISwitch *cryptoFunctionsSwitch;
@property (nonatomic, strong) UISwitch *hostInfoFunctionsSwitch;
@property (nonatomic, strong) UISwitch *cfStringFunctionsSwitch;
@property (nonatomic, strong) UISwitch *cfURLFunctionsSwitch;
@property (nonatomic, strong) UISwitch *timeFunctionsSwitch;
@property (nonatomic, strong) UISwitch *keychainFunctionsSwitch;
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
    return 14; // 7个原有 Hook 开关 + 7个新增 Hook 开关
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
    case 7:
      title = @"启用系统函数 Hook (fopen, getenv, etc.)";
      key = kEnableSystemFunctionsHook;
      tag = 107;
      break;
    case 8:
      title = @"启用加密函数 Hook (CC_SHA256)";
      key = kEnableCryptoFunctionsHook;
      tag = 108;
      break;
    case 9:
      title = @"启用主机信息 Hook (host_info, etc.)";
      key = kEnableHostInfoFunctionsHook;
      tag = 109;
      break;
    case 10:
      title = @"启用 CFString Hook";
      key = kEnableCFStringFunctionsHook;
      tag = 110;
      break;
    case 11:
      title = @"启用 CFURL Hook";
      key = kEnableCFURLFunctionsHook;
      tag = 111;
      break;
    case 12:
      title = @"启用时间函数 Hook (CACurrentMediaTime)";
      key = kEnableTimeFunctionsHook;
      tag = 112;
      break;
    case 13:
      title = @"启用 Keychain Hook";
      key = kEnableKeychainFunctionsHook;
      tag = 113;
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
    switchControl.on = value ? [value boolValue] : YES; // 默认开启

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
    case 107:
      self.systemFunctionsSwitch = switchControl;
      break;
    case 108:
      self.cryptoFunctionsSwitch = switchControl;
      break;
    case 109:
      self.hostInfoFunctionsSwitch = switchControl;
      break;
    case 110:
      self.cfStringFunctionsSwitch = switchControl;
      break;
    case 111:
      self.cfURLFunctionsSwitch = switchControl;
      break;
    case 112:
      self.timeFunctionsSwitch = switchControl;
      break;
    case 113:
      self.keychainFunctionsSwitch = switchControl;
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
  case 107:
    key = kEnableSystemFunctionsHook;
    break;
  case 108:
    key = kEnableCryptoFunctionsHook;
    break;
  case 109:
    key = kEnableHostInfoFunctionsHook;
    break;
  case 110:
    key = kEnableCFStringFunctionsHook;
    break;
  case 111:
    key = kEnableCFURLFunctionsHook;
    break;
  case 112:
    key = kEnableTimeFunctionsHook;
    break;
  case 113:
    key = kEnableKeychainFunctionsHook;
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
