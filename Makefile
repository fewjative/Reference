ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = Reference
Reference_FILES = Tweak.xm ReferenceController.m
Reference_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore
Reference_CFLAGS = -Wno-error
export GO_EASY_ON_ME := 1
include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += ReferenceSettings
include $(THEOS_MAKE_PATH)/aggregate.mk

before-stage::
	find . -name ".DS_STORE" -delete
after-install::
	install.exec "killall -9 backboardd"
