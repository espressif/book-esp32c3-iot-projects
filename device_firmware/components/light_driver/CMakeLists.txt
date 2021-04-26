
idf_component_register(SRCS "./light_driver.c" "./iot_led.c"
                    INCLUDE_DIRS "." "./include"
                    REQUIRES app_storage
)
