set(ENUM_TEMPLATES INTERFACE_LIB)

set(TARGET_PARAMETERS 
	LIBPAR	SCALAR	INTEGER	23
)

set(LINK_PARAMETERS 
)

set(FILE_OPTIONS
#	EXPORTED_VARIABLES LIB_MYVAR
)

function(declare_dependencies TEMPLATE_NAME)
	build_target(NESTED_INTERFACE_LIB)
endfunction()

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	add_library(${TARGET_NAME} INTERFACE)
	target_compile_definitions(${TARGET_NAME} INTERFACE "LIBPAR=${LIBPAR}")
endfunction()

#function(apply_dependency_to_target DEPENDEE_TARGET_NAME OUR_TARGET_NAME)
#	
#endfunction()
