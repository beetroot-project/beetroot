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
include(${__PREFIX}/burak_variables.cmake)
include(${__PREFIX}/burak_global_storage.cmake)
include(${__PREFIX}/burak_global_storage_misc.cmake)
include(${__PREFIX}/burak_dependency_processing.cmake)
include(${__PREFIX}/build_install_prefix.cmake)
include(${__PREFIX}/set_operations.cmake)
include(${__PREFIX}/prepare_arguments_to_pass.cmake)

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

#Calls targets.cmake:generate_targets() to create the declared target during the project phase run of the CMake. 
#Does nothing on the SUPERBUILD phase, as the internal project dependencies are of no concern then.
function(_get_target_internal __INSTANCE_ID __OUT_FUNCTION_EXISTS)
#	message(STATUS "Inside _get_target_internal trying to instantiate ${__INSTANCE_NAME}")
	if(NOT __NOT_SUPERBUILD)
		return()
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
	_make_instance_name(${__INSTANCE_ID} __INSTANCE_NAME)
	_retrieve_instance_data(${__INSTANCE_ID} PATH __TARGETS_CMAKE_PATH)

	_retrieve_instance_args(${__INSTANCE_ID} I_FEATURES __ARGS)
	set(__ARGS__LIST_FEATURES "${__ARGS__LIST}")
	_retrieve_instance_args(${__INSTANCE_ID} MODIFIERS __ARGS)
	set(__ARGS__LIST_MODIFIERS "${__ARGS__LIST}")
	list(APPEND __ARGS__LIST ${__ARGS__LIST_FEATURES})
	
	_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __DEP_ID_LIST)
	
	if(NOT __TARGETS_CMAKE_PATH)
		message(FATAL_ERROR "Internal error: Empty __TARGETS_CMAKE_PATH")
	endif()
	
	#We need to populate all dependencies, so their names can be used in the targets.cmake
	foreach(__DEP_ID IN LISTS __DEP_ID_LIST)
		_make_instance_name(${__DEP_ID} __DEP_NAME)
		_retrieve_instance_data(${__DEP_ID} I_TEMPLATE_NAME __DEP_TEMPLATE_NAME)
		list(APPEND ${__DEP_TEMPLATE_NAME}_TARGET_NAME "${__DEP_NAME}")
	endforeach()

	set(TARGET_NAME ${__INSTANCE_NAME})
	set(${__TEMPLATE_NAME}_TARGET_NAME ${__INSTANCE_NAME})
	_instantiate_variables(__ARGS "${__ARGS__LIST}")
	get_filename_component(__TEMPLATE_DIR "${__TARGETS_CMAKE_PATH}" DIRECTORY)
	_read_functions_from_targets_file("${__TARGETS_CMAKE_PATH}")
	
	set(CMAKE_CURRENT_SOURCE_DIR "${__TEMPLATE_DIR}")
	
#	message(FATAL_ERROR "Going to call generate targets for ${__TEMPLATE_NAME} from ${__TARGETS_CMAKE_PATH} with instance name set as «${__INSTANCE_NAME}» ")
	unset(__NO_OP)
	
	generate_targets(${__TEMPLATE_NAME})
	_retrieve_instance_data(${__INSTANCE_ID} NO_TARGETS __NO_TARGETS )
	_retrieve_instance_data(${__INSTANCE_ID} TARGETS_REQUIRED __TARGETS_REQUIRED )
	if(__NO_OP)
		_get_target_behavior(__TARGET_BEHAVIOR)
		if("${__TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
			message(FATAL_ERROR "File ${CMAKE_CURRENT_SOURCE_DIR}/targets.cmake did not define generate_targets() function.")
		endif()
		if(__TARGETS_REQUIRED)
			message(FATAL_ERROR "File ${CMAKE_CURRENT_SOURCE_DIR}/targets.cmake did not define generate_targets() function. If you cannot produce targets, please add NO_TARGETS option to TEMPLATE_OPTIONS variable defined in this file.")
		endif()
		set(${__OUT_FUNCTION_EXISTS} 0 PARENT_SCOPE)
	else()
		if(__NO_TARGETS)
			message(FATAL_ERRLR "File ${CMAKE_CURRENT_SOURCE_DIR}/targets.cmake defined generate_targets() function while also declared NO_TARGETS option.")
		endif()
		if(__TARGETS_REQUIRED AND NOT TARGET "${${__TEMPLATE_NAME}_TARGET_NAME}")
			message(FATAL_ERROR "Called ${__TEMPLATE_DIR}/targets.cmake:generate_targets(${__TEMPLATE_NAME}) which did not produce the target with name TARGET_NAME = \"${TARGET_NAME}\"" )
		endif()
		set(${__OUT_FUNCTION_EXISTS} 1 PARENT_SCOPE)
	endif()
endfunction()

macro(_parse_all_external_info __EXTERNAL_INFO __OUT_PREFIX)
	set(__OPTIONS ASSUME_INSTALLED)
	set(__oneValueArgs SOURCE_PATH INSTALL_PATH NAME EXPORTED_TARGETS_PATH)
	set(__multiValueArgs WHAT_COMPONENTS_NAME_DEPENDS_ON COMPONENTS BUILD_PARAMETERS APT_PACKAGES SPACK_PACKAGES)
	
	cmake_parse_arguments(${__OUT_PREFIX} "${__OPTIONS}" "${__oneValueArgs}" "${__multiValueArgs}" "${__EXTERNAL_INFO}")
	set(__unparsed ${__PARSED_UNPARSED_ARGUMENTS})
	if(__unparsed)
		message(FATAL_ERROR "Undefined options for external project: ${__unparsed}. All options: ${__EXTERNAL_INFO}")
	endif()
endmacro()

function(_parse_external_info __EXTERNAL_INFO __TARGETS_CMAKE_PATH __PROPERTIES __OUT_PREFIX)
	_parse_all_external_info("${__EXTERNAL_INFO}" ___P)
#	message(STATUS "_parse_external_info(): __PROPERTIES: ${__PROPERTIES}")
	foreach(__PROPERTY IN LISTS __PROPERTIES)
		if(NOT ${__PROPERTY} IN_LIST __OPTIONS AND NOT ${__PROPERTY} IN_LIST __oneValueArgs AND NOT ${__PROPERTY} IN_LIST __multiValueArgs)
			message(FATAL_ERROR "Internal Beetroot error: property name ${__PROPERTY} is not valid for external project options in file ${__TARGETS_CMAKE_PATH}")
		endif()
		set(${__OUT_PREFIX}_${__PROPERTY} "${___P_${__PROPERTY}}" PARENT_SCOPE)
	endforeach()
endfunction()

#`_get_target_external(<TEMPLATE_NAME> <var_dictionary> <out_instance_name> <EXTERNAL_PROJECT_ARGS>)`

#2. Jeśli etap SUPERBUILD - Wywołuje `ExternalProject_Add` dla nazwy targetu policzonej na `var_dictionary` i zwraca tą nazwę targetu w `out_instance_name`
#3. Jeśli etap naszego projektu - wywołuje `find_packages`, tworzy alias dla importowanego targetu i zwraca nazwę `INSTANCE_NAME`.

# Pass empty __HASH if the external project does not support multiple instances (because the targets names are fixed)
function(_get_target_external __INSTANCE_ID __DEP_TARGETS)
	_retrieve_instance_data(${__INSTANCE_ID} EXTERNAL_INFO __EXTERNAL_INFO) 
	_parse_all_external_info("${__EXTERNAL_INFO}" __PARSED)
	
	if(NOT __PARSED_SOURCE_PATH AND NOT __PARSED_ASSUME_INSTALLED)
		message(FATAL_ERROR "External project must name PATH or be ASSUME_INSTALLED")
	else()
		get_filename_component(__PARSED_SOURCE_PATH "${__PARSED_SOURCE_PATH}" REALPATH BASE_DIR "${SUPERBUILD_ROOT}")
	endif()
	
	if(__DEP_TARGETS)
		foreach(__DEP IN LISTS __DEP_TARGETS)
			
		endforeach()
		set(__DEP_STR "DEPENDS ${__DEP_TARGETS}")
	else()
		set(__DEP_STR )
	endif()
	
	_retrieve_instance_data(${__INSTANCE_ID} PATH __TARGETS_CMAKE_PATH) 
	get_filename_component(__TEMPLATE_DIR ${__TARGETS_CMAKE_PATH} DIRECTORY)
	if(NOT __PARSED_NAME)
		get_filename_component(__EXTERNAL_BARE_NAME ${__TEMPLATE_DIR} NAME_WE)
	else()
		set(__EXTERNAL_BARE_NAME "${__PARSED_NAME}")
	endif()
	name_external_project("${__PARSED_WHAT_COMPONENTS_NAME_DEPENDS_ON}" ${__EXTERNAL_BARE_NAME} __EXTERNAL_NAME)
	
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE) 
	
	set(__EXTERNAL_NAME "${__EXTERNAL_NAME}/${__FEATUREBASE}")
	_make_instance_name(${__INSTANCE_ID} __INSTANCE_NAME)
	
	if(__PARSED_INSTALL_PATH)
		get_filename_component(__INSTALL_DIR "${__PARSED_INSTALL_PATH}" REALPATH BASE_DIR "${SUPERBUILD_ROOT}")
		
	else()
		set(__INSTALL_DIR "${SUPERBUILD_ROOT}/install/${__EXTERNAL_NAME}")
		_retrieve_instance_data(${__INSTANCE_ID} F_HASH_SOURCE __HASH_SOURCE)
		if("${__HASH_SOURCE}" STREQUAL "")
			message(FATAL_ERROR "Internal beetroot error: empty __HASH_SOURCE ${__HASH_SOURCE} for ${__EXTERNAL_NAME}")
		endif()
		message(STATUS "Going to use ${__INSTALL_DIR} for ${__INSTANCE_NAME} because it is a hash of \"${__HASH_SOURCE}.\"")
	endif()
	
#	message(STATUS "_get_target_external(): Going to add external project for ${__TEMPLATE_NAME} defined in the path ${__TEMPLATE_DIR}. We expect it will generate a target ${__INSTANCE_NAME}. The project will be installed in ${__INSTALL_DIR}")
	if(NOT __NOT_SUPERBUILD)
		if(NOT __PARSED_ASSUME_INSTALLED)
			string(REPLACE "::" "_" __INSTANCE_NAME_FIXED ${__INSTANCE_NAME})
			
			_retrieve_instance_args(${__INSTANCE_ID} I_FEATURES __ARGS)
			set(__ARGS__LIST_FEATURES "${__ARGS__LIST}")
			_retrieve_instance_args(${__INSTANCE_ID} MODIFIERS __ARGS)
			set(__ARGS__LIST_MODIFIERS "${__ARGS__LIST}")
			list(APPEND __ARGS__LIST ${__ARGS__LIST_FEATURES})
			if(__PARSED_BUILD_PARAMETERS)
				foreach(__PAR IN LISTS __PARSED_BUILD_PARAMETERS)
					if(NOT "${__PAR}" IN_LIST __ARGS__LIST)
						message(FATAL_ERROR "Cannot find ${__PAR} among list of declared TARGET_PARAMETERS and TARGET_FEATURES. Remove ${__PAR} from BUILD_PARAMETERS in DEFINE_EXTERNAL_PROJECT.")
					endif()
				endforeach()
				set(__ARGS__LIST ${__PARSED_BUILD_PARAMETERS})
			endif()
			_retrieve_instance_pars(${__INSTANCE_ID} __PARS)
			_make_cmake_args(__PARS __ARGS "${__ARGS__LIST}" __CMAKE_ARGS)
#			message(FATAL_ERROR "__CMAKE_ARGS: ${__CMAKE_ARGS}, ${__PARS_PREFIX}__LIST: ${${__PARS_PREFIX}__LIST}")
	#		list(APPEND __CMAKE_ARGS "-D${CACHE_VAR}${CACHE_VAR_TYPE}=${${CACHE_VAR}}")
	#		list(APPEND __CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${__INSTALL_DIR})
			ExternalProject_Add("${__INSTANCE_NAME_FIXED}" 
				${__DEP_STR}
				PREFIX ${__PARSED_SOURCE_PATH}
				SOURCE_DIR ${__PARSED_SOURCE_PATH}
				TMP_DIR ${SUPERBUILD_ROOT}/build/${__EXTERNAL_NAME}/tmp
				STAMP_DIR ${SUPERBUILD_ROOT}/build/${__EXTERNAL_NAME}/timestamps
				DOWNLOAD_DIR ${SUPERBUILD_ROOT}/build/download
				BINARY_DIR ${SUPERBUILD_ROOT}/build/${__EXTERNAL_NAME}
				INSTALL_DIR ${__INSTALL_DIR}
				CMAKE_ARGS ${__CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${__INSTALL_DIR}
			)
#			message(STATUS "_get_target_external(): Setting external project ${__INSTANCE_NAME_FIXED} with the following arguments: ${__CMAKE_ARGS}")
			set_property(GLOBAL APPEND PROPERTY __BURAK_EXTERNAL_DEPENDENCIES "${__INSTANCE_NAME}")
			_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)
			_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} TARGET_BUILT 1)
		endif()
	else()
		
#		message(STATUS "_get_target_external(): __EXTERNAL_BARE_NAME: ${__EXTERNAL_BARE_NAME} __INSTANCE_NAME: ${__INSTANCE_NAME} __TEMPLATE_NAME: ${__TEMPLATE_NAME} ${__INSTANCE_NAME}_DIR: ${${__INSTANCE_NAME}_DIR}")
		if(__PARSED_INSTALL_PATH OR NOT __PARSED_ASSUME_INSTALLED)
			set(${__EXTERNAL_BARE_NAME}_ROOT ${__INSTALL_DIR})
			set(${__EXTERNAL_BARE_NAME}_DIR ${__INSTALL_DIR})
			if(__PARSED_EXPORTED_TARGETS_PATH)
#				message(STATUS "_get_target_external(): __PARSED_EXPORTED_TARGETS_PATH: ${__PARSED_EXPORTED_TARGETS_PATH}")
				set(__PATHS HINTS ${__INSTALL_DIR}/${__PARSED_EXPORTED_TARGETS_PATH} NO_CMAKE_FIND_ROOT_PATH)
			else()
				set(__PATHS HINTS ${__INSTALL_DIR}/cmake ${__INSTALL_DIR} NO_CMAKE_FIND_ROOT_PATH)
			endif()
		else()
			set(__PATHS)
		endif()
		if(__PARSED_COMPONENTS)
#			message(FATAL_ERROR "__PARSED_COMPONENTS: ${__PARSED_COMPONENTS}")
			set(__COMPONENTS COMPONENTS ${__PARSED_COMPONENTS})
		endif()
		set(__INVOCATION ${__EXTERNAL_BARE_NAME} ${__PATHS} ${__COMPONENTS} REQUIRED)
#		message(STATUS "_get_target_external(): find_package(${__INVOCATION})")
#		find_package(${__INVOCATION})
		find_package(${__EXTERNAL_BARE_NAME} ${__PATHS} ${__COMPONENTS} REQUIRED )
		if(NOT TARGET ${__INSTANCE_NAME} AND NOT __NO_TARGETS)
			_get_nice_name(${__INSTANCE_ID} __DESCRIPTION)
			_get_nice_dependencies_name(${__INSTANCE_ID} __REQUIREDBY)
			set(__PACKAGES )
			if(__PARSED_APT_PACKAGES)
				list(APPEND __PACKAGES APT_PACKAGES ${__PARSED_APT_PACKAGES})
			endif()
			if(__PARSED_SPACK_PACKAGES)
				list(APPEND __PACKAGES SPACK_PACKAGES ${__PARSED_SPACK_PACKAGES})
			endif()
			missing_dependency(
				DESCRIPTION ${__DESCRIPTION}
				REQUIRED_BY "${__REQUIREDBY}"
				${__PACKAGES}
			)
		endif()
	endif()
endfunction()

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
	function(apply_dependency_to_target INSTANCE_NAME DEP_INSTANCE_NAME)
#		target_link_libraries(${INSTANCE_NAME} ${DEP_INSTANCE_NAME})  <- For dependencies that do not define targets this call does not make sense.
		set(__NO_OP 1 PARENT_SCOPE) #To signal the caller, that the function in fact was not defined, only the default version was used
#		message(STATUS "default apply_to_target(): calling with INSTANCE_NAME: ${INSTANCE_NAME} and DEP_INSTANCE_NAME: ${DEP_INSTANCE_NAME}")
	endfunction()

	unset(LINK_PARAMETERS)
	unset(TARGET_PARAMETERS)
	unset(TARGET_FEATURES)
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
		set(${__OUT_READ_PREFIX}_LINK_PARAMETERS "${LINK_PARAMETERS}" PARENT_SCOPE)
		set(${__OUT_READ_PREFIX}_TARGET_PARAMETERS "${TARGET_PARAMETERS}" PARENT_SCOPE)
		set(${__OUT_READ_PREFIX}_TARGET_FEATURES "${TARGET_FEATURES}" PARENT_SCOPE)
		set(${__OUT_READ_PREFIX}_ENUM_TEMPLATES "${ENUM_TEMPLATES}" PARENT_SCOPE)
		set(${__OUT_READ_PREFIX}_DEFINE_EXTERNAL_PROJECT "${DEFINE_EXTERNAL_PROJECT}" PARENT_SCOPE)
		if(TEMPLATE_OPTIONS)
#			message(STATUS "_read_targets_file(): TEMPLATE_OPTIONS: ${TEMPLATE_OPTIONS}")
		endif()
		set(${__OUT_READ_PREFIX}_TEMPLATE_OPTIONS "${TEMPLATE_OPTIONS}" PARENT_SCOPE)
	endif()
	set_property(GLOBAL PROPERTY __BURAK_LAST_READ_FILE "${__TARGETS_CMAKE_PATH}")
endfunction()

function(__prepare_template_list)
	set(__TEMPLATE_FILENAME "${SUPERBUILD_ROOT}/build/templates.cmake")
	if(EXISTS "${__TEMPLATE_FILENAME}" AND FALSE)
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
				string(REPLACE "::" "_" __TARGET_FIXED "${__TARGET}")
				string(REPLACE "-" "_" __TARGET_FIXED "${__TARGET_FIXED}")
				if("${__TARGET_FIXED}" IN_LIST __TEMPLATES)
					message(FATAL_ERROR "Duplicate template name detected. One instance declared in ${__TEMPLATES_${__TARGET_FIXED}} and the other in ${__FILE}")
				endif()
				list(APPEND __TEMPLATES__LIST "${__TARGET_FIXED}")
				set(__TEMPLATES_${__TARGET_FIXED} "${__FILE}" PARENT_SCOPE)
#				message(STATUS "__prepare_template_list(): Found ${__TARGET_FIXED}.")
				set(__STR_OUT "${__STR_OUT}\nset(__TEMPLATES_${__TARGET_FIXED} \"${__FILE}\" PARENT_SCOPE)")
			endforeach()
		endforeach()
		string(REPLACE ";" " " __TEMPLATES_SPACES "${__TEMPLATES__LIST}")
#		message(STATUS "__prepare_template_list(): __STR_OUT: ${__STR_OUT}")
		set(__STR_OUT "${__STR_OUT}\nset(__TEMPLATES__LIST ${__TEMPLATES_SPACES} PARENT_SCOPE)")
#		message(STATUS "__prepare_template_list(): __STR_OUT: ${__STR_OUT}")
		file(WRITE ${SUPERBUILD_ROOT}/build/templates.cmake "${__STR_OUT}")
	endif()
	message("")
	message("")
	message("")
	if(__NOT_SUPERBUILD)
		message("    DECLARING  DEPENDENCIES  IN  PROJECT BUILD")
	else()
		message("    DECLARING  DEPENDENCIES  IN  SUPERBUILD")
	endif()
	message("")
endfunction()

function(__find_targets_cmake_by_template_name __TEMPLATE_NAME __OUT_TARGETS_CMAKE_PATH __OUT_IS_TARGET_FIXED)
	set(__TEMPLATE_FILENAME "${SUPERBUILD_ROOT}/build/templates.cmake")
	if(EXISTS "${__TEMPLATE_FILENAME}")
		include("${__TEMPLATE_FILENAME}")
	else()
		message(FATAL_ERROR "Cannot find ${__TEMPLATE_FILENAME}")
	endif()
	string(REPLACE "::" "_" __TEMPLATE_NAME "${__TEMPLATE_NAME}")
	string(REPLACE "-" "_" __TEMPLATE_NAME "${__TEMPLATE_NAME}")
#	message(STATUS "__find_targets_cmake_by_template_name(): Looking up for __TEMPLATE_NAME: ${__TEMPLATE_NAME}")

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


