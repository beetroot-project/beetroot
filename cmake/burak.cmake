# get_target(<TEMPLATE_NAME> [PATH <Ścieżka do targets.cmake>] <Args...>)
#
# High level function responsible for 
# 1. finding a target defining function by its template name (or path), 
# 2. get all its arguments by properly combining default values with already existing variables and arguments Args...
# 3. if target defined by that arguments exists already, return its name, otherwise...
# 3. ...instatiate its dependencies (which may be internal and external) by calling declare_dependencies(), 
# 4. define the target by calling generate_targets() and
# 5. return the actual target name.
#

get_filename_component(__PREFIX "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
set(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY 1) #We disable use of CMake package registry. See https://cmake.org/cmake/help/v3.2/variable/CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY.html . With this variable set, the only version of the packages will be the version we actually intend to use.

include(${__PREFIX}/burak_get_target.cmake)
include(${__PREFIX}/burak_finalize.cmake)
include(${__PREFIX}/burak_reading_targets.cmake)
include(${__PREFIX}/burak_variables.cmake)
include(${__PREFIX}/burak_global_storage.cmake)
include(${__PREFIX}/burak_global_storage_misc.cmake)
include(${__PREFIX}/burak_dependency_processing.cmake)
include(${__PREFIX}/burak_external_target.cmake)
include(${__PREFIX}/build_install_prefix.cmake)
include(${__PREFIX}/set_operations.cmake)
include(${__PREFIX}/prepare_arguments_to_pass.cmake)
include(${__PREFIX}/missing_dependency.cmake)

_set_behavior_outside_defining_targets()
if(NOT __NOT_SUPERBUILD)
	set_property(GLOBAL PROPERTY __BURAK_EXTERNAL_DEPENDENCIES "")
else()
	message(STATUS "Beginning of the second phase")
endif()
set(__RANDOM ${__RANDOM})
include(ExternalProject)


#We hijack the project() command to make sure, that during the superbuild phase no actual compiling will take place.
macro(project) 
	if(__NOT_SUPERBUILD)
		_project(${ARGN})
	else()
		message("No languages in project ${ARGV0}")
		_project(${ARGV0} NONE)
	endif()
endmacro()

function(_invoke_apply_dependency_to_target __DEPENDEE_INSTANCE_ID __INSTANCE_ID __OUT_FUNCTION_EXISTS)
	_retrieve_instance_data(${__INSTANCE_ID} PATH __TARGETS_CMAKE_PATH)
	_retrieve_instance_args(${__INSTANCE_ID} MODIFIERS __ARGS)
	set(__TMP_LIST "${__ARGS__LIST}")
	_retrieve_instance_args(${__INSTANCE_ID} I_FEATURES __ARGS)
	list(APPEND __TMP_LIST ${__ARGS__LIST})
	_retrieve_instance_args(${__INSTANCE_ID} LINKPARS __ARGS)
	list(APPEND __TMP_LIST ${__ARGS__LIST})
	set(__ARGS__LIST ${__TMP_LIST})
	_make_instance_name(${__DEPENDEE_INSTANCE_ID} __DEP_INSTANCE_NAME)
	_make_instance_name(${__INSTANCE_ID} __INSTANCE_NAME)
	
	_read_functions_from_targets_file("${__TARGETS_CMAKE_PATH}")
	_instantiate_variables(__ARGS "${__ARGS__LIST}")
	unset(__NO_OP)
#	apply_to_target(${__DEPENDEE_INSTANCE_ID} ${__INSTANCE_NAME})
#	take_dependency_from_target(${__DEPENDEE_INSTANCE_ID} ${__INSTANCE_NAME})

	get_target_property(__TYPE ${__DEP_INSTANCE_NAME} TYPE)
	if("${__TYPE}" STREQUAL "INTERFACE_LIBRARY" )
		set(KEYWORD "INTERFACE")
	else()
		set(KEYWORD "PUBLIC")
	endif()


	apply_dependency_to_target(${__DEP_INSTANCE_NAME} ${__INSTANCE_NAME})

#	message(STATUS "_invoke_apply_dependency_to_target(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH} __DEPENDEE_INSTANCE_ID: ${__DEPENDEE_INSTANCE_ID} __INSTANCE_ID: ${__INSTANCE_ID} __NO_OP: ${__NO_OP}")
	if(__NO_OP)
		set(${__OUT_FUNCTION_EXISTS} 0 PARENT_SCOPE)
	else()
		set(${__OUT_FUNCTION_EXISTS} 1 PARENT_SCOPE)
	endif()
endfunction()

function(_make_sure_no_apply_to_target __TARGETS_CMAKE_PATH __DEPENDENT __DEPENDEE)
	_read_functions_from_targets_file("${__TARGETS_CMAKE_PATH}")
	unset(__NO_OP)
	apply_to_target("NO_TARGET" "NO_TARGET")
	if(NOT __NO_OP)
		message(FATAL_ERROR "Cannot use ${__DEPENDENT} as a dependency of ${__DEPENDEE}, because ${__DEPENDENT} has take_dependency_from_target() function defined which cannot be called when ${__DEPENDEE} does not generate a target.")
	endif()
endfunction()

#General function that parses whatever arguments were passed to it after the required parameters.
#Additionally, the function includes a list ${__OUT_PREFIX}__LIST with all actually set arguments for e.g. easier calculation of hash.
function(_parse_general_function_arguments __POSITIONAL __OPTIONS __oneValueArgs __multiValueArgs __OUT_PREFIX )
	set(__ARGSKIP 4)
	set(__TO_REMOVE 0 1 2 3 4)
	set(__ALL_PARS ${__POSITIONAL} ${__OPTIONS} ${__oneValueArgs} ${__multiValueArgs})
	set(__ALL_PARS_COPY ${__ALL_PARS})
	list(REMOVE_DUPLICATES __ALL_PARS_COPY)
	list(LENGTH __ALL_PARS __ALL_PARS_COUNT)
	list(LENGTH __ALL_PARS_COPY __UNIQUE_PARS_COUNT)
	if(${__UNIQUE_PARS_COUNT} LESS ${__ALL_PARS_COUNT})
		message(FATAL_ERROR "Internal beetroot error: non-unique names of parameters passed to _parse_general_function_arguments(\"${__POSITIONAL}\" \"${__OPTIONS}\" \"${__oneValueArgs}\" \"${__multiValueArgs}\" ${__OUT_PREFIX})")
	endif()
	if(__POSITIONAL)
		foreach(__POS_ITEM IN LISTS __POSITIONAL)
#			message(STATUS "_parse_general_function_arguments(): __POS_ITEM: ${__POS_ITEM}")
			math(EXPR __ARGSKIP "${__ARGSKIP} + 1")
			list(APPEND __TO_REMOVE ${__ARGSKIP})
			message(STATUS "_parse_general_function_arguments(): __ARGSKIP: ${__ARGSKIP}")
			if(${ARGC} LESS_EQUAL ${__ARGSKIP})
				message(FATAL_ERROR "Internal beetroot error: _append_postprocessing_action(${__ACTION}) was passed less arguments than the number of obligatory positional parameters ${__POSITIONAL}")
			endif()
			set(___PARSED_${__POS_ITEM} "${ARGV${__ARGSKIP}}")
			message(STATUS "_parse_general_function_arguments(): __TO_REMOVE: ${__TO_REMOVE}")
		endforeach()
		message(STATUS "_parse_general_function_arguments(): ARGV${__ARGSKIP}: ${ARGV${__ARGSKIP}}")
		set(__COPY_ARGS "${ARGV}")
		message(STATUS "_parse_general_function_arguments(): __COPY_ARGS: ${__COPY_ARGS} __TO_REMOVE: ${__TO_REMOVE}")
		
		list(REMOVE_AT __COPY_ARGS ${__TO_REMOVE})
	else()
		set(__COPY_ARGS ${ARGV})
	endif()
	
	message(STATUS "_parse_general_function_arguments(): __COPY_ARGS: ${__COPY_ARGS}")
	cmake_parse_arguments(___PARSED "${__OPTIONS}" "${__oneValueArgs}" "${__multiValueArgs}" ${__COPY_ARGS})
	set(__unparsed ${___PARSED_UNPARSED_ARGUMENTS})
	if(__unparsed)
		message(FATAL_ERROR "Internal beetroot error: Undefined postprocessing for targets file: ${__unparsed}. All options: ${__COPY_ARGS}")
	endif()
	set(__ARGLIST)
	foreach(__VAR IN LISTS __POSITIONAL __OPTIONS __oneValueArgs __multiValueArgs )
		if( NOT "${___PARSED_${__VAR}}" STREQUAL "")
			set(${__OUT_PREFIX}_${__VAR} ${___PARSED_${__VAR}} PARENT_SCOPE)
			list(APPEND __ARGLIST ${__VAR})
		elseif(${__VAR} IN_LIST __OPTIONS)
			set(___PARSED_${__VAR} 0 PARENT_SCOPE)
			set(${__OUT_PREFIX}_${__VAR} ${___PARSED_${__VAR}} PARENT_SCOPE)
		endif()
	endforeach()
	set(${__OUT_PREFIX}__LIST ${__ARGLIST} PARENT_SCOPE)
endfunction()

__prepare_template_list()


