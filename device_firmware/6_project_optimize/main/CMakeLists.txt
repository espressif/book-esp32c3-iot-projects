set(srcs "app_main.c"
                    "app_pm.c"
                    "app_driver.c")
set(include_dirs "include")
set(DEVELOPMENT_BOARD "board_esp32c3_devkitc.h")

idf_component_register(SRCS "${srcs}"
                    INCLUDE_DIRS "${include_dirs}")

target_add_binary_data(${COMPONENT_TARGET} "server.crt" TEXT)

idf_build_set_property(COMPILE_DEFINITIONS "-DDEVELOPMENT_BOARD=\"${DEVELOPMENT_BOARD}\"" APPEND)
