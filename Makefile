TARGET := iphone:16.5:14.0
#export ARCHS = arm64

# THEOS_DEVICE_IP=172.16.20.12
# THEOS_DEVICE_PORT=22

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += naketweak
SUBPROJECTS += nakeapp
include $(THEOS_MAKE_PATH)/aggregate.mk

all::

before-package::
	find $(THEOS_STAGING_DIR) -name ".DS_Store" -delete

stage::
	find . -name ".DS_Store" -delete


# compile:
# make clean && make package FINALPACKAGE=1
# make clean && make package THEOS_PACKAGE_SCHEME=rootless  FINALPACKAGE=1
