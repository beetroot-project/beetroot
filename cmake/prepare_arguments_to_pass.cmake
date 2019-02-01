#Function, that takes list variable names (VAR_NAMES) and option names (OPTION_NAMES) makes a list, that can be passed as named arguments (without quotes, so it will be parsed as list).

function(prepare_arguments_to_pass )
	set(options )
	set(oneValueArgs  OUTVAR)
	set(multiValueArgs VAR_NAMES OPTION_NAMES)
	cmake_parse_arguments(__PATP "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

	set(unparsed ${__PATP_UNPARSED_ARGUMENTS})
	if(unparsed)
		message(FATAL_ERROR "function nice_list_output: unparsed arguments: ${unparsed}")
	endif()
	set(__OUT)
	if(__PATP_VAR_NAMES)
#		message(STATUS "prepare_arguments_to_pass(): __PATP_VAR_NAMES: ${__PATP_VAR_NAMES}")
		foreach(__VAR IN LISTS __PATP_VAR_NAMES)
#			message(STATUS "prepare_arguments_to_pass(): __VAR: ${__VAR}")
			if(NOT "${${__VAR}}" STREQUAL "")
#				message(STATUS "prepare_arguments_to_pass(): __VAR: ${__VAR}: ${${__VAR}}, __OUT: ${__OUT}")
				list(APPEND __OUT ${__VAR} "${${__VAR}}")
			endif()
		endforeach()
	endif()
	if(__PATP_OPTION_NAMES)
#		message(STATUS "prepare_arguments_to_pass(): __PATP_OPTION_NAMES: ${__PATP_OPTION_NAMES}")
		foreach(__VAR IN LISTS __PATP_OPTION_NAMES)
			if(${__VAR})
#				message(STATUS "prepare_arguments_to_pass(): __VAR: ${__VAR}, __OUT: ${__OUT}")
				list(APPEND __OUT ${__VAR})
			endif()
		endforeach()
	endif()
	set(${__PATP_OUTVAR} "${__OUT}" PARENT_SCOPE)
endfunction()

#Exampel syntax:
#	pass_compile_definitions_to_target(${TARGET_NAME} PRIVATE|PUBLIC|INTERFACE
#		VAR_NAMES <list of variables that will be passed as string>
#		OPTION_NAMES <list of variables that will be passed only as their existance (no value) if they are actually set>)
#
#Function passes listed CMake variables in 3rd and later arguments as preprocessor macros for TARGET_NAME passed as first argument.
#
function (pass_compile_definitions_to_target __TARGET_NAME __KEYWORD)
	set(options )
	set(oneValueArgs )
	set(multiValueArgs VAR_NAMES OPTION_NAMES)
	cmake_parse_arguments(__FPAR "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

	set(unparsed ${__FPAR_UNPARSED_ARGUMENTS})
	if(unparsed)
		message(FATAL_ERROR "function nice_list_output: unparsed arguments: ${unparsed}")
	endif()
	
	if(NOT TARGET "${__TARGET_NAME}")
		message(FATAL_ERROR "pass_compile_definitions_to_targets() requires first argument to be an existing target name.")
	endif()
	set(__VALID_KEYWORDS PUBLIC PRIVATE INTERFACE)
	if(NOT "${__KEYWORD}" IN_LIST __VALID_KEYWORDS)
		message(FATAL_ERROR "2nd argument to pass_compile_definitions_to_targets() must PUBLIC or PRIVATE or INTERFACE.")
	endif()
	
	foreach(__VAR IN LISTS __FPAR_VAR_NAMES)
		if(NOT "${${__VAR}}" STREQUAL "")
			target_compile_definitions("${__TARGET_NAME}" ${__KEYWORD} "${__VAR}=${${__VAR}}")
		endif()
	endforeach()
	foreach(__VAR IN LISTS __FPAR_OPTION_NAMES)
		if(${__VAR})
			target_compile_definitions("${__TARGET_NAME}" ${__KEYWORD} "${__VAR}")
		endif()
	endforeach()
endfunction()

