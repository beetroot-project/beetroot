set(DEFINE_MODIFIERS 
	SERIALBOX_ENABLE_FORTRAN SCALAR	"BOOL" "YES"
)

set(ENUM_TEMPLATES SERIALBOX_TEST)

function(declare_dependencies TEMPLATE_NAME)
	build_target(Serialbox::SerialboxCStatic SERIALBOX_ENABLE_FORTRAN "${SERIALBOX_ENABLE_FORTRAN}" )
endfunction()

function(generate_targets TEMPLATE_NAME)
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/example-01-laplacian.c")
endfunction()

