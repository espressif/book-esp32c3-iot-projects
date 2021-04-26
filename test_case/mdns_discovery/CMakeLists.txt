# The following lines of boilerplate have to be in your project's
# CMakeLists in this exact order for cmake to work correctly
cmake_minimum_required(VERSION 3.5)

add_compile_options(-fdiagnostics-color=always)

# Add common application components
set(EXTRA_COMPONENT_DIRS ${CMAKE_CURRENT_LIST_DIR}/../../Project/components/light_driver
                        ${CMAKE_CURRENT_LIST_DIR}/../../Project/components/button
                        ${CMAKE_CURRENT_LIST_DIR}/../../Project/components/app_storage
                        )

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(mdns_discovery)
