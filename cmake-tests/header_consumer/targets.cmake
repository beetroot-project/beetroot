set(ENUM_TEMPLATES HEADER_CONSUMER)

function(declare_dependencies TEMPLATE_NAME)
	build_target(HEADER_LIB)
endfunction()

function(generate_targets TEMPLATE_NAME)
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/consumer.cpp")
endfunction()

