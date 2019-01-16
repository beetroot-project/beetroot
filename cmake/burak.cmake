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
include(burak_variables)
include(burak_global_storage)
include(burak_global_storage_misc)
include(burak_dependency_processing)
include(build_install_prefix)
include(set_operations)
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

function(build_target __TEMPLATE_NAME)
	get_target(${__TEMPLATE_NAME} __TMP_INSTANCE_NAME ${ARGN})
endfunction()

function(get_target __TEMPLATE_NAME __OUT_INSTANCE_NAME) 
	_get_target_behavior(__GET_TARGET_BEHAVIOR)
#	message(STATUS "Called get_target(${__TEMPLATE_NAME}) on phase ${__GET_TARGET_BEHAVIOR}")
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "INSIDE_GENERATE_TARGETS")
		message(FATAL_ERROR "Calling get_target from inside generate_targets is disallowed. To call dependency use declare_dependencies() (in which you cannot define targets).")
	endif()
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
		_read_targets_file(${__TARGETS_CMAKE_PATH} __READ __IS_TARGET_FIXED)
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
	
	
	_get_variables("${__TARGETS_CMAKE_PATH}" "" __VARIABLE_DIC __PARAMETERS_DIC __TEMPLATES __EXTERNAL_PROJECT_INFO __IS_TARGET_FIXED __TEMPLATE_OPTIONS ${__ARGS})
#	if("${__TEMPLATE_NAME}" STREQUAL "SerialboxStatic")
#		message(FATAL_ERROR "__EXTERNAL_PROJECT_INFO: ${__EXTERNAL_PROJECT_INFO}")
#	endif()
	if("${__VARIABLE_DIC_VERSION}" STREQUAL "KUC")
		message(FATAL_ERROR "__VARIABLE_DIC_VERSION: ${__VARIABLE_DIC_VERSION}")
	endif()
	_make_instance_id(${__TEMPLATE_NAME} __VARIABLE_DIC __INSTANCE_ID)
#	message(STATUS "get_target: __TEMPLATE_NAME ${__TEMPLATE_NAME} got __INSTANCE_ID: ${__INSTANCE_ID}")
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "GATHERING_DEPENDENCIES" OR "${__GET_TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
		#Add dependencies together with their arguments to the list. They will be instatiated later on, during generate_targets run
		_put_dependencies_into_stack("${__INSTANCE_ID}")
		_discover_dependencies(${__TEMPLATE_NAME} "${__TARGETS_CMAKE_PATH}" __VARIABLE_DIC "${__VARIABLE_DIC__LIST_MODIFIERS}" __DEP_INSTANCE_ID_LIST)
#		message(FATAL_ERROR "__PARAMETERS_DIC__LIST_MODIFIERS: ${__PARAMETERS_DIC__LIST_MODIFIERS}")
#		message(STATUS "Storing instance data for ${__TEMPLATE_NAME} in ${__TARGETS_CMAKE_PATH}...")
		if("${__GET_TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
			set(__TARGET_REQUIRED 1)
		else()
			set(__TARGET_REQUIRED 0)
		endif()
		_store_instance_data(
			 ${__INSTANCE_ID}
			__VARIABLE_DIC 
			__PARAMETERS_DIC
			"${__PARAMETERS_DIC__LIST_MODIFIERS}"
			"${__DEP_INSTANCE_ID_LIST}" 
			 ${__TEMPLATE_NAME} 
			 ${__TARGETS_CMAKE_PATH} 
			 ${__IS_TARGET_FIXED}
			"${__EXTERNAL_PROJECT_INFO}"
			 ${__TARGET_REQUIRED}
			"${__TEMPLATE_OPTIONS}"
			 )
	elseif("${__GET_TARGET_BEHAVIOR}" STREQUAL "DEFINING_TARGETS")
		_make_instance_name(${__INSTANCE_ID} __INSTANCE_NAME)
		if(NOT TARGET "${__INSTANCE_NAME}")
			get_filename_component(__TARGETS_CMAKE_DIR "${__TARGETS_CMAKE_PATH}" DIRECTORY)
	
			if(NOT "${__TEMPLATE_NAME}" IN_LIST __TEMPLATES)
				message(FATAL_ERROR "File ${__TARGETS_CMAKE_PATH} does not contain definition of template ${__TEMPLATE_NAME}")
			endif()
#			message(STATUS "get_target(): Instantiating dependencies for ${__TEMPLATE_NAME}...")
			_get_dependencies(${__TEMPLATE_NAME} "${__TARGETS_CMAKE_PATH}" __VARIABLE_DIC __DEP_INSTANCE_NAME_LIST)
			if("${__TEMPLATE_NAME}" STREQUAL "HELLO" AND NOT __DEP_INSTANCE_NAME_LIST)
				message(FATAL_ERROR "No dependencies for HELLO")
			endif()
#			message(STATUS "get_target(): Gathered the following dependencies for ${__TEMPLATE_NAME}: ${__DEP_INSTANCE_NAME_LIST}")
			_set_behavior_defining_targets() #So any call to the get_targets will raise an error. 
			_instantiate_target(${__TEMPLATE_NAME} ${__TARGETS_CMAKE_PATH} ${__INSTANCE_NAME} __VARIABLE_DIC "${__DEP_INSTANCE_NAME_LIST}")
		endif()
	else()
		message(FATAL_ERROR "Unknown global state __GET_TARGET_BEHAVIOR = \"${__GET_TARGET_BEHAVIOR}\"")
	endif()
	if(__OUT_INSTANCE_NAME)
		set(${__OUT_INSTANCE_NAME} "${__INSTANCE_NAME}" PARENT_SCOPE)
	endif()
endfunction()

function(_invoke_apply_to_target __INSTANCE_ID __DEP_INSTANCE_ID __OUT_FUNCTION_EXISTS)
	_retrieve_instance_data(${__DEP_INSTANCE_ID} PATH __TARGETS_CMAKE_PATH)
	_retrieve_instance_args(${__DEP_INSTANCE_ID} __ARGS)
	_make_instance_name(${__DEP_INSTANCE_ID} __DEP_INSTANCE_NAME)
	_make_instance_name(${__INSTANCE_ID} __INSTANCE_NAME)
	
	_read_functions_from_targets_file("${__TARGETS_CMAKE_PATH}")
	_instantiate_variables(__ARGS "${__ARGS__LIST}")
	unset(__NO_OP)
	apply_to_target(${__INSTANCE_NAME} ${__DEP_INSTANCE_NAME})
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
		message(FATAL_ERROR "Cannot use ${__DEPENDENT} as a dependency of ${__DEPENDEE}, because ${__DEPENDENT} has apply_to_target() function defined which cannot be called when ${__DEPENDEE} does not generate a target.")
	endif()
endfunction()

#Calls targets.cmake:generate_targets() to create the declared target during the project phase run of the CMake. 
#Does nothing on the SUPERBUILD phase, as the internal project dependencies are of no concern then.
function(_get_target_internal __INSTANCE_ID)
#	message(STATUS "Inside _get_target_internal trying to instantiate ${__INSTANCE_NAME}")
	if(NOT __NOT_SUPERBUILD)
		return()
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} TEMPLATE __TEMPLATE_NAME)
	_make_instance_name(${__INSTANCE_ID} __INSTANCE_NAME)
	_retrieve_instance_data(${__INSTANCE_ID} PATH __TARGETS_CMAKE_PATH)
	_retrieve_instance_args(${__INSTANCE_ID} __ARGS)
	_retrieve_instance_data(${__INSTANCE_ID} MODIFIERS __ARGS__LIST_MODIFIERS)
	_retrieve_instance_data(${__INSTANCE_ID} DEPS __DEP_ID_LIST)
	
	if(NOT __TARGETS_CMAKE_PATH)
		message(FATAL_ERROR "Internal error: Empty __TARGETS_CMAKE_PATH")
	endif()
	
	#We need to populate all dependencies, so their names can be used in the targets.cmake
	foreach(__DEP_ID IN LISTS __DEP_ID_LIST)
		_make_instance_name(${__DEP_ID} __DEP_NAME)
		_retrieve_instance_data(${__DEP_ID} TEMPLATE __DEP_TEMPLATE_NAME)
		list(APPEND ${__DEP_TEMPLATE_NAME}_TARGET_NAME "${__DEP_NAME}")
	endforeach()

	set(TARGET_NAME ${__INSTANCE_NAME})
	set(${__TEMPLATE_NAME}_TARGET_NAME ${__INSTANCE_NAME})
	_instantiate_variables(__ARGS "${__ARGS__LIST_MODIFIERS}")
	_set_behavior_defining_targets()
	get_filename_component(__TEMPLATE_DIR "${__TARGETS_CMAKE_PATH}" DIRECTORY)
	_read_functions_from_targets_file("${__TARGETS_CMAKE_PATH}")
	
	set(CMAKE_CURRENT_SOURCE_DIR "${__TEMPLATE_DIR}")
	
#	message(FATAL_ERROR "Going to call generate targets for ${__TEMPLATE_NAME} from ${__TARGETS_CMAKE_PATH} with instance name set as «${__INSTANCE_NAME}» ")
	unset(__NO_OP)
	
	generate_targets(${__TEMPLATE_NAME})
	if(__NO_OP)
		_get_target_behavior(__TARGET_BEHAVIOR)
		if("${__TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
			message(FATAL_ERROR "File ${CMAKE_CURRENT_SOURCE_DIR}/targets.cmake did not define generate_targets() function.")
		endif()
	else()
		if(NOT TARGET "${${__TEMPLATE_NAME}_TARGET_NAME}")
			message(FATAL_ERROR "Called ${__TEMPLATE_DIR}/targets.cmake:generate_targets(${__TEMPLATE_NAME}) which did not produce the target with name TARGET_NAME = \"${TARGET_NAME}\"" )
		endif()
	endif()
endfunction()

#`_get_target_external(<TEMPLATE_NAME> <var_dictionary> <out_instance_name> <EXTERNAL_PROJECT_ARGS>)`

#2. Jeśli etap SUPERBUILD - Wywołuje `ExternalProject_Add` dla nazwy targetu policzonej na `var_dictionary` i zwraca tą nazwę targetu w `out_instance_name`
#3. Jeśli etap naszego projektu - wywołuje `find_packages`, tworzy alias dla importowanego targetu i zwraca nazwę `INSTANCE_NAME`.

# Pass empty __HASH if the external project does not support multiple instances (because the targets names are fixed)
function(_get_target_external __TEMPLATE_NAME __INSTANCE_NAME __TEMPLATE_DIR __PARS_PREFIX __ARGS_PREFIX __ARGS_LIST __EXTERNAL_PROJECT_ARGS __DEPENDENCIES_ID __HASH)
	set(__OPTIONS EXPORTS_TARGETS ASSUME_INSTALLED)
	set(__oneValueArgs PATH NAME)
	set(__multiValueArgs WHAT_COMPONENTS_NAME_DEPENDS_ON COMPONENTS)
	
	
	cmake_parse_arguments(__PARSED "${__OPTIONS}" "${__oneValueArgs}" "${__multiValueArgs}" ${__EXTERNAL_PROJECT_ARGS})
	set(__unparsed ${__PARSED_UNPARSED_ARGUMENTS})
	if(__unparsed)
		message(FATAL_ERROR "Undefined options for external project: ${__unparsed}")
	endif()
	
	if(__DEPENDENCIES_ID)
		set(DEPENDENCIES)
		foreach(__DEP_ID IN LISTS __DEPENDENCIES_ID)
			_make_instance_name(${__DEP_ID} __DEP_NAME)
			if(__DEP_NAME)
				list(APPEND DEPENDENCIES ${__DEP_NAME})
			else()
				_retrieve_instance_data(${__DEP_ID} TEMPLATE __DEP_TEMPLATE_NAME)
				message(WARNING "Cannot set proper dependency for external target ${__TEMPLATE_NAME} when dependency is a template ${__DEP_TEMPLATE_NAME} that does not produce a target")
			endif()
		endforeach()
		set(__DEP_STR "DEPENDS ${__DEPENDENCIES}")
	else()
		set(__DEP_STR )
	endif()
	
	if(NOT __PARSED_NAME)
		get_filename_component(__EXTERNAL_BARE_NAME ${__TEMPLATE_DIR} NAME_WE)
	else()
		set(__EXTERNAL_BARE_NAME "${__PARSED_NAME}")
	endif()
#	message(FATAL_ERROR "__TEMPLATE_BARE_NAME: ${__TEMPLATE_BARE_NAME}")
	name_external_project("${__PARSED_WHAT_COMPONENTS_NAME_DEPENDS_ON}" ${__EXTERNAL_BARE_NAME} __EXTERNAL_NAME)
	
	if(__HASH)
		set(__EXTERNAL_NAME "${__EXTERNAL_NAME}/${__HASH}")
	endif()
#	message(STATUS "_get_target_external(): The external project ${__INSTANCE_NAME} is going to be installed in install/${__EXTERNAL_NAME}")
	
	set(__INSTALL_DIR "${SUPERBUILD_ROOT}/install/${__EXTERNAL_NAME}")
#	message(STATUS "_get_target_external(): Going to add external project for ${__TEMPLATE_NAME} defined in the path ${__TEMPLATE_DIR}. We expect it will generate a target ${__INSTANCE_NAME}. The project will be installed in ${__INSTALL_DIR}")
	if(NOT __NOT_SUPERBUILD)
		if(NOT __PARSED_ASSUME_INSTALLED)
			string(REPLACE "::" "_" __INSTANCE_NAME_FIXED ${__INSTANCE_NAME})
			_make_cmake_args(${__PARS_PREFIX} ${__ARGS_PREFIX} "${__ARGS_LIST}" __CMAKE_ARGS)
#			message(FATAL_ERROR "__CMAKE_ARGS: ${__CMAKE_ARGS}, ${__PARS_PREFIX}__LIST: ${${__PARS_PREFIX}__LIST}")
	#		list(APPEND __CMAKE_ARGS "-D${CACHE_VAR}${CACHE_VAR_TYPE}=${${CACHE_VAR}}")
	#		list(APPEND __CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${__INSTALL_DIR})
			ExternalProject_Add("${__INSTANCE_NAME_FIXED}" 
				PREFIX ${__PARSED_PATH}
				SOURCE_DIR ${__PARSED_PATH}
				TMP_DIR ${SUPERBUILD_ROOT}/build/${__EXTERNAL_NAME}/tmp
				STAMP_DIR ${SUPERBUILD_ROOT}/build/${__EXTERNAL_NAME}/timestamps
				DOWNLOAD_DIR ${SUPERBUILD_ROOT}/build/download
				BINARY_DIR ${SUPERBUILD_ROOT}/build/${__EXTERNAL_NAME}
				INSTALL_DIR ${__INSTALL_DIR}
				CMAKE_ARGS ${__CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${__INSTALL_DIR}
				${__DEP_STR}
			)
#			message(STATUS "_get_target_external(): Setting external project ${__INSTANCE_NAME_FIXED} with the following arguments: ${__CMAKE_ARGS}")
			set_property(GLOBAL APPEND PROPERTY __BURAK_EXTERNAL_DEPENDENCIES "${__INSTANCE_NAME}")
		endif()
	else()
		
#		message(STATUS "_get_target_external(): __EXTERNAL_BARE_NAME: ${__EXTERNAL_BARE_NAME} __INSTANCE_NAME: ${__INSTANCE_NAME} __TEMPLATE_NAME: ${__TEMPLATE_NAME} ${__INSTANCE_NAME}_DIR: ${${__INSTANCE_NAME}_DIR}")
		if(NOT __PARSED_ASSUME_INSTALLED)
			set(${__EXTERNAL_BARE_NAME}_ROOT ${__INSTALL_DIR})
			set(${__EXTERNAL_BARE_NAME}_DIR ${__INSTALL_DIR})
			set(__PATHS "PATHS \"${__INSTALL_DIR}/cmake\" NO_CMAKE_FIND_ROOT_PATH")
		else()
			set(__PATHS)
		endif()
		if(__PARSED_COMPONENTS)
#			message(FATAL_ERROR "__PARSED_COMPONENTS: ${__PARSED_COMPONENTS}")
			set(__COMPONENTS COMPONENTS ${__PARSED_COMPONENTS})
		endif()
		find_package(${__EXTERNAL_BARE_NAME}
			${__PATHS}
			${__COMPONENTS}
			REQUIRED
		)
		if(NOT TARGET ${__INSTANCE_NAME} AND ${__PARSED_EXPORTS_TARGETS})
			message(FATAL_ERROR "${__EXTERNAL_BARE_NAME} did not produce an exported target ${__INSTANCE_NAME}" )
		endif()
#		add_library(${__INSTANCE_NAME} ALIAS ${__PARSED_TARGET_NAME})
	endif()
endfunction()

#Function that generates a local project as the external dependency in the SUPERBUILD phase
#that depends on all external dependencies
function(finalizer)
	message("")
	message("")
	message("")
	if(__NOT_SUPERBUILD)
		message("    DEFINING  TARGETS  IN  PROJECT BUILD")
	else()
		message("    DEFINING  TARGETS  IN  SUPERBUILD")
	endif()
	message("")
	_set_behavior_defining_targets() #To make sure we never call declare_dependencies()
	
	#Now we need to instantiate all the targets
	_get_all_instance_ids(__INSTANCE_ID_LIST)
#	message(STATUS "finalizer: __INSTANCE_ID_LIST: ${__INSTANCE_ID_LIST}")
	if(__INSTANCE_ID_LIST)
		foreach(__DEP_ID IN LISTS __INSTANCE_ID_LIST)
#			message(STATUS "finalizer(): Going to instantiate ${__DEP_ID}")
			_instantiate_target(${__DEP_ID})
		endforeach()
		if(NOT __NOT_SUPERBUILD)
			get_property(__EXTERNAL_DEPENDENCIES GLOBAL PROPERTY __BURAK_EXTERNAL_DEPENDENCIES)
			if(__EXTERNAL_DEPENDENCIES)
				set(__EXT_DEP_STR "DEPENDS ")
				foreach(__EXT_DEP IN LISTS __EXTERNAL_DEPENDENCIES)
					string(REPLACE "::" "_" __EXT_DEP_FIXED ${__EXT_DEP})
					set(__EXT_DEP_STR "${__EXT_DEP_STR} ${__EXT_DEP_FIXED}")
				endforeach()
			endif()
			message(STATUS "End of SUPERBUILD phase. External projects: ${__EXT_DEP_STR} CMAKE_PROJECT_NAME: ${CMAKE_PROJECT_NAME}")
			set(__EXT_DEP_STR ${__EXT_DEP_STR})
			ExternalProject_Add(${CMAKE_PROJECT_NAME}
				PREFIX ${CMAKE_SOURCE_DIR}
				SOURCE_DIR ${CMAKE_SOURCE_DIR}
				TMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/tmp
				STAMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/stamps
				DOWNLOAD_DIR "${CMAKE_CURRENT_BINARY_DIR}"
				INSTALL_COMMAND ""
				BUILD_ALWAYS ON
				BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/project"
				${__EXT_DEP_STR}
#				DEPENDS Serialbox_SerialboxCStatic
				CMAKE_ARGS -D__NOT_SUPERBUILD=ON
			)
		endif()
	else()
		message(WARNING "No targets declared")
	endif()
endfunction()

macro(finalize)
	finalizer()
endmacro()

function(_read_functions_from_targets_file __TARGETS_CMAKE_PATH)
	get_property(__LAST_READ_FILE GLOBAL PROPERTY __BURAK_LAST_READ_FILE)
	if(NOT "${__LAST_READ_FILE}" STREQUAL "${__TARGETS_CMAKE_PATH}")
		_read_targets_file("${__TARGETS_CMAKE_PATH}" __DUMMY __DUMMY2)
	endif()
endfunction()


# The function that actually reads in the targets.cmake file. All read variables are stored in parent scope with ${__OUT_READ_PREFIX} prefix.
# In case last optional argument is NOT present ENUM_TEMPLATES from ENUM_TARGETS are prepended with "*" character.
function(_read_targets_file __TARGETS_CMAKE_PATH __OUT_READ_PREFIX __OUT_IS_TARGET_FIXED)

	get_filename_component(__TARGETS_CMAKE_DIR "${__TARGETS_CMAKE_PATH}" DIRECTORY)
	set(CMAKE_CURRENT_SOURCE_DIR "${__TARGETS_CMAKE_DIR}")
#	set(__TARGETS_CMAKE_PATH "${__TARGETS_CMAKE_DIR}/targets.cmake")
	function(declare_dependencies DUMMY_VAR)
		#nothing to declare
	endfunction()
	
	function(generate_targets DUMMY_VAR)
		set(__NO_OP 1 PARENT_SCOPE) #To signal the caller, that the function in fact was not defined
	endfunction()
	function(apply_to_target INSTANCE_NAME DEP_INSTANCE_NAME)
#		target_link_libraries(${INSTANCE_NAME} ${DEP_INSTANCE_NAME})  <- For dependencies that do not define targets this call does not make sense.
		set(__NO_OP 1 PARENT_SCOPE) #To signal the caller, that the function in fact was not defined, only the default version was used
	endfunction()

	unset(DEFINE_PARAMETERS)
	unset(DEFINE_MODIFIERS)
	unset(ENUM_TEMPLATES)
	unset(ENUM_TARGETS)
	unset(DEFINE_EXTERNAL_PROJECT)
	
#	message(STATUS "_read_targets_file(): Reading in ${__TARGETS_CMAKE_PATH}...")
	include(${__TARGETS_CMAKE_PATH} OPTIONAL RESULT_VARIABLE __FILE_LOADED)
	if("${__FILE_LOADED}" STREQUAL "NOTFOUND")
		message(FATAL_ERROR "Cannot find targets.cmake in ${__TARGETS_CMAKE_PATH}")
	endif()
	if(NOT DEFINED ENUM_TEMPLATES AND NOT DEFINED ENUM_TARGETS)
		message(FATAL_ERROR "You must define either ENUM_TEMPLATES or ENUM_TARGETS in ${__TARGETS_CMAKE_PATH}")
	endif()
	if(DEFINED ENUM_TEMPLATES AND DEFINED ENUM_TARGETS)
		message(FATAL_ERROR "You cannot define both ENUM_TEMPLATES and ENUM_TARGETS in ${__TARGETS_CMAKE_PATH}")
	endif()
	if(DEFINED ENUM_TARGETS)
		set(${__OUT_IS_TARGET_FIXED} 1 PARENT_SCOPE)
		set(ENUM_TEMPLATES ${ENUM_TARGETS})
	else()
		set(${__OUT_IS_TARGET_FIXED} 0 PARENT_SCOPE)
	endif()
	if(__OUT_READ_PREFIX)
		set(${__OUT_READ_PREFIX}_DEFINE_PARAMETERS "${DEFINE_PARAMETERS}" PARENT_SCOPE)
		set(${__OUT_READ_PREFIX}_DEFINE_MODIFIERS "${DEFINE_MODIFIERS}" PARENT_SCOPE)
		set(${__OUT_READ_PREFIX}_ENUM_TEMPLATES "${ENUM_TEMPLATES}" PARENT_SCOPE)
		set(${__OUT_READ_PREFIX}_DEFINE_EXTERNAL_PROJECT "${DEFINE_EXTERNAL_PROJECT}" PARENT_SCOPE)
	endif()
	set_property(GLOBAL PROPERTY __BURAK_LAST_READ_FILE "${__TARGETS_CMAKE_PATH}")
endfunction()

function(__prepare_template_list)
	set(__PS "PARENT_SCOPE")
	set(__TEMPLATE_FILENAME "${SUPERBUILD_ROOT}/build/templates.cmake")
	if(EXISTS "${__TEMPLATE_FILENAME}")
		include("${__TEMPLATE_FILENAME}")
	else()
		file(GLOB_RECURSE __TARGETS_CMAKE_LIST CONFIGURE_DEPENDS "${SUPERBUILD_ROOT}/targets.cmake")
		file(GLOB_RECURSE __EXTERNAL_TARGETS_CMAKE_LIST CONFIGURE_DEPENDS "${SUPERBUILD_ROOT}/cmake/targets/*.cmake")
		set(__STR_OUT)
		set(__TEMPLATES__LIST)
		foreach(__FILE IN LISTS __TARGETS_CMAKE_LIST __EXTERNAL_TARGETS_CMAKE_LIST)
#			message(STATUS "__prepare_template_list(): Trying to read file ${__FILE}...")
			_read_targets_file("${__FILE}" __TARGETS_CMAKE_PREFIX __IS_TARGET_FIXED)
			foreach(__TARGET IN LISTS __TARGETS_CMAKE_PREFIX_ENUM_TEMPLATES)
#				string(REGEX REPLACE "^\\*" "" __TARGET "${__TEMPLATE}") #removes "*" in front of fixed targets
				if("${__TARGET}" IN_LIST __TEMPLATES)
					message(FATAL_ERROR "Duplicate template name detected. One instance declared in ${__TEMPLATES_${__TARGET}} and the other in ${__FILE}")
				endif()
				list(APPEND __TEMPLATES__LIST "${__TEMPLATE}")
				set(__TEMPLATES_${__TARGET} "${__FILE}" ${__PS})
#				message(STATUS "__prepare_template_list(): Found ${__TARGET}.")
				set(__STR_OUT "${__STR_OUT}\nset(__TEMPLATES_${__TARGET} \"${__FILE}\" ${__PS})")
			endforeach()
		endforeach()
		set(__TEMPLATES__LIST "${__TEMPLATES__LIST}" ${__PS})
		set(__STR_OUT "${__STR_OUT}\nset(__TEMPLATES__LIST \"${__TEMPLATES__LIST}\" ${__PS})")
		file(WRITE ${SUPERBUILD_ROOT}/build/templates.cmake "${__STR_OUT}")
	endif()
endfunction()

function(__find_targets_cmake_by_template_name __TEMPLATE_NAME __OUT_TARGETS_CMAKE_PATH __OUT_IS_TARGET_FIXED)
	set(__TEMPLATE_FILENAME "${SUPERBUILD_ROOT}/build/templates.cmake")
	if(EXISTS "${__TEMPLATE_FILENAME}")
		include("${__TEMPLATE_FILENAME}")
	else()
		message(FATAL_ERROR "Cannot find ${__TEMPLATE_FILENAME}")
	endif()
	if(DEFINED __TEMPLATES_${__TEMPLATE_NAME})
		set(${__OUT_TARGETS_CMAKE_PATH} "${__TEMPLATES_${__TEMPLATE_NAME}}" PARENT_SCOPE)
		if("*${__TEMPLATE_NAME}" IN_LIST __TEMPLATES__LIST)
			set(${__OUT_IS_TARGET_FIXED} 1 PARENT_SCOPE)
		else()
			set(${__OUT_IS_TARGET_FIXED} 0 PARENT_SCOPE)
		endif()
	else()
		message(FATAL_ERROR "Cannot find ${__TEMPLATE_NAME} among known templates")
	endif()
endfunction()

__prepare_template_list()


