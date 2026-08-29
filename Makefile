export THEOS_PACKAGE_SCHEME = roothide

TARGET = iphone:latest:15.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppsFlyerDefeat
AppsFlyerDefeat_FILES = Tweak.x
AppsFlyerDefeat_CFLAGS = -fobjc-arc -Wall

# Debug logging off unless: make DEBUG_LOG=1
ifeq ($(DEBUG_LOG),1)
AppsFlyerDefeat_CFLAGS += -DAFD_DEBUG=1
endif

include $(THEOS_MAKE_PATH)/tweak.mk
