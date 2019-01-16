set(TARGET_PARAMETERS 
	SERIALBOX_ENABLE_FORTRAN SCALAR	"BOOL" "YES"
	SERIALBOX_USE_NETCDF	SCALAR	"BOOL" "NO"
	SERIALBOX_ENABLE_EXPERIMENTAL_FILESYSTEM	SCALAR	BOOL	"YES"
	SERIALBOX_EXAMPLES	SCALAR	BOOL	"NO"
)

if(SUPPORT_FORTRAN)
	set(SERIALBOX_FORTRAN Serialbox::SerialboxFortranStatic)
else()
	set(SERIALBOX_FORTRAN )
endif()

set(ENUM_TARGETS Serialbox::SerialboxStatic Serialbox::SerialboxCStatic ${SERIALBOX_FORTRAN})

set(DEFINE_EXTERNAL_PROJECT 
	NAME Serialbox
	PATH "${SUPERBUILD_ROOT}/serialbox2"
	EXPORTS_TARGETS
	WHAT_COMPONENTS_NAME_DEPENDS_ON boost;compiler
)

function(declare_dependencies TEMPLATE_NAME)
	if(SERIALBOX_ENABLE_EXPERIMENTAL_FILESYSTEM)
		build_target(Boost::system)
		build_target(Boost::filesystem)
	endif()
endfunction()

#function(apply_to_target TARGET_NAME)
#	target_compile_definitions(${TARGET_NAME} PRIVATE "BOOST_MPL_CFG_NO_PREPROCESSED_HEADERS=1")
#	target_compile_definitions(${TARGET_NAME} PRIVATE "BOOST_MPL_LIMIT_VECTOR_SIZE=${FUSION_MAX_VECTOR_SIZE}")
#endfunction()

