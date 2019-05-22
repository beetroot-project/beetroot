set(ENUM_TEMPLATES HEADER_LIB)

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	message(STATUS "HEADER_LIB: inside generate_targets trying to define ${TARGET_NAME} in ${CMAKE_CURRENT_SOURCE_DIR}/include")
	
	add_library(${TARGET_NAME} INTERFACE)
	target_sources(${TARGET_NAME} INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include/header_lib.h)
	target_include_directories(${TARGET_NAME} INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)
endfunction()

