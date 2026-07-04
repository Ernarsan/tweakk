export THEOS_DEVICE_IP = 127.0.0.1
export THEOS_DEVICE_PORT = 22

TARGET = iphone:clang:latest
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = standoff2_cheat

standoff2_cheat_FILES = Tweak.xm
standoff2_cheat_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -DGLES_SILENCE_DEPRECATION
standoff2_cheat_FRAMEWORKS = UIKit OpenGLES QuartzCore CoreGraphics Foundation
standoff2_cheat_PRIVATE_FRAMEWORKS = BackBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Standoff2"
