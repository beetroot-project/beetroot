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
	
endmacro()


function(get_target __TEMPLATE_NAME __OUT_INSTANCE_NAME) 
	_get_target_behavior(__GET_TARGET_BEHAVIOR)
#	message(STATUS "Called get_target(${__TEMPLATE_NAME}) on phase ${__GET_TARGET_BEHAVIOR}")
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "INSIDE_GENERATE_TARGETS")
		message(FATAL_ERROR "Calling get_target from inside generate_targets is disallowed. To call dependency use declare_dependencies() (in which you cannot define targets).")
	endif()
	if(NOT __TEMPLATE_NAME)
		message(FATAL_ERROR "get_error was called without any arguments")
	endif()
	_parse_TARGETS_PATH("${__TEMPLATE_NAME}" ${ARGN})
	
	
	_get_variables("${__TARGETS_CMAKE_PATH}" "" __VARIABLE_DIC __PARAMETERS_DIC __TEMPLATES __EXTERNAL_PROJECT_INFO __IS_TARGET_FIXED __TEMPLATE_OPTIONS ${__ARGS})
	if("${__VARIABLE_DIC_VERSION}" STREQUAL "KUC")
		message(FATAL_ERROR "__VARIABLE_DIC_VERSION: ${__VARIABLE_DIC_VERSION}")
	endif()
	_make_instance_id(${__TEMPLATE_NAME} __VARIABLE_DIC "" __INSTANCE_ID)
#	message(STATUS "get_target: __TEMPLATE_NAME ${__TEMPLATE_NAME} got __INSTANCE_ID: ${__INSTANCE_ID}")
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "GATHERING_DEPENDENCIES" OR "${__GET_TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
		#Add dependencies together with their arguments to the list. They will be instatiated later on, during generate_targets run
		_put_dependencies_into_stack("${__INSTANCE_ID}")
		set(__LIST ${__PARAMETERS_DIC__LIST_MODIFIERS})
		list(APPEND __LIST ${__PARAMETERS_DIC__LIST_LINKPARS} )
		_discover_dependencies(${__TEMPLATE_NAME} "${__TARGETS_CMAKE_PATH}" __VARIABLE_DIC "${__LIST}" __DEP_INSTANCE_ID_LIST)
		if("${__GET_TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
			set(__TARGET_REQUIRED 1)
		else()
			set(__TARGET_REQUIRED 0)
		endif()
		_get_parent_dependency_from_stack(__PARENT_INSTANCE_ID)
		_store_instance_data(
			 ${__INSTANCE_ID}
			"${__PARENT_INSTANCE_ID}"
			__VARIABLE_DIC 
			__PARAMETERS_DIC
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

function(_invoke_apply_dependency_to_target __DEPENDEE_INSTANCE_ID __INSTANCE_ID __OUT_FUNCTION_EXISTS)
	_retrieve_instance_data(${__DEPENDEE_INSTANCE_ID} PATH __TARGETS_CMAKE_PATH)
	_retrieve_instance_args(${__DEPENDEE_INSTANCE_ID} MODIFIERS __ARGS)
	set(__TMP_LIST "${__ARGS__LIST}")
	_retrieve_instance_args(${__DEPENDEE_INSTANCE_ID} I_FEATURES __ARGS)
	list(APPEND __TMP_LIST ${__ARGS__LIST})
	_retrieve_instance_args(${__DEPENDEE_INSTANCE_ID} LINKPARS __ARGS)
	list(APPEND __TMP_LIST ${__ARGS__LIST})
	set(__ARGS__LIST ${__TMP_LIST})
	_make_instance_name(${__DEPENDEE_INSTANCE_ID} __DEP_INSTANCE_NAME)
	_make_instance_name(${__INSTANCE_ID} __INSTANCE_NAME)
	
	_read_functions_from_targets_file("${__TARGETS_CMAKE_PATH}")
	_instantiate_variables(__ARGS "${__ARGS__LIST}")
	unset(__NO_OP)
#	apply_to_target(${__DEPENDEE_INSTANCE_ID} ${__INSTANCE_NAME})
#	take_dependency_from_target(${__DEPENDEE_INSTANCE_ID} ${__INSTANCE_NAME})
	apply_dependency_to_target(${__DEP_INSTANCE_NAME} ${__INSTANCE_NAME})

#	message(STATUS "_invoke_apply_dependency_to_target(): __NO_OP: ${__NO_OP}")
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

#`_get_target_external(<TEMPLATE_NAME> <var_dictionary> <out_instance_name> <EXTERNAL_PROJECT_ARGS>)`

#2. Jeśli etap SUPERBUILD - Wywołuje `ExternalProject_Add` dla nazwy targetu policzonej na `var_dictionary` i zwraca tą nazwę targetu w `out_instance_name`
#3. Jeśli etap naszego projektu - wywołuje `find_packages`, tworzy alias dla importowanego targetu i zwraca nazwę `INSTANCE_NAME`.

# Pass empty __HASH if the external project does not support multiple instances (because the targets names are fixed)
function(_get_target_external __INSTANCE_ID __DEP_TARGETS)
# __TEMPLATE_NAME __INSTANCE_NAME __TEMPLATE_DIR __PARS_PREFIX __ARGS_PREFIX __ARGS_LIST __EXTERNAL_PROJECT_ARGS __DEPENDENCIES_ID __HASH __NO_TARGETS
	set(__OPTIONS ASSUME_INSTALLED)
	set(__oneValueArgs SOURCE_PATH INSTALL_PATH NAME)
	set(__multiValueArgs WHAT_COMPONENTS_NAME_DEPENDS_ON COMPONENTS BUILD_PARAMETERS)
	
	_retrieve_instance_data(${__INSTANCE_ID} EXTERNAL_INFO __EXTERNAL_INFO) 
	cmake_parse_arguments(__PARSED "${__OPTIONS}" "${__oneValueArgs}" "${__multiValueArgs}" "${__EXTERNAL_INFO}")
	set(__unparsed ${__PARSED_UNPARSED_ARGUMENTS})
	if(__unparsed)
		message(FATAL_ERROR "Undefined options for external project: ${__unparsed}")
	endif()
	
	if(NOT __PARSED_SOURCE_PATH AND NOT __PARSED_ASSUME_INSTALLED)
		message(FATAL_ERROR "External project must name PATH or be ASSUME_INSTALLED")
	else()
		get_filename_component(__PARSED_SOURCE_PATH "${__PARSED_SOURCE_PATH}" REALPATH BASE_DIR "${SUPERBUILD_ROOT}"])
	endif()
	
	if(__DEP_TARGETS)
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
		get_filename_component(__INSTALL_DIR "${__PARSED_INSTALL_PATH}" REALPATH BASE_DIR "${SUPERBUILD_ROOT}"])
		
	else()
		set(__INSTALL_DIR "${SUPERBUILD_ROOT}/install/${__EXTERNAL_NAME}")
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
			set(__PATHS "HINTS \"${__INSTALL_DIR}/cmake\" NO_CMAKE_FIND_ROOT_PATH")
			set(__PATHS "NO_CMAKE_FIND_ROOT_PATH")
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
		if(NOT TARGET ${__INSTANCE_NAME} AND NOT __NO_TARGETS)
			message(FATAL_ERROR "${__EXTERNAL_BARE_NAME} did not produce an exported target ${__INSTANCE_NAME}" )
		endif()
	endif()
endfunction()

#Macro that generates a local project as the external dependency in the SUPERBUILD phase
#that depends on all external dependencies.
#
#It must be macro, because it has to enable languages, if enabled by any of the targets.
macro(finalizer)
	_get_target_behavior(__TARGET_BEHAVIOR)
	if("${__TARGET_BEHAVIOR}" STREQUAL "DEFINING_TARGETS")
		message(WARNING "finalizer called second time. This function is meant to be called only once at the very end of the root CMakeLists. Ignoring this call.")
		return()
	endif()
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
	_resolve_features()
	#Now we can assume that all features in all featuresets agree with the features in instances, which means that we can concatenate features to the target parameters (modifiers)
	_get_all_languages(__LANGUAGES)
	if(__LANGUAGES)
		foreach(__LANGUAGE IN LISTS __LANGUAGES)
			enable_language(${__LANGUAGE})
		endforeach()
	endif()
	#Now we need to instantiate all the targets. 
	_get_all_instance_ids(__INSTANCE_ID_LIST)
#	message(STATUS "finalizer: __INSTANCE_ID_LIST: ${__INSTANCE_ID_LIST}")
	if(__INSTANCE_ID_LIST)
		_add_languages(__INSTANCE_ID_LIST)
		foreach(__DEP_ID IN LISTS __INSTANCE_ID_LIST)
#			message(STATUS "finalizer(): Going to instantiate ${__DEP_ID}")
			_instantiate_target(${__DEP_ID})
		endforeach()
		if(NOT __NOT_SUPERBUILD)
			get_property(__EXTERNAL_DEPENDENCIES GLOBAL PROPERTY __BURAK_EXTERNAL_DEPENDENCIES)
			if(__EXTERNAL_DEPENDENCIES)
				set(__EXT_DEP_STR "DEPENDS")
				foreach(__EXT_DEP IN LISTS __EXTERNAL_DEPENDENCIES)
					string(REPLACE "::" "_" __EXT_DEP_FIXED ${__EXT_DEP})
					set(__EXT_DEP_STR ${__EXT_DEP_STR} ${__EXT_DEP_FIXED})
				endforeach()
			endif()
			message(STATUS "End of SUPERBUILD phase. External projects: ${__EXT_DEP_STR} CMAKE_PROJECT_NAME: ${CMAKE_PROJECT_NAME}")
			set(__EXT_DEP_STR ${__EXT_DEP_STR})
#			message(STATUS "finalizer(): ExternalProject_Add(${CMAKE_PROJECT_NAME} PREFIX ${CMAKE_SOURCE_DIR} SOURCE_DIR ${CMAKE_SOURCE_DIR} TMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/tmp STAMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/stamps DOWNLOAD_DIR \"${CMAKE_CURRENT_BINARY_DIR}\" INSTALL_COMMAND \"\" BUILD_ALWAYS ON BINARY_DIR \"${CMAKE_CURRENT_BINARY_DIR}/project\" ${__EXT_DEP_STR} CMAKE_ARGS -D__NOT_SUPERBUILD=ON)")
			ExternalProject_Add(${CMAKE_PROJECT_NAME}
				${__EXT_DEP_STR}
				PREFIX ${CMAKE_SOURCE_DIR}
				SOURCE_DIR ${CMAKE_SOURCE_DIR}
				TMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/tmp
				STAMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/stamps
				DOWNLOAD_DIR "${CMAKE_CURRENT_BINARY_DIR}"
				INSTALL_COMMAND ""
				BUILD_ALWAYS ON
				BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/project"
				CMAKE_ARGS -D__NOT_SUPERBUILD=ON
			)
		endif()
	else()
		message(WARNING "No targets declared")
	endif()
endmacro()

function(_resolve_features)
	#First we need to make sure all instances that connect to the same featurebase agree in their feature lists
	get_property(__ALL_FEATUREBASES GLOBAL PROPERTY __BURAK_ALL_FEATUREBASES)
	while(__ALL_FEATUREBASES)
		list(GET __ALL_FEATUREBASES 0 __FEATUREBASE_ID)
		_retrieve_featurebase_data(${__FEATUREBASE_ID} F_INSTANCES __FEATURE_INSTANCES)
		list(LENGTH __FEATURE_INSTANCES __INSTANCES_COUNT)
		if(${__INSTANCES_COUNT} EQUAL 0)
			message(FATAL_ERROR "Internal beetroot error: no instances in the featurebase __INSTANCES_COUNT")
		endif()
#		if(${__INSTANCES_COUNT} EQUAL 1)
#			#Only one featurebase - there is little to do. 
#			_remove_property_from_db(BURAK ALL FEATUREBASES ${__FEATUREBASE_ID} )
#			continue()
#		endif()
		_retrieve_featurebase_args(${__FEATUREBASE_ID} F_FEATURES __BASE_ARGS)
		_calculate_hash(__BASE_ARGS "${__BASE_ARGS__LIST}" "" __BASE_HASH)
		foreach(__INSTANCE_ID IN LISTS __FEATURE_INSTANCES)
			#We must make sure, that all features agree with the features declared in the featureabase
			_retrieve_instance_data(${__INSTANCE_ID} I_FEATURES __I_ARGS)
			_calculate_hash(__I_ARGS "${__I_ARGS__LIST}" "" __I_HASH)
			if(NOT "${__I_HASH}" STREQUAL "${__BASE_HASH}")
				_serialize_variables(__BASE_ARGS "${__BASE_ARGS__LIST}" __SERIALIZED_BASE_ARGS)
				_serialize_variables(__I_ARGS "${__I_ARGS__LIST}" __SERIALIZED_I_ARGS)

				message(FATAL_ERROR "Internal Beetroot error: features in the instance ${__INSTANCE_ID} (${__SERIALIZED_I_ARGS} with hash ${__I_HASH}) does not agree with features in the featurebase (${__SERIALIZED_BASE_ARGS} with hash ${__BASE_HASH})")
			endif()
		endforeach()
		_remove_property_from_db(BURAK ALL FEATUREBASES ${__FEATUREBASE_ID} )
		get_property(__ALL_FEATUREBASES GLOBAL PROPERTY __BURAK_ALL_FEATUREBASES)
	endwhile()
endfunction()

macro(finalize)
	finalizer()
endmacro()

macro(_get_all_languages __OUT_LANGUAGES) 
	_gather_languages()
	get_property("${__OUT_LANGUAGES}" GLOBAL PROPERTY __BURAK_ALL_INSTANCES)
endmacro()

function(_gather_languages )
	_get_all_instance_ids(__INSTANCE_ID_LIST)
	foreach(__INSANCE_ID IN LISTS __INSTANCE_ID_LIST)
		_gather_language_rec(${__INSANCE_ID})
	endforeach()
endfunction()

function(_gather_language_rec __INSTANCE_ID)
	_retrieve_instance_data(${__INSTANCE_ID} LANGUAGES __LANGUAGES)
	if(__LANGUAGES)
		_retrieve_instance_data(${__INSTANCE_ID} F_PATH __PATH)
		_make_path_hash("${__PATH}" __KEY)
		_add_property_to_db(BURAK ALL LANGUAGES "${__LANGUAGES}")
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __DEP_IDS)
	if(__DEP_IDS)
		foreach(__DEP_ID IN LISTS __DEP_IDS)
			_gather_language_rec(${__DEP_ID})
		endforeach()
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


