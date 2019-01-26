set(ENUM_TARGETS Serialbox::SerialboxStatic Serialbox::SerialboxCStatic Serialbox::SerialboxFortranStatic)

set(TARGET_PARAMETERS 
	SERIALBOX_ENABLE_FORTRAN SCALAR	"BOOL" "YES"
	SERIALBOX_USE_NETCDF	SCALAR	"BOOL" "NO"
	SERIALBOX_ENABLE_EXPERIMENTAL_FILESYSTEM	SCALAR	BOOL	"YES"
	SERIALBOX_EXAMPLES	SCALAR	BOOL	"NO"
)

set(DEFINE_EXTERNAL_PROJECT 
	NAME Serialbox
	SOURCE_PATH "${SUPERBUILD_ROOT}/serialbox2"
	WHAT_COMPONENTS_NAME_DEPENDS_ON boost;compiler;serialbox
)

function(declare_dependencies TEMPLATE_NAME)
	if(SERIALBOX_ENABLE_EXPERIMENTAL_FILESYSTEM)
		build_target(Boost::system)
		build_target(Boost::filesystem)
	endif()
endfunction()

function(apply_dependency_to_target DEPENDEE_TARGET_NAME TARGET_NAME)
	if("${TARGET_NAME}" STREQUAL "Serialbox::SerialboxFortranStatic" AND NOT SERIALBOX_ENABLE_FORTRAN)
		message(FATAL_ERROR "To use Fortran, you must first pass target option SERIALBOX_ENABLE_FORTRAN")
	endif()
	target_link_libraries(${DEPENDEE_TARGET_NAME} ${KEYWORD} ${TARGET_NAME}) 
endfunction()

