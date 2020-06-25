INSTALL_TARGET_PROCESSES = SpringBoard

THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222

ARCHS = arm64 #arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Shortcuts

Shortcuts_FILES = Tweak.x
Shortcuts_CFLAGS = -fobjc-arc
Shortcuts_LIBRARIES = mryipc

include $(THEOS_MAKE_PATH)/tweak.mk
