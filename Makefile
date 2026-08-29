export THEOS_PACKAGE_SCHEME = roothide

TARGET = iphone:latest:15.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppsFlyerShim
AppsFlyerShim_FILES = Tweak.x
AppsFlyerShim_CFLAGS = -fobjc-arc -Wall

ifneq ($(FINALPACKAGE),1)
AppsFlyerShim_CFLAGS += -DAFD_DEBUG=1
endif

include $(THEOS_MAKE_PATH)/tweak.mk
