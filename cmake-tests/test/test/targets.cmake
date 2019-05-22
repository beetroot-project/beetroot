set(ENUM_TEMPLATES SELF_TEST_TEST)

set(TARGET_PARAMETERS 
)

set(TEMPLATE_OPTIONS
	NO_TARGETS
)

function(declare_dependencies TARGET_NAME)
	build_target(SELF_TEST)
endfunction()

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	get_target(SELF_TEST SELF_TEST_DRIVER)

	file(WRITE  "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.sh" "#!/bin/sh\n")
	file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.sh" "./${SELF_TEST_DRIVER}.sh")
	
	add_test(NAME ${TARGET_NAME} COMMAND /bin/sh ${TARGET_NAME}.sh
		WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
	)
endfunction()

