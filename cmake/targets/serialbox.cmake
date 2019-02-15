set(ENUM_TARGETS Serialbox::SerialboxStatic Serialbox::SerialboxCStatic Serialbox::SerialboxFortranStatic)

set(TARGET_PARAMETERS 
)

set(TARGET_FEATURES 
	SERIALBOX_ENABLE_FORTRAN SCALAR	"BOOL" "NO"
	SERIALBOX_USE_NETCDF	SCALAR	"BOOL" "NO"
	SERIALBOX_EXAMPLES	SCALAR	BOOL	"NO"
	SERIALBOX_ENABLE_EXPERIMENTAL_FILESYSTEM	SCALAR	BOOL	"NO"
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

