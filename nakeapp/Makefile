TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = nakeApp

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = nakeApp

nakeApp_FILES = main.m NKAAppDelegate.m NKARootViewController.m
nakeApp_FRAMEWORKS = UIKit CoreGraphics MobileCoreServices
nakeApp_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
