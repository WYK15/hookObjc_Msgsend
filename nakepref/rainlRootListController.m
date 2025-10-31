#import <Foundation/Foundation.h>
#import "rainlRootListController.h"
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <rootless.h>

static NSString *const kPreferenceAppPath = @"/var/mobile/Library/Preferences/com.rainl.nake.apps.plist";

@implementation rainlRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

// 开关状态变化时的回调方法
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    // 调用父类方法保存设置
    [super setPreferenceValue:value specifier:specifier];
}

// 获取偏好设置文件路径
- (NSString*)getPreferencesPath {
    return ROOT_PATH_NS(kPreferenceAppPath);
}

// 从plist文件加载配置
- (NSMutableDictionary*)loadAppPreferences {
    NSString *prefsPath = [self getPreferencesPath];
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:prefsPath];
    return prefs ?: [NSMutableDictionary dictionary];
}

// 保存配置到plist文件
- (void)saveAppPreferences:(NSDictionary*)prefs {
    NSString *prefsPath = [self getPreferencesPath];
    [prefs writeToFile:prefsPath atomically:YES];
}

// 全局监控开关管理
- (void)setGlobalMonitoringEnabled:(id)value forSpecifier:(PSSpecifier *)specifier {
    @try {
        BOOL enabled = [value boolValue];
        NSMutableDictionary *prefs = [self loadAppPreferences];
        prefs[@"global_monitoring"] = @(enabled);
        [self saveAppPreferences:prefs];
        NSLog(@"Global monitoring %@", enabled ? @"ENABLED" : @"DISABLED");
    } @catch (NSException *exception) {
        NSLog(@"Error in setGlobalMonitoringEnabled: %@", exception);
    }
}

- (id)getGlobalMonitoringEnabled:(PSSpecifier *)specifier {
    @try {
        NSMutableDictionary *prefs = [self loadAppPreferences];
        NSNumber *value = prefs[@"global_monitoring"];
        BOOL enabled = value ? [value boolValue] : YES;  // 默认开启
        NSLog(@"Global monitoring state: %@", enabled ? @"ENABLED" : @"DISABLED");
        return @(enabled);
    } @catch (NSException *exception) {
        NSLog(@"Error in getGlobalMonitoringEnabled: %@", exception);
    }
    return @YES;
}

// 开关状态管理
- (void)setAppSwitchEnabled:(id)value forSpecifier:(PSSpecifier *)specifier {
    @try {
        NSString *bundleId = specifier.properties[@"key"];
        if (bundleId) {
            BOOL enabled = [value boolValue];
            NSString *key = [NSString stringWithFormat:@"app_switch_%@", bundleId];
            NSMutableDictionary *prefs = [self loadAppPreferences];
            prefs[key] = @(enabled);
            [self saveAppPreferences:prefs];
            NSLog(@"App switch changed: %@ = %@", bundleId, enabled ? @"ON" : @"OFF");
        } else {
            NSLog(@"Warning: No bundle ID found in specifier properties");
        }
    } @catch (NSException *exception) {
        NSLog(@"Error in setAppSwitchEnabled: %@", exception);
    }
}

- (id)getAppSwitchEnabledForSpecifier:(PSSpecifier *)specifier {
    @try {
        NSString *bundleId = specifier.properties[@"key"];
        if (bundleId) {
            NSString *key = [NSString stringWithFormat:@"app_switch_%@", bundleId];
            NSMutableDictionary *prefs = [self loadAppPreferences];
            NSNumber *value = prefs[key];
            BOOL enabled = value ? [value boolValue] : NO;  // 默认关闭
            //NSLog(@"App switch state for %@: %@", bundleId, enabled ? @"ON" : @"OFF");
            return @(enabled);
        }
    } @catch (NSException *exception) {
        NSLog(@"Error in getAppSwitchEnabledForSpecifier: %@", exception);
    }
    return @NO;
}

// 显示应用列表
- (void)showAppList {
    NSMutableArray *appList = [NSMutableArray array];
    
    @try {
        // 使用私有API获取所有应用
        LSApplicationWorkspace *workspace = [LSApplicationWorkspace defaultWorkspace];
        NSArray *applications = [workspace allApplications];
        
        for (LSApplicationProxy *app in applications) {
			NSString *bundleId = [app applicationIdentifier] ?: @"Unknown";
			BOOL isSystem = [bundleId hasPrefix:@"com.apple"];
			if (isSystem) {
                continue;
            }
			
			NSString *appName = [app localizedName] ?: bundleId;
			
			NSString *appInfo = [NSString stringWithFormat:@"%@ - %@", appName, bundleId];
			[appList addObject:appInfo];
        }
        
        // 按名称排序
        [appList sortUsingSelector:@selector(compare:)];
        
    } @catch (NSException *exception) {
        [appList addObject:[NSString stringWithFormat:@"获取应用列表失败: %@", exception.reason]];
    }
    
    // 创建显示控制器
    PSListController *appListController = [[PSListController alloc] init];
    NSMutableArray *specifiers = [NSMutableArray array];
    
    // 添加全局开关
    PSSpecifier *globalSwitch = [PSSpecifier preferenceSpecifierNamed:@"全局监控开关" 
                                                               target:self 
                                                                  set:@selector(setGlobalMonitoringEnabled:forSpecifier:) 
                                                                  get:@selector(getGlobalMonitoringEnabled:) 
                                                               detail:nil 
                                                                 cell:PSSwitchCell 
                                                                edit:nil];
    [globalSwitch setProperty:@"global_monitoring" forKey:@"key"];
    [globalSwitch setProperty:@YES forKey:@"default"];
    [specifiers addObject:globalSwitch];
    
    // 添加标题
    PSSpecifier *groupSpec = [PSSpecifier groupSpecifierWithName:[NSString stringWithFormat:@"已安装应用 (%lu个)", (unsigned long)appList.count]];
    [specifiers addObject:groupSpec];
    
    // 添加应用列表
    for (NSString *appInfo in appList) {
        // 提取 bundle ID 作为开关的唯一标识符
        NSString *bundleId = nil;
        NSArray *components = [appInfo componentsSeparatedByString:@" - "];
        if (components.count >= 2) {
            bundleId = components[1];
        }
        
        if (bundleId) {
            // 创建开关类型的 specifier
            PSSpecifier *switchSpec = [PSSpecifier preferenceSpecifierNamed:appInfo 
                                                                    target:self 
                                                                       set:@selector(setAppSwitchEnabled:forSpecifier:) 
                                                                       get:@selector(getAppSwitchEnabledForSpecifier:) 
                                                                    detail:nil 
                                                                      cell:PSSwitchCell 
                                                                     edit:nil];
            [switchSpec setProperty:bundleId forKey:@"key"];
            [switchSpec setProperty:@NO forKey:@"default"];
            [specifiers addObject:switchSpec];
        }
    }

	NSLog(@"specifiers: %@", specifiers);
    
    [appListController setSpecifiers:specifiers];
    [appListController setTitle:@"应用列表"];
    
    // 推送显示 - 使用导航控制器
    [self.navigationController pushViewController:appListController animated:YES];
}

@end
