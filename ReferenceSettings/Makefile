ARCHS = armv7 arm64
$(shell install_name_tool -id /usr/lib/libcolorpicker_Reference.dylib lib/libcolorpicker.dylib)
include theos/makefiles/common.mk

BUNDLE_NAME = ReferenceSettings
ReferenceSettings_FILES = ReferenceSettings.mm
ReferenceSettings_INSTALL_PATH = /Library/PreferenceBundles
ReferenceSettings_FRAMEWORKS = UIKit CoreGraphics QuartzCore
ReferenceSettings_PRIVATE_FRAMEWORKS = Preferences
ReferenceSettings_LDFLAGS = -Llib -lcolorpicker

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ReferenceSettings.plist$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/usr/lib/$(ECHO_END)
	$(ECHO_NOTHING)cp lib/libcolorpicker.dylib $(THEOS_STAGING_DIR)/usr/lib/libcolorpicker_Reference.dylib$(ECHO_END)

include $(THEOS_MAKE_PATH)/aggregate.mk
