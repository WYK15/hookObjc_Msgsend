#import <Foundation/Foundation.h>
#import "rainlRootListController.h"

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

@end
