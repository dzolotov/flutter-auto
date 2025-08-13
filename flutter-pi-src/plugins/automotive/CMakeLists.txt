# Automotive CAN Bus Plugin

target_sources(flutterpi PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../../src/plugins/automotive_plugin.c
)

target_include_directories(flutterpi PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../../src/plugins
)