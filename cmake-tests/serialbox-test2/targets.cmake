set(ENUM_TEMPLATES SERIALBOX_C_TEST2)

include_features_of(Serialbox)

set(TARGET_FEATURES 
	PAM_TARAM SCALAR	"STRING" "WARTOSC"
)

function(declare_dependencies TEMPLATE_NAME)
	message(STATUS "declare_dependencies(): PAM_TARAM: ${PAM_TARAM}")
	message(STATUS "Inside declare_dependencies() for SERIALBOX_C_TEST.")
	message(STATUS "declare_dependencies(): SERIALBOX_ENABLE_FORTRAN: ${SERIALBOX_ENABLE_FORTRAN}")
	get_existing_target(Serialbox::SerialboxCStatic)
endfunction()

function(generate_targets TEMPLATE_NAME)
	if(NOT Serialbox_SerialboxCStatic_INSTALL_DIR)
		message(FATAL_ERROR "Passing INSTALL_DIR of the dependency does not work")
	endif()
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/example-01-laplacian.c")
endfunction()


