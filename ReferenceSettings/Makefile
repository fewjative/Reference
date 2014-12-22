ARCHS = armv7 arm64
include theos/makefiles/common.mk

BUNDLE_NAME = ReferenceSettings
ReferenceSettings_FILES = ReferenceSettings.mm
ReferenceSettings_INSTALL_PATH = /Library/PreferenceBundles
ReferenceSettings_FRAMEWORKS = UIKit
ReferenceSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ReferenceSettings.plist$(ECHO_END)

include $(THEOS_MAKE_PATH)/aggregate.mk
