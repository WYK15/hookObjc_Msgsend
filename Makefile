TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

# THEOS_DEVICE_IP = 172.16.23.36
# THEOS_DEVICE_PORT = 22

#  `make clean package ROOTLESS=1` to compile rootless
ifeq ($(ROOTLESS),1)
THEOS_PACKAGE_SCHEME=rootless
endif

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
	ARCHS = arm64 arm64e
	TARGET = iphone:clang:latest:15.0
else
#	ARCHS = armv7 armv7s arm64 arm64e
	ARCHS = arm64
	TARGET = iphone:clang:latest:7.0
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hookObjcMsgsend

hookObjcMsgsend_FILES = Tweak.xm fishhook/fishhook.c
hookObjcMsgsend_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
