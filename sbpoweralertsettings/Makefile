ARCHS = armv7 arm64
include theos/makefiles/common.mk

BUNDLE_NAME = SBPowerAlertSettings
SBPowerAlertSettings_FILES = SBPowerAlertSettings.mm
SBPowerAlertSettings_INSTALL_PATH = /Library/PreferenceBundles
SBPowerAlertSettings_FRAMEWORKS = UIKit
SBPowerAlertSettings_PRIVATE_FRAMEWORKS = Preferences
SBPowerAlertSettings_CFLAGS = -w

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SBPowerAlertSettings.plist$(ECHO_END)
