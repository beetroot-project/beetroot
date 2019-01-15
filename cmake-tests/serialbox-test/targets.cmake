set(ENUM_TEMPLATES SERIALBOX_C_TEST)

function(declare_dependencies TEMPLATE_NAME)
	build_target(Serialbox::SerialboxCStatic)
endfunction()

function(generate_targets TEMPLATE_NAME)
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/example-01-laplacian.c")
endfunction()

