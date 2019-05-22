set(ENUM_TEMPLATES IMPLICIT_VARS_SUBTARGET)

include_features_of(JUST_VAR_LIB)

set(TARGET_PARAMETERS 
	IMPLICIT_GLOBAL	SCALAR	STRING	"default_implicit_global"
	IMPLICIT_LOCAL	SCALAR	STRING	"default_implicit_local"
)

set(LINK_PARAMETERS 
	IMPLICIT_LINK	SCALAR	STRING	"default_implicit_link"
)

set(TEMPLATE_OPTIONS
)

function(declare_dependencies TEMPLATE_NAME)
	if("${IMPLICIT_GLOBAL}" STREQUAL "default_implicit_global")
		message(FATAL_ERROR "IMPLICIT_GLOBAL was not overriden")
	endif()
	if("${IMPLICIT_LOCAL}" STREQUAL "default_implicit_local")
		message(FATAL_ERROR "IMPLICIT_LOCAL was not overriden")
	endif()
	if("${IMPLICIT_IMPORTED}" STREQUAL "default_implicit_imported")
		message(FATAL_ERROR "IMPLICIT_IMPORTED was not overriden")
	endif()
	message(STATUS "IMPLICIT_VARS_SUBTARGET: making promise EXPORT_VAR...")
	get_existing_target(EXPORT_VAR)
endfunction()

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	if("${IMPLICIT_GLOBAL}" STREQUAL "default_implicit_global")
		message(FATAL_ERROR "IMPLICIT_GLOBAL was not overriden")
	endif()
	if("${IMPLICIT_LOCAL}" STREQUAL "default_implicit_local")
		message(FATAL_ERROR "IMPLICIT_LOCAL was not overriden")
	endif()
	if("${IMPLICIT_IMPORTED}" STREQUAL "default_implicit_imported")
		message(FATAL_ERROR "IMPLICIT_IMPORTED was not overriden")
	endif()
	if(NOT "${IMPLICIT_EXPORTED_DEFAULT}" STREQUAL "default_implicit_exported_default")
		message(FATAL_ERROR "wrong value for IMPLICIT_EXPORTED_DEFAULT: \"${IMPLICIT_EXPORTED_DEFAULT}\"")
	endif()
	if("${IMPLICIT_EXPORTED}" STREQUAL "default_implicit_exported")
		message(FATAL_ERROR "IMPLICIT_EXPORTED was not overriden")
	endif()
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/source.cpp")
endfunction()


function(apply_dependency_to_target DEPENDEE_TARGET_NAME OUR_TARGET_NAME)
	if("${IMPLICIT_GLOBAL}" STREQUAL "default_implicit_global")
		message(FATAL_ERROR "IMPLICIT_GLOBAL was not overriden")
	endif()
	if("${IMPLICIT_LOCAL}" STREQUAL "default_implicit_local")
		message(FATAL_ERROR "IMPLICIT_LOCAL was not overriden")
	endif()
	if("${IMPLICIT_IMPORTED}" STREQUAL "default_implicit_imported")
		message(FATAL_ERROR "IMPLICIT_IMPORTED was not overriden")
	endif()
	if("${IMPLICIT_LINK}" STREQUAL "default_implicit_link")
		message(FATAL_ERROR "IMPLICIT_IMPORTED was not overriden")
	endif()
	if(NOT "${IMPLICIT_EXPORTED_DEFAULT}" STREQUAL "default_implicit_exported_default")
		message(FATAL_ERROR "wrong value for IMPLICIT_EXPORTED_DEFAULT: \"${IMPLICIT_EXPORTED_DEFAULT}\"")
	endif()
	if("${IMPLICIT_EXPORTED}" STREQUAL "default_implicit_exported")
		message(FATAL_ERROR "IMPLICIT_EXPORTED was not overriden")
	endif()
endfunction()
