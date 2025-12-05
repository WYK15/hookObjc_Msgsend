#import "NKAAppDelegate.h"
#import "NKARootViewController.h"

@implementation NKAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[NKARootViewController alloc] init]];
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];
	return YES;
}

@end
