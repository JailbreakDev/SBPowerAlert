TARGET = :clang:7.0
ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

TWEAK_NAME = SBPowerAlert
SBPowerAlert_FILES = SBPowerAlert.m
SBPowerAlert_FRAMEWORKS = UIKit CoreGraphics SystemConfiguration
SBPowerAlert_LIBRARIES = activator MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk
