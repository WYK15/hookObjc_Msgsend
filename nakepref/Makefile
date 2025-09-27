# TARGET := iphone:16.5:14.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = nakePref

nakePref_FILES = rainlRootListController.m
nakePref_FRAMEWORKS = UIKit
nakePref_PRIVATE_FRAMEWORKS = Preferences
nakePref_INSTALL_PATH = /Library/PreferenceBundles
nakePref_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
