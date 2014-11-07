ARCHS = armv7 arm64
TARGET := iphone:clang:8.1
THEOS_DEVICE_IP = iPad
include theos/makefiles/common.mk

TWEAK_NAME = SBPowerAlert
SBPowerAlert_FILES = SBPowerAlert.m SBPowerAlertItem.m
SBPowerAlert_FRAMEWORKS = UIKit CoreGraphics SystemConfiguration
SBPowerAlert_PRIVATE_FRAMEWORKS = SpringBoardUI
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