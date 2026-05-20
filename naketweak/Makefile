#TARGET := iphone:clang:latest:7.0
TARGET := iphone:16.5:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = nake

nake_FILES = hookobjcMsgsend.xm fishhook/fishhook.c hookcommon.x hookCrypt.x stdstringhook.xm hookNet.x Tweak.x
nake_CFLAGS =  -Wno-cast-of-sel-type -Wno-unused-function -Wno-deprecated-declarations -Wno-unused-variable
name_Frameworks = Security

include $(THEOS_MAKE_PATH)/tweak.mk
