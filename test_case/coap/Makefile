#
# This is a project Makefile. It is assumed the directory this Makefile resides in is a
# project subdirectory.
#

PROJECT_NAME := coap

DEVELOPMENT_BOARD := board_esp32c3_devkitc.h
EXTRA_COMPONENT_DIRS += $(PROJECT_PATH)/../../Project/components/light_driver
EXTRA_COMPONENT_DIRS += $(PROJECT_PATH)/../../Project/components/button
EXTRA_COMPONENT_DIRS += $(PROJECT_PATH)/../../Project/components/app_storage

include $(IDF_PATH)/make/project.mk
CPPFLAGS += -DDEVELOPMENT_BOARD=\"$(DEVELOPMENT_BOARD)\"
