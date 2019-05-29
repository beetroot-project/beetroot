set(ENUM_TEMPLATES EMPTY_LIB)

set(TARGET_PARAMETERS 
)

set(LINK_PARAMETERS 
	LIBPAR	SCALAR	INTEGER	23
)

set(TEMPLATE_OPTIONS
#	DONT_LINK_TO_DEPENDEE
)

function(declare_dependencies TEMPLATE_NAME)
	build_target(NESTED_EMPTY_LIB)
endfunction()

function(apply_dependency_to_target DEPENDEE_TARGET_NAME OUR_TARGET_NAME)
	target_compile_definitions(${DEPENDEE_TARGET_NAME} ${KEYWORD} "LIBPAR=${LIBPAR}")
	message(STATUS "EMPTY_LIB: inside apply_dependency_to_target in ${CMAKE_CURRENT_SOURCE_DIR}, OUR_TARGET_NAME: ${OUR_TARGET_NAME}")

endfunction()
