set(ENUM_TEMPLATES SERIALBOX_C_TEST2)

function(declare_dependencies TEMPLATE_NAME)
	message(STATUS "Inside declare_dependencies() for SERIALBOX_C_TEST.")
	get_existing_target(Serialbox::SerialboxCStatic)
endfunction()

function(generate_targets TEMPLATE_NAME)
	if(NOT Serialbox_SerialboxCStatic_INSTALL_DIR)
		message(FATAL_ERROR "Passing INSTALL_DIR of the dependency does not work")
	endif()
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/example-01-laplacian.c")
endfunction()

