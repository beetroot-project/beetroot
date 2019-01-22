function(get_version_from_git_tag)
	set(options )
	set(oneValueArgs PATH OUT)
	set(multiValueArgs )
	cmake_parse_arguments(GVFGT "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")
	if(GVFGT_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "function build_install_prefix: unparsed arguments: ${GVFGT_UNPARSED_ARGUMENTS}")
	endif()

	execute_process(COMMAND /bin/bash -c "git describe --tags $(git rev-parse --verify HEAD)"
					WORKING_DIRECTORY "${GVFGT_PATH}"
					RESULT_VARIABLE RESULT
					OUTPUT_STRIP_TRAILING_WHITESPACE
					OUTPUT_VARIABLE VERSION)

	if(NOT "${RESULT}" EQUAL "0")
		message(FATAL_ERROR "${GVFGT_PATH} version unknown")
	endif()
	set(${GVFGT_OUT} "${VERSION}" PARENT_SCOPE)
endfunction()
