#The function that expects that the target described by the target properties already exists, and it simply brings it.
#It will never define a new target.
function(get_existing_target __TEMPLATE_NAME __OUT_INSTANCE_NAME)
	_get_target_behavior(__GET_TARGET_BEHAVIOR)
	set(__CALLING_FILE "${CMAKE_PARENT_LIST_FILE}")
	file(RELATIVE_PATH __CALLING_FILE ${SUPERBUILD_ROOT} ${__CALLING_FILE})
	
#	message(STATUS "Called get_target(${__TEMPLATE_NAME}) on phase ${__GET_TARGET_BEHAVIOR}")
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "INSIDE_GENERATE_TARGETS")
		message(FATAL_ERROR "Calling get_existing_target from inside generate_targets is disallowed. To call dependency use declare_dependencies() (in which you cannot define targets).")
	endif()
	if(NOT __TEMPLATE_NAME)
		message(FATAL_ERROR "get_error was called without any arguments")
	endif()
	_parse_TARGETS_PATH("${__TEMPLATE_NAME}" ${ARGN})
	
	_get_variables("${__TARGETS_CMAKE_PATH}" "${__CALLING_FILE}" "" __VARIABLE_DIC __PARAMETERS_DIC __TEMPLATES __EXTERNAL_PROJECT_INFO __IS_TARGET_FIXED __TEMPLATE_OPTIONS ${__ARGS})
	
	_make_instance_id(${__TEMPLATE_NAME} __VARIABLE_DIC "" __INSTANCE_ID __HASH_SOURCE) 
#	message(STATUS "get_target: __TEMPLATE_NAME ${__TEMPLATE_NAME} got __INSTANCE_ID: ${__INSTANCE_ID}")
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "GATHERING_DEPENDENCIES" OR "${__GET_TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
		#Add dependencies together with their arguments to the list. They will be instatiated later on, during generate_targets run
		_put_dependencies_into_stack("${__INSTANCE_ID}")
		_get_parent_dependency_from_stack(__PARENT_INSTANCE_ID)
		_store_instance_link_data(
			 ${__INSTANCE_ID}
			"${__PARENT_INSTANCE_ID}"
			__VARIABLE_DIC 
			__PARAMETERS_DIC
			 ${__TEMPLATE_NAME} 
			 ${__TARGETS_CMAKE_PATH} 
			 ${__IS_TARGET_FIXED}
			"${__EXTERNAL_PROJECT_INFO}"
			 0
			"${__TEMPLATE_OPTIONS}"
			 )
		_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_HASH_SOURCE "${__HASH_SOURCE}")
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

function(build_target __TEMPLATE_NAME)
	get_target(${__TEMPLATE_NAME} __TMP_INSTANCE_NAME ${ARGN})
endfunction()

function(get_target __TEMPLATE_NAME __OUT_INSTANCE_NAME) 
	_get_target_behavior(__GET_TARGET_BEHAVIOR)
	set(__CALLING_FILE "${CMAKE_PARENT_LIST_FILE}")
	file(RELATIVE_PATH __CALLING_FILE ${SUPERBUILD_ROOT} ${__CALLING_FILE})
#	message(STATUS "Called get_target(${__TEMPLATE_NAME}) on phase ${__GET_TARGET_BEHAVIOR}")
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "INSIDE_GENERATE_TARGETS")
		message(FATAL_ERROR "Calling get_target from inside generate_targets is disallowed. To call dependency use declare_dependencies() (in which you cannot define targets).")
	endif()
	if(NOT __TEMPLATE_NAME)
		message(FATAL_ERROR "get_error was called without any arguments")
	endif()
	_parse_TARGETS_PATH("${__TEMPLATE_NAME}" ${ARGN})
#	message(STATUS "get_target(): ARGN: ${ARGN}")
	_get_variables("${__TARGETS_CMAKE_PATH}" "${__CALLING_FILE}" "" __VARIABLE_DIC __PARAMETERS_DIC __TEMPLATES __EXTERNAL_PROJECT_INFO __IS_TARGET_FIXED __TEMPLATE_OPTIONS ${__ARGS})
	if(__TEMPLATE_OPTIONS)
		message(STATUS "get_target(): __TEMPLATE_OPTIONS: ${__TEMPLATE_OPTIONS}")
	endif()
	if("${__VARIABLE_DIC_VERSION}" STREQUAL "KUC")
		message(FATAL_ERROR "__VARIABLE_DIC_VERSION: ${__VARIABLE_DIC_VERSION}")
	endif()
	_make_instance_id(${__TEMPLATE_NAME} __VARIABLE_DIC "" __INSTANCE_ID __HASH_SOURCE)
#	message(STATUS "get_target: __TEMPLATE_NAME ${__TEMPLATE_NAME} got __INSTANCE_ID: ${__INSTANCE_ID}")
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "GATHERING_DEPENDENCIES" OR "${__GET_TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
		#Add dependencies together with their arguments to the list. They will be instatiated later on, during generate_targets run
		_discover_dependencies(${__INSTANCE_ID} ${__TEMPLATE_NAME} "${__TARGETS_CMAKE_PATH}" __VARIABLE_DIC __PARAMETERS_DIC "${__EXTERNAL_PROJECT_INFO}" ${__IS_TARGET_FIXED} "${__TEMPLATE_OPTIONS}" "${__HASH_SOURCE}")
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

