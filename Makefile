TARGET = :clang:7.0
ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

TWEAK_NAME = SBPower
SBPower_FILES = SBPower.m
SBPower_FRAMEWORKS = UIKit CoreGraphics
SBPower_LIBRARIES = activator

include $(THEOS_MAKE_PATH)/tweak.mk