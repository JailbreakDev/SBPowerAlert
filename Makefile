export ARCHS = armv7 arm64
export TARGET := iphone:clang:9.0:7.0
export THEOS_DEVICE_IP = iPhone6s
include theos/makefiles/common.mk

TWEAK_NAME = SBPowerAlert
SBPowerAlert_FILES = SBPowerAlert.m SBPowerAlertItem.m
SBPowerAlert_FRAMEWORKS = UIKit CoreGraphics SystemConfiguration
SBPowerAlert_PRIVATE_FRAMEWORKS = SpringBoardUI CoreTelephony
SBPowerAlert_LIBRARIES = activator MobileGestalt
SBPowerAlert_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += sbpoweralertsettings
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	
	$(ECHO_NOTHING)mkdir -p ./_/Library/Activator/Listeners/$(ECHO_END)
	$(ECHO_NOTHING)cp -r com.sharedroutine.sbpoweralert ./_/Library/Activator/Listeners/com.sharedroutine.sbpoweralert$(ECHO_END)

after-install::
	install.exec "killall -9 SpringBoard"
