#Function appends target_parameters of specified target. In future the function might get parameters that specify other source of parameters
#(LINK_PARAMETERS or FEATURES) and a list of imported/not imported parameters. Function is expected to be called only directly in targets file.
#
#If the TEMPLATE calls the function to import the parameters from elsewhere, they will be also included.
#
#Must be the macro, because it modifies the POSTPROCESSING list, which is local (not global). 
macro(include_features_of __TEMPLATE_NAME)
	include_target_parameters_univ(${__TEMPLATE_NAME} TARGET_FEATURES ${ARGN})
endmacro()

macro(include_target_parameters_of __TEMPLATE_NAME)
	include_target_parameters_univ(${__TEMPLATE_NAME} TARGET_PARAMETERS ${ARGN})
endmacro()

macro(include_link_parameters_of __TEMPLATE_NAME)
	include_target_parameters_univ(${__TEMPLATE_NAME} LINK_PARAMETERS ${ARGN})
endmacro()

function(include_target_parameters_univ __TEMPLATE_NAME __TYPE)
	_is_inside_targets_file(__IS_INSIDE_TARGETS_FILE)
	if("${__IS_INSIDE_TARGETS_FILE}" STREQUAL 0)
		message(FATAL_ERROR "Calling include_target_parameters_of(<TEMPLATE_NAME>) is supported only from within targets file (e.g. targets.cmake). ")
	elseif("${__IS_INSIDE_TARGETS_FILE}" STREQUAL 1)
		set(__VALID_TYPES TARGET_PARAMETERS TARGET_FEATURES LINK_PARAMETERS)
		if(NOT "${__TYPE}" IN_LIST __VALID_TYPES)
			message(FATAL_ERROR "Internal beetroot error: __TYPE: ${__TYPE} not valid")
		endif()
		#The only condition when we do anything
#		message(STATUS "include_target_parameters_of(): ARGN: ${ARGN}")
		set(options NONRECURSIVE)
		set(oneValueArgs SOURCE)
		set(multiValueArgs ALL_EXCEPT INCLUDE_ONLY )
		cmake_parse_arguments(__PARSED "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

		set(unparsed ${__PARSED_UNPARSED_ARGUMENTS})
		if(unparsed)
			message(FATAL_ERROR "function include_target_parameters_of: unparsed arguments: ${unparsed}")
		endif()
		if(__PARSED_ALL_EXCEPT AND __PARSED_INCLUDE_ONLY)
			message(FATAL_ERROR "include_target_parameters_of() cannot accept both INCLUDE_ONLY and ALL_EXCEPT parameters")
		endif()
	
		set(__ARGS ${__TEMPLATE_NAME})
		list(APPEND __ARGS ${ARGN})
#		message(STATUS "include_target_parameters_of(): __TEMPLATE_NAME: ${__TEMPLATE_NAME} __TYPE: ${__TYPE} __ARGS: ${__ARGS}")

		#Action is deferred by registering it in the list __POSTPROCESS.
		#It is for speedup and to evade a potential user error of first including the foreign target parameters, and only then 
		_append_postprocessing_option("${__CURRENT_TARGETS_CMAKE_PATH}" ${__TYPE} "${__ARGS}")

	elseif("${__IS_INSIDE_TARGETS_FILE}" STREQUAL 2)
		#Do nothing. No recurrence in this mode
	else()
		message(FATAL_ERROR "Internal beetroot error: unknown mode of reading targets file: ${__IS_INSIDE_TARGETS_FILE}")
	endif()

endfunction()

#This function modifies parent's __POSTPROCESS list. Care must be taken not to nest it too deeply, so
#the list that is modified is the actual list we intend, not its local copy.
macro(_append_postprocessing_option __TARGETS_CMAKE_PATH __ACTION __ACTION_PARS)
	_make_path_hash("${__TARGETS_CMAKE_PATH}" __PATH_HASH)
#	message(STATUS "_append_postprocessing_option(): _parse_postprocess(\"${__TARGETS_CMAKE_PATH}\", __PPPARS, ${__ACTION}, ${__ACTION_PARS})")
	_parse_postprocess("${__TARGETS_CMAKE_PATH}" __PPPARS ${__ACTION} ${__ACTION_PARS})
#	message(STATUS "_append_postprocessing_option(): __PPPARS__LIST: ${__PPPARS__LIST}")
#	message(STATUS "_append_postprocessing_option(): _calculate_hash(__PPPARS \"${__PPPARS__LIST}\" \"${__ACTION}\" __HASH __HASH_SOURCE)")
	_calculate_hash(__PPPARS "${__PPPARS__LIST}" "${__ACTION}" __HASH __HASH_SOURCE)
#	message(STATUS "_append_postprocessing_option(): appending __HASH: ${__HASH} to file ${__PATH_HASH} (${__TARGETS_CMAKE_PATH}) ${__ACTION} | ${__ACTION_PARS}")
	if(NOT "${__HASH}" IN_LIST __POSTPROCESS_${__PATH_HASH}__LIST)
		set(__POSTPROCESS_${__HASH} ${__ACTION} ${__ACTION_PARS} PARENT_SCOPE)
		set(__POSTPROCESS_${__PATH_HASH}__LIST ${__POSTPROCESS_${__PATH_HASH}__LIST} ${__HASH} PARENT_SCOPE)
	endif()
endmacro()



#Simple macro that parses the optional argument PATH. Maybe removed in future realeses
macro(_parse_TARGETS_PATH __TEMPLATE_NAME)
	if(NOT __TEMPLATE_NAME)
		message(FATAL_ERROR "get_error was called without any arguments")
	endif()
	if("${ARGV0}" STREQUAL "PATH")
		if(NOT ARGV1)
			message(FATAL_ERROR "PATH keyword was given, but no actual argument")
		endif()
		set(__TARGETS_CMAKE_PATH "${ARGV1}")
		set(__ARGS ${ARGN})
		list(REMOVE_AT __ARGS 0 1)
		if(NOT EXISTS "${__TARGETS_CMAKE_PATH}" )
			message(FATAL_ERROR "Cannot find ${__TARGETS_CMAKE_PATH}")
		endif()
		_read_targets_file(${__TARGETS_CMAKE_PATH} 1 __READ __IS_TARGET_FIXED)
		if(NOT ${__TEMPLATE_NAME} IN_LISTS __READ_ENUM_TEMPLATES)
			message(FATAL_ERROR "Cannot find template ${__TEMPLATE_NAME} in ${__TARGETS_CMAKE_PATH}")
		endif()
	else()
		set(__ARGS ${ARGN})
		__find_targets_cmake_by_template_name(${__TEMPLATE_NAME} __TARGETS_CMAKE_PATH __IS_TARGET_FIXED)
		if(NOT __TARGETS_CMAKE_PATH)
			message(FATAL_ERROR "Canot find file defining template ${__TEMPLATE_NAME}.")
		endif()
	endif()
	
endmacro()

function(_read_functions_from_targets_file __TARGETS_CMAKE_PATH)
	_retrieve_global_data(LAST_READ_FILE __LAST_READ_FILE)
#	message(STATUS "_read_functions_from_targets_file(): __LAST_READ_FILE: ${__LAST_READ_FILE} __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH}")
	if(NOT "${__LAST_READ_FILE}" STREQUAL "${__TARGETS_CMAKE_PATH}")
		_read_targets_file("${__TARGETS_CMAKE_PATH}" 1 __DUMMY __DUMMY2)
	endif()
endfunction()

# The function that actually reads in the targets.cmake file. All read variables are stored in parent scope with ${__OUT_READ_PREFIX} prefix.
# In case last optional argument is NOT present ENUM_TEMPLATES from ENUM_TARGETS are prepended with "*" character.
function(_read_targets_file __TARGETS_CMAKE_PATH __SKIP_RECURRENCE __OUT_READ_PREFIX __OUT_IS_TARGET_FIXED)
	get_filename_component(__TARGETS_CMAKE_DIR "${__TARGETS_CMAKE_PATH}" DIRECTORY)
	set(CMAKE_CURRENT_SOURCE_DIR "${__TARGETS_CMAKE_DIR}")
	
	if(NOT __SKIP_RECURRENCE)
		_can_descend_recursively("${__TARGETS_CMAKE_PATH}" PREPROCESS __CAN_DESCEND)
		if(NOT __CAN_DESCEND)
			_get_recurency_list(PREPROCESS __INSTANCE_LIST)
			nice_list_output(LIST "${__INSTANCE_LIST}" OUTVAR __OUTVAR)
			message(FATAL_ERROR "Cyclic dependency graph encountered when including the following source files (in the calling order): ${__OUTVAR}")
		endif()
		_set_inside_targets_file()
	else()
		_set_skip_targets_file()
	endif()
	

	function(declare_dependencies DUMMY_VAR)
		#nothing to declare
	endfunction()
	function(generate_targets DUMMY_VAR)
		set(__NO_OP 1 PARENT_SCOPE) #To signal the caller, that the function in fact was not defined
	endfunction()
	function(apply_dependency_to_target INSTANCE_NAME DEP_INSTANCE_NAME)
#		target_link_libraries(${INSTANCE_NAME} ${DEP_INSTANCE_NAME})  <- For dependencies that do not define targets this call does not make sense.
		set(__NO_OP 1 PARENT_SCOPE) #To signal the caller, that the function in fact was not defined, only the default version was used
#		message(STATUS "default apply_to_target(): calling with INSTANCE_NAME: ${INSTANCE_NAME} and DEP_INSTANCE_NAME: ${DEP_INSTANCE_NAME}")
	endfunction()
	set(LINK_PARAMETERS)
	set(TARGET_PARAMETERS)
	set(TARGET_FEATURES)
	set(ENUM_TEMPLATES)
	set(ENUM_TARGETS)
	set(DEFINE_EXTERNAL_PROJECT)
	
	_make_path_hash("${__TARGETS_CMAKE_PATH}" __PATH_HASH)
	set(__POSTPROCESS_${__PATH_HASH}__LIST) #Clear all possible previous postprocessing
	set(__CURRENT_TARGETS_CMAKE_PATH "${__TARGETS_CMAKE_PATH}")
#	message(STATUS "_read_targets_file(): Reading in ${__TARGETS_CMAKE_PATH}...")
	include("${__TARGETS_CMAKE_PATH}" OPTIONAL RESULT_VARIABLE __FILE_LOADED)
#	message(STATUS "_read_targets_file(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH} ENUM_TEMPLATES: ${ENUM_TEMPLATES} ENUM_TARGETS: ${ENUM_TARGETS}")

	if("${__FILE_LOADED}" STREQUAL "NOTFOUND")
		message(FATAL_ERROR "Cannot find targets.cmake in ${__TARGETS_CMAKE_PATH}")
	endif()
	if(ENUM_TEMPLATES)
		string(REPLACE "-" "_" ENUM_TEMPLATES "${ENUM_TEMPLATES}")
	endif()
	if(ENUM_TARGETS)
		string(REPLACE "-" "_" ENUM_TARGETS "${ENUM_TARGETS}")
	endif()
#	message(STATUS "_read_targets_file(): Setting LAST_READ_FILE to ${__TARGETS_CMAKE_PATH}")
	_set_property_to_db(GLOBAL ALL LAST_READ_FILE ${__TARGETS_CMAKE_PATH} FORCE)
	_clear_inside_targets_file()
	if(NOT __SKIP_RECURRENCE)
		_process_all_postprocessing("${__TARGETS_CMAKE_PATH}")
		
		_ascend_from_recurency("${__TARGETS_CMAKE_PATH}" PREPROCESS)
	endif()


	if(NOT ENUM_TEMPLATES AND NOT ENUM_TARGETS)
		message(FATAL_ERROR "You must define either ENUM_TEMPLATES or ENUM_TARGETS in ${__TARGETS_CMAKE_PATH}")
	endif()
	if(ENUM_TEMPLATES AND ENUM_TARGETS)
		message(FATAL_ERROR "You cannot define both ENUM_TEMPLATES and ENUM_TARGETS in ${__TARGETS_CMAKE_PATH}")
	endif()
	if(DEFINED ENUM_TARGETS)
		set(${__OUT_IS_TARGET_FIXED} 1 PARENT_SCOPE)
		set(ENUM_TEMPLATES ${ENUM_TARGETS})
	else()
		set(${__OUT_IS_TARGET_FIXED} 0 PARENT_SCOPE)
	endif()
	if(__OUT_READ_PREFIX)
		set(${__OUT_READ_PREFIX}_LINK_PARAMETERS "${LINK_PARAMETERS}" PARENT_SCOPE)
		set(${__OUT_READ_PREFIX}_TARGET_PARAMETERS "${TARGET_PARAMETERS}" PARENT_SCOPE)
		set(${__OUT_READ_PREFIX}_TARGET_FEATURES "${TARGET_FEATURES}" PARENT_SCOPE)
		set(${__OUT_READ_PREFIX}_ENUM_TEMPLATES "${ENUM_TEMPLATES}" PARENT_SCOPE)
		set(${__OUT_READ_PREFIX}_DEFINE_EXTERNAL_PROJECT "${DEFINE_EXTERNAL_PROJECT}" PARENT_SCOPE)
#		if(TEMPLATE_OPTIONS)
#			message(STATUS "_read_targets_file(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH} TEMPLATE_OPTIONS: ${TEMPLATE_OPTIONS}")
#		endif()
		set(${__OUT_READ_PREFIX}_TEMPLATE_OPTIONS "${TEMPLATE_OPTIONS}" PARENT_SCOPE)
	endif()
endfunction()

function(__append_target_from __TARGETS_CMAKE_PATH __EXISTING_TEMPLATES)
	set(__TEMPLATE_FILENAME "${SUPERBUILD_ROOT}/build/templates.cmake")
	_read_targets_file("${__TARGETS_CMAKE_PATH}" 1 __TARGETS_VARS_PREFIX __IS_TARGET_FIXED)
	set(__TEMPLATES__LIST "${${__EXISTING_TEMPLATES}}")
	if(__TARGETS_VARS_PREFIX_DEFINE_EXTERNAL_PROJECT)
		set(__EXTERNAL_PROJECT_INFO__LIST "${__TARGETS_VARS_PREFIX_DEFINE_EXTERNAL_PROJECT}")
		_parse_external_info(__EXTERNAL_PROJECT_INFO "${__TARGETS_CMAKE_PATH}" NAME __EXT_NAME)
		if(__EXT_NAME)
			if(NOT "${__EXT_NAME}" IN_LIST __TARGETS_VARS_PREFIX_ENUM_TEMPLATES)
				list(APPEND __TARGETS_VARS_PREFIX_ENUM_TEMPLATES "${__EXT_NAME}")
			endif()
		endif()
	endif()
	foreach(__TARGET IN LISTS __TARGETS_VARS_PREFIX_ENUM_TEMPLATES)
#				string(REGEX REPLACE "^\\*" "" __TARGET "${__TEMPLATE}") #removes "*" in front of fixed targets
		string(REPLACE "::" "_" __TARGET_FIXED "${__TARGET}")
		string(REPLACE "-" "_" __TARGET_FIXED "${__TARGET_FIXED}")
		if("${__TARGET_FIXED}" IN_LIST ${__EXISTING_TEMPLATES})
			message(FATAL_ERROR "Duplicate template name detected. One instance declared in ${${__EXISTING_TEMPLATES}_${__TARGET_FIXED}} and the other in ${__TARGETS_CMAKE_PATH}")
		endif()
		list(APPEND __TEMPLATES__LIST "${__TARGET_FIXED}")
		set(${__EXISTING_TEMPLATES}_TEMPLATES_${__TARGET_FIXED} "${__TARGETS_CMAKE_PATH}" PARENT_SCOPE)
#				message(STATUS "__prepare_template_list(): Found ${__TARGET_FIXED}.")
		set(__STR_OUT "set(__TEMPLATES_${__TARGET_FIXED} \"${__TARGETS_CMAKE_PATH}\")\n")
		file(APPEND ${__TEMPLATE_FILENAME} "${__STR_OUT}")
	endforeach()
	set(${__EXISTING_TEMPLATES} ${__TEMPLATES__LIST} PARENT_SCOPE)
endfunction()

function(__prepare_template_list)
	set(__TEMPLATE_FILENAME "${SUPERBUILD_ROOT}/build/templates.cmake")
	if(EXISTS "${__TEMPLATE_FILENAME}" AND FALSE)
		include("${__TEMPLATE_FILENAME}")
	else()
		if(EXISTS "${__TEMPLATE_FILENAME}")
			file(REMOVE "${__TEMPLATE_FILENAME}")
		endif()
		set(__TEMPLATES__LIST)
		file(GLOB_RECURSE __EXTERNAL_TARGETS_DIRS_LIST LIST_DIRECTORIES true "${SUPERBUILD_ROOT}/*/cmake")
		foreach(__EXTERNAL_TARGETS_DIR IN LISTS __EXTERNAL_TARGETS_DIRS_LIST)
			if(IS_DIRECTORY "${__EXTERNAL_TARGETS_DIR}")
				get_filename_component(__NAME1 ${__EXTERNAL_TARGETS_DIR} DIRECTORY)
				get_filename_component(__NAME1 ${__NAME1} NAME)
				get_filename_component(__NAME2 ${__EXTERNAL_TARGETS_DIR} NAME)
#				message(STATUS "__prepare_template_list(): __EXTERNAL_TARGETS_DIRS_LIST: ${__EXTERNAL_TARGETS_DIRS_LIST} __NAME1: ${__NAME1} __NAME2: ${__NAME2}")
				if("${__NAME1}" STREQUAL "cmake" AND "${__NAME2}" STREQUAL "targets")
#					message(STATUS "__prepare_template_list(): __EXTERNAL_TARGETS_DIR: ${__EXTERNAL_TARGETS_DIR}")
					file(GLOB_RECURSE __EXTERNAL_TARGETS_CMAKE_LIST CONFIGURE_DEPENDS "${__EXTERNAL_TARGETS_DIR}/*.cmake")
					foreach(__FILE IN LISTS __EXTERNAL_TARGETS_CMAKE_LIST)
						__append_target_from("${__FILE}" __TEMPLATES__LIST)
					endforeach()
				endif()
			endif()
		endforeach()
		
		file(GLOB_RECURSE __TARGETS_CMAKE_LIST CONFIGURE_DEPENDS "${SUPERBUILD_ROOT}/targets.cmake")
		foreach(__FILE IN LISTS __TARGETS_CMAKE_LIST)
			__append_target_from("${__FILE}" __TEMPLATES__LIST)
		endforeach()
		string(REPLACE ";" " " __TEMPLATES_SPACES "${__TEMPLATES__LIST}")
#		message(STATUS "__prepare_template_list(): __STR_OUT: ${__STR_OUT}")
		set(__STR_OUT "set(__TEMPLATES__LIST ${__TEMPLATES_SPACES})\n")
#		message(STATUS "__prepare_template_list(): __STR_OUT: ${__STR_OUT}")
		file(APPEND ${SUPERBUILD_ROOT}/build/templates.cmake "${__STR_OUT}")
	endif()
	message("")
	message("")
	message("SUPERBUILD: ${SUPERBUILD}")
	if(__NOT_SUPERBUILD)
		message("    DECLARING  DEPENDENCIES  IN  PROJECT BUILD")
	else()
		if("${SUPERBUILD}" STREQUAL "AUTO")
			message("    DECLARING  DEPENDENCIES  AND  DECIDING  WHETHER  TO  USE  SUPERBUILD")
		else()
			message("    DECLARING  DEPENDENCIES  IN  SUPERBUILD")
		endif()
	endif()
	message("")
endfunction()

function(__find_targets_cmake_by_template_name __TEMPLATE_NAME __OUT_TARGETS_CMAKE_PATH __OUT_IS_TARGET_FIXED)
	set(__TEMPLATE_FILENAME "${SUPERBUILD_ROOT}/build/templates.cmake")
	if(EXISTS "${__TEMPLATE_FILENAME}")
#		message(STATUS "__find_targets_cmake_by_template_name(): Including ${__TEMPLATE_FILENAME}")
		include("${__TEMPLATE_FILENAME}")
	else()
		message(FATAL_ERROR "Cannot find ${__TEMPLATE_FILENAME}")
	endif()
	string(REPLACE "::" "_" __TEMPLATE_NAME "${__TEMPLATE_NAME}")
	string(REPLACE "-" "_" __TEMPLATE_NAME "${__TEMPLATE_NAME}")
#	message(STATUS "__find_targets_cmake_by_template_name(): Looking up for __TEMPLATE_NAME: ${__TEMPLATE_NAME}")

	if(__TEMPLATES_${__TEMPLATE_NAME})
		set(${__OUT_TARGETS_CMAKE_PATH} "${__TEMPLATES_${__TEMPLATE_NAME}}" PARENT_SCOPE)
		if("*${__TEMPLATE_NAME}" IN_LIST __TEMPLATES__LIST)
			set(${__OUT_IS_TARGET_FIXED} 1 PARENT_SCOPE)
		else()
			set(${__OUT_IS_TARGET_FIXED} 0 PARENT_SCOPE)
		endif()
	else()
		message(FATAL_ERROR "Cannot find ${__TEMPLATE_NAME} in __TEMPLATES_${__TEMPLATE_NAME} among known templates")
	endif()
endfunction()






macro(_process_all_postprocessing __REF_TARGETS_CMAKE_PATH)
	_make_path_hash("${__REF_TARGETS_CMAKE_PATH}" __PATH_HASH)
#	message(STATUS "_process_all_postprocessing(): for ${__REF_TARGETS_CMAKE_PATH} __POSTPROCESS_${__PATH_HASH}__LIST: ${__POSTPROCESS_${__PATH_HASH}__LIST}")
	foreach(__PP_HASH IN LISTS __POSTPROCESS_${__PATH_HASH}__LIST)
#		message(STATUS "_process_all_postprocessing(): __POSTPROCESS_${__PP_HASH}: ${__POSTPROCESS_${__PP_HASH}}")
		_process_postprocess("${__REF_TARGETS_CMAKE_PATH}" ${__POSTPROCESS_${__PP_HASH}})
	endforeach()
endmacro()

function(_parse_postprocess __REF_TARGETS_CMAKE_PATH __OUT_PREFIX __ACTION)
	set(__INCLUDE_CMD_LIST TARGET_PARAMETERS TARGET_FEATURES LINK_PARAMETERS)
	if("${__ACTION}" IN_LIST __INCLUDE_CMD_LIST)
		set(__POSITIONAL TEMPLATE_NAME )
		set(__OPTIONS NONRECURSIVE)
		set(__oneValueArgs SOURCE )
		set(__multiValueArgs ALL_EXCEPT INCLUDE_ONLY)
	else()
		message(FATAL_ERROR "Internal beetroot error: unknown postprocessing action: ${__ACTION} in ${__REF_TARGETS_CMAKE_PATH}.")
	endif()
#	message(STATUS "_parse_postprocess(): __ACTION: ${__ACTION} ARGN: ${ARGN}")
#	message(STATUS "_parse_postprocess(): przed parse __REF_TARGETS_CMAKE_PATH: ${__REF_TARGETS_CMAKE_PATH} _parse_general_function_arguments(\"${__POSITIONAL}\" \"${__OPTIONS}\" \"${__oneValueArgs}\" \"${__multiValueArgs}\" ${__OUT_PREFIX} ${ARGN})")
	_parse_general_function_arguments("${__POSITIONAL}" "${__OPTIONS}" "${__oneValueArgs}" "${__multiValueArgs}" __PARSE ${ARGN} ) 
	if("${__PARSE_SOURCE}" STREQUAL "")
		set(__PARSE_SOURCE ${__ACTION})
		list(APPEND __PARSE__LIST SOURCE)
	elseif("${__PARSE_SOURCE}" STREQUAL "LINKPARS")
		set(__PARSE_SOURCE LINK_PARAMETERS)
	elseif("${__PARSE_SOURCE}" STREQUAL "LINK_PARAMETERS")
		set(__PARSE_SOURCE LINK_PARAMETERS)
	elseif("${__PARSE_SOURCE}" STREQUAL "PARAMETERS")
		set(__PARSE_SOURCE TARGET_PARAMETERS)
	elseif("${__PARSE_SOURCE}" STREQUAL "FEATURES")
		set(__PARSE_SOURCE TARGET_FEATURES)
	else()
		message(FATAL_ERROR "Wrong SOURCE parameter to the include_target_parameters_of: ${__PARSE_SOURCE}")
	endif()
#	message(STATUS "_parse_postprocess(): po parse __REF_TARGETS_CMAKE_PATH: ${__REF_TARGETS_CMAKE_PATH} __PARSE__LIST: ${__PARSE__LIST} __PARSE_TEMPLATE_NAME: ${__PARSE_TEMPLATE_NAME} __PARSE_INCLUDE_ONLY: ${__PARSE_INCLUDE_ONLY}")
	set(__PARSE__LIST ${__POSITIONAL} ${__OPTIONS} ${__oneValueArgs} ${__multiValueArgs})
	_pass_arguments_higher(__PARSE ${__OUT_PREFIX})
	
#	message(STATUS "_parse_postprocess(): __OUT_PREFIX: ${__OUT_PREFIX} ${__OUT_PREFIX}__LIST: ${${__OUT_PREFIX}__LIST}")
endfunction()

function(_process_postprocess __REF_TARGETS_CMAKE_PATH __ACTION)
#	message(STATUS "_process_postprocess(): To parse: ${__ACTION} ${ARGN} for ${__REF_TARGETS_CMAKE_PATH}")
	_parse_postprocess("${__REF_TARGETS_CMAKE_PATH}" __PPPARS ${__ACTION} ${ARGN})
#	message(STATUS "_process_postprocess(): __PPPARS__LIST: ${__PPPARS__LIST} __PPPARS_TEMPLATE_NAME: ${__PPPARS_TEMPLATE_NAME}")
#	message(STATUS "_process_postprocess(): __PPPARS_TEMPLATE_NAME: ${__PPPARS_TEMPLATE_NAME}")
	set(__INCLUDE_CMD_LIST TARGET_PARAMETERS TARGET_FEATURES LINK_PARAMETERS)
	
	
	if("${__ACTION}" IN_LIST __INCLUDE_CMD_LIST)
		if(NOT __PPPARS_TEMPLATE_NAME)
			message(FATAL_ERROR "_process_postprocess was called without any arguments")
		endif()
		__find_targets_cmake_by_template_name(${__PPPARS_TEMPLATE_NAME} __TARGETS_CMAKE_PATH __IS_TARGET_FIXED)
#		message(STATUS "_process_postprocess(): descending into include ${__TARGETS_CMAKE_PATH} from ${__REF_TARGETS_CMAKE_PATH}. __PPPARS_ALL_EXCEPT: ${__PPPARS_ALL_EXCEPT} __PPPARS_INCLUDE_ONLY: ${__PPPARS_INCLUDE_ONLY}")
		
		_include_target_parameters_from(${__ACTION} "${__REF_TARGETS_CMAKE_PATH}" "${__TARGETS_CMAKE_PATH}" "${__PPPARS_ALL_EXCEPT}" "${__PPPARS_INCLUDE_ONLY}" "${__PPPARS_NONRECURSIVE}" ${__PPPARS_SOURCE} __OUT_PARAMS)
#		message(STATUS "_process_postprocess(): (parent) ${__ACTION}: ${${__ACTION}}, (imported) __PREFIX_${__ACTION}: ${__OUT_PARAMS}")
		set(${__ACTION} "${${__ACTION}}")
		list(APPEND ${__ACTION} "${__OUT_PARAMS}")
		set(${__ACTION} "${${__ACTION}}" PARENT_SCOPE)
		
#		message(STATUS "_process_postprocess(): in total found the following parameters in ${__TARGETS_CMAKE_PATH}: __PREFIX_${__ACTION}: ${__PREFIX_${__ACTION}}")
	else()
		message(FATAL_ERROR "Internal beetroot error: unknown postprocessing action: ${__ACTION} in ${__REF_TARGETS_CMAKE_PATH}.")
	endif()
endfunction()

function(_include_target_parameters_from __TYPE __REF_TARGETS_CMAKE_PATH __TARGETS_CMAKE_PATH __ALL_EXCEPT __INCLUDE_ONLY __SKIP_RECURRENCE __SOURCE __OUT_PARAMS )
#		#We need to stash current TARGET_PARAMETERS in case another souce file will be read
#		set(__TARGET_PARAMETERS "${TARGET_PARAMETERS}")
#	message(STATUS "_include_target_parameters_from(): __REF_TARGETS_CMAKE_PATH: ${__REF_TARGETS_CMAKE_PATH} __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH} __ALL_EXCEPT: ${__ALL_EXCEPT} __INCLUDE_ONLY: ${__INCLUDE_ONLY}")
#	message(STATUS "_include_target_parameters_from(): Attempting to read ${__TARGETS_CMAKE_PATH}")
	_read_targets_file(${__TARGETS_CMAKE_PATH} ${__SKIP_RECURRENCE} __PREFIX __IS_TARGET_FIXED)
#	message(STATUS "_include_target_parameters_from(): __PREFIX_${__TYPE}: ${__PREFIX_${__TYPE}}")

	set(__ARGS__LIST)
	set(__PARS__LIST)
	
	
	_parse_parameters(__PREFIX_${__SOURCE} __ARGS __PARS "${__TARGETS_CMAKE_PATH}" 0)
	
	set(__DEBUG_VARNAME USE_PNETCDF)
	if(__ARGS_${__DEBUG_VARNAME})
#		message(STATUS "_include_target_parameters_from(): __ARGS_${__DEBUG_VARNAME}: ${__ARGS_${__DEBUG_VARNAME}} __PARS_${__DEBUG_VARNAME}__CONTAINER: ${__PARS_${__DEBUG_VARNAME}__CONTAINER} __PARS_${__DEBUG_VARNAME}__TYPE: ${__PARS_${__DEBUG_VARNAME}__TYPE}")
	endif()
	if(__ALL_EXCEPT)
#		message(STATUS "_include_target_parameters_from(): __ALL_EXCEPT: ${__ALL_EXCEPT}")
		list_diff(__TMP __ALL_EXCEPT __ARGS__LIST)
		if(__TMP)
			nice_list_output(LIST ${__TMP} OUT_VAR __NICE_LIST)
			message(FATAL_ERROR "Suspicious use of include_target_parameters_of() in ${__REF_TARGETS_CMAKE_PATH}: file ${__TARGETS_CMAKE_PATH} was included using ALL_EXCEPT clause, but the following exceptions were not present anyway: ${__NICE_LIST}.")
		endif()
		list_diff(__TO_APPEND __ARGS__LIST __ALL_EXCEPT)
	elseif(__INCLUDE_ONLY)
#		message(STATUS "_include_target_parameters_from(): __INCLUDE_ONLY: ${__INCLUDE_ONLY} __ARGS__LIST: ${__ARGS__LIST}")
		list_diff(__TMP __INCLUDE_ONLY __ARGS__LIST)
#		message(STATUS "_include_target_parameters_from(): __INCLUDE_ONLY: ${__INCLUDE_ONLY} __ARGS__LIST: ${__ARGS__LIST} __TMP: ${__TMP}")
		if(__TMP)
			nice_list_output(LIST ${__TMP} OUTVAR __NICE_LIST)
			message(FATAL_ERROR "Error when calling include_target_parameters_of() in ${__REF_TARGETS_CMAKE_PATH}: file was included using INCLUDE_ONLY clause with the variables ${__NICE_LIST} that are missing in ${__TARGETS_CMAKE_PATH}.")
		endif()
		set(__TO_APPEND ${__INCLUDE_ONLY})
	else()
#		message(STATUS "_include_target_parameters_from(): all: ${__ARGS__LIST}")
		set(__TO_APPEND ${__ARGS__LIST})
	endif()
#	message(STATUS "_include_target_parameters_from(): Going to include __TO_APPEND: ${__TO_APPEND} variables to ${__REF_TARGETS_CMAKE_PATH} from ${__TARGETS_CMAKE_PATH}")
	set(__OUT)
	foreach(__VAR IN LISTS __TO_APPEND)
		list(APPEND __OUT ${__VAR} "${__PARS_${__VAR}__CONTAINER}" "${__PARS_${__VAR}__TYPE}" "${__ARGS_${__VAR}}" )
#		message(STATUS "_include_target_parameters_from(): Forwarded variable def: ${__VAR} \"${__PARS_${__VAR}__CONTAINER}\" \"${__PARS_${__VAR}__TYPE}\" \"${__ARGS_${__VAR}}\"")
	endforeach()
#	message(STATUS "_include_target_parameters_from(): After appending from ${__TARGETS_CMAKE_PATH} to ${__REF_TARGETS_CMAKE_PATH} := ${__OUT}")
	set(${__OUT_PARAMS} "${__OUT}" PARENT_SCOPE)
endfunction()