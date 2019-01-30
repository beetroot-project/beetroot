set(ENUM_TEMPLATES NESTED_INTERFACE_LIB)

set(TARGET_PARAMETERS 
	NESTED_LIBPAR	SCALAR	INTEGER	23
)

set(LINK_PARAMETERS 
)

set(TEMPLATE_OPTIONS
#	EXPORTED_VARIABLES LIB_MYVAR
)

function(generate_targets TEMPLATE_NAME)
	add_library(${TARGET_NAME} INTERFACE)
	message(STATUS "generate_targets for NESTED_EMPTY_LIB: NESTED_LIBPAR: ${NESTED_LIBPAR}")
	target_compile_definitions(${TARGET_NAME} INTERFACE "NESTED_LIBPAR=${NESTED_LIBPAR}")
endfunction()

#function(apply_dependency_to_target DEPENDEE_TARGET_NAME OUR_TARGET_NAME)
#	
#endfunction()
