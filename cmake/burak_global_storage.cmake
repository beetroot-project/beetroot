function(_descend_dependencies_stack )
	get_property(__STACK_TOP GLOBAL PROPERTY __BURAK_STACK_TOP)
	math(EXPR __NEW_STACK_TOP "${__STACK_TOP} + 1")
	set_property(GLOBAL PROPERTY __BURAK_STACK_TOP "${__NEW_STACK_TOP}")
endfunction()

function(_ascend_dependencies_stack )
	get_property(__STACK_TOP GLOBAL PROPERTY __BURAK_STACK_TOP)
	set_property(GLOBAL  PROPERTY __BURAK_STACK_${__STACK_TOP} "")
	math(EXPR __NEW_STACK_TOP "${__STACK_TOP} - 1")
	set_property(GLOBAL PROPERTY __BURAK_STACK_TOP "${__NEW_STACK_TOP}")
endfunction()

function(_put_dependencies_into_stack __DEPENDENCY_LIST)
	get_property(__STACK_TOP GLOBAL PROPERTY __BURAK_STACK_TOP)
	set_property(GLOBAL APPEND  PROPERTY __BURAK_STACK_${__STACK_TOP} ${__DEPENDENCY_LIST})
#	message(STATUS "Put dependency ${__DEPENDENCY_LIST} into __BURAK_STACK_${__STACK_TOP}")
endfunction()

function(_get_dependencies_from_stack __OUT_DEPENDENCY_LIST)
	get_property(__STACK_TOP GLOBAL PROPERTY __BURAK_STACK_TOP)
	get_property(${__OUT_DEPENDENCY_LIST} GLOBAL PROPERTY __BURAK_STACK_${__STACK_TOP})
#	message(STATUS "Get dependency ${${__OUT_DEPENDENCY_LIST}} from __BURAK_STACK_${__STACK_TOP}")
	set(${__OUT_DEPENDENCY_LIST} "${${__OUT_DEPENDENCY_LIST}}" PARENT_SCOPE)
endfunction()

function(_get_target_behavior __OUT_BEHAVIOR)
	get_property(__TARGET_BEHAVIOR GLOBAL PROPERTY __BURAK_GET_TARGET_BEHAVIOR)
	if("${__TARGET_BEHAVIOR}" STREQUAL "DEFINING_TARGETS")
		set(${__OUT_BEHAVIOR} "${__TARGET_BEHAVIOR}")
	elseif("${__TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_DEFINING_TARGETS")
		get_property(__STACK_TOP GLOBAL PROPERTY __BURAK_STACK_TOP)
		if("${__STACK_TOP}" STREQUAL "0")
			set(${__OUT_BEHAVIOR} "OUTSIDE_SCOPE")
		else()
			set(${__OUT_BEHAVIOR} "GATHERING_DEPENDENCIES")
		endif()
	else()
		message(FATAL_ERROR "Unknown target behavior: ${__TARGET_BEHAVIOR}")
	endif()
	set(${__OUT_BEHAVIOR} "${${__OUT_BEHAVIOR}}" PARENT_SCOPE)
#	message(STATUS "_get_target_behavior(): Current behaviour: ${${__OUT_BEHAVIOR}}")
endfunction()

function(_set_behavior_defining_targets)
	set_property(GLOBAL PROPERTY __BURAK_GET_TARGET_BEHAVIOR "DEFINING_TARGETS")
endfunction()

function(_set_behavior_outside_defining_targets)
	set_property(GLOBAL PROPERTY __BURAK_STACK_TOP "0")
	set_property(GLOBAL PROPERTY __BURAK_GET_TARGET_BEHAVIOR "OUTSIDE_DEFINING_TARGETS")
endfunction()

function(_store_instance_data __INSTANCE_ID __ARGS __PARS __ARGS_LIST_MODIFIERS __DEP_LIST __TEMPLATE_NAME __TARGETS_CMAKE_PATH __IS_TARGET_FIXED __EXTERNAL_PROJECT_INFO __TARGET_REQUIRED)
#	message(FATAL_ERROR "__ARGS_LIST_MODIFIERS: ${__ARGS_LIST_MODIFIERS}")
#	if("${__INSTANCE_ID}" STREQUAL "SerialboxStatic_18768807d4b4034c1c5d4dd0f5ba6964")
#		message(FATAL_ERROR "__EXTERNAL_PROJECT_INFO: ${__EXTERNAL_PROJECT_INFO}")
#	endif()
	_serialize_variables(${__ARGS} __SERIALIZED_VARIABLES)
	_serialize_parameters(${__PARS} __SERIALIZED_PARAMETERS)
	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_VARS 			"${__SERIALIZED_VARIABLES}")  #Serialized list of variables with their values
	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_PARS 			"${__SERIALIZED_PARAMETERS}") #Serialized list of definitions of variables (without their default values)
	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_MODIFIERS 		"${__ARGS_LIST_MODIFIERS}")   #Variable list that are defining the target name
	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_DEPS 			"${__DEP_LIST}")              #List of dependencies (INSTANCE_ID)
	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_TEMPLATE 		"${__TEMPLATE_NAME}")         #Base template name
	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_PATH 			"${__TARGETS_CMAKE_PATH}")    #Path to the file that defines this instance
	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_TARGET_FIXED 	"${__IS_TARGET_FIXED}")       #Boolean. True means that there is only on target name for this template
	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_EXTERNAL_INFO 	"${__EXTERNAL_PROJECT_INFO}") #Serialized external project info
	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_REQUIRED 		"${__TARGET_REQUIRED}")       #True means that we require this instance to generate a CMake target
	
	_append_instance_modifiers_hash(${__INSTANCE_ID} ${__TEMPLATE_NAME} ${__ARGS} "${__ARGS_LIST_MODIFIERS}")
#	_calculate_hash(${__ARGS} "${__ARGS_LIST_MODIFIERS}" "${__TEMPLATE_NAME}" __MODIFERS_HASH)
#	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_MODIFERS_HASH 	"${__MODIFERS_HASH}")        #Hash that defines the target name (INSTANCE_NAME)
#	
#	set_property(GLOBAL APPEND PROPERTY __BURAK_ALL_INSTANCES "${__INSTANCE_ID}")
endfunction()

#Storage allows for quick enumaration of number of distinct ARG_MODIFIERS hashes for each TEMPLATE_NAME,
#so the function that names the targets can easily decide on the best naming scheme.
#
#For each TEMPLATE_NAME there is a global list of modifier_hashes:
#__${TEMPLATE_NAME}_MODIFIER_HASHES
function(_append_instance_modifiers_hash __INSTANCE_ID __TEMPLATE_NAME __ARGS __ARGS_LIST_MODIFIERS)
	_calculate_hash("${__ARGS}" "${__ARGS_LIST_MODIFIERS}" "${__TEMPLATE_NAME}" __HASH_TEMPLATE_NAME)
	get_property(__MODIFIERS_HASHES GLOBAL PROPERTY __${__TEMPLATE_NAME}_MODIFIER_HASHES)
	if(__MODIFIERS_HASHES)
		if("${__HASH_TEMPLATE_NAME}" IN_LIST __MODIFIERS_HASHES)
			return()
		endif()
	endif()
	set_property(GLOBAL APPEND PROPERTY __${__TEMPLATE_NAME}_MODIFIER_HASHES "${__HASH_TEMPLATE_NAME}")
	set_property(GLOBAL APPEND PROPERTY __BURAK_ALL_INSTANCES "${__INSTANCE_ID}")
	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_MODIFIERS_HASH 	"${__HASH_TEMPLATE_NAME}")    #Hash that defines the target name (INSTANCE_NAME)
	get_property(__TMP GLOBAL PROPERTY __BURAK_ALL_INSTANCES)
#	message(STATUS "_append_instance_modifiers_hash(): Added ${__INSTANCE_ID} to all instances. Now the full list: ${__TMP}")
endfunction()

macro(_retrieve_instance_data __INSTANCE_ID __PROPERTY __OUT)
	get_property(${__OUT} GLOBAL PROPERTY	__${__INSTANCE_ID}_${__PROPERTY})
endmacro()

macro(_retrieve_instance_args __INSTANCE_ID __OUT)
	_retrieve_instance_data(${__INSTANCE_ID} VARS 			__TMP_SER_VARS)
	_unserialize_variables("${__TMP_SER_VARS}" ${__OUT})
endmacro()

macro(_retrieve_instance_pars __INSTANCE_ID __OUT)
	_retrieve_instance_data(${__INSTANCE_ID} PARS 			__TMP_SER_PARS)
	_unserialize_parameters("${__TMP_SER_PARS}" ${__OUT})
endmacro()

macro(_retrieve_all_instance_data __INSTANCE_ID 
 __OUT_ARGS __OUT_DEP_LIST __OUT_TEMPLATE_NAME __OUT_TARGETS_CMAKE_PATH __OUT_IS_TARGET_FIXED __OUT_EXTERNAL_PROJECT_INFO __OUT_TARGET_REQUIRED)
	_retrieve_instance_args(${__INSTANCE_ID} ${__OUT_ARGS})
	_retrieve_instance_data(${__INSTANCE_ID} DEPS 			${__OUT_DEP_LIST})
	_retrieve_instance_data(${__INSTANCE_ID} TEMPLATE 		${__OUT_TEMPLATE_NAME})
	_retrieve_instance_data(${__INSTANCE_ID} PATH 			${__OUT_TARGETS_CMAKE_PATH})
	_retrieve_instance_data(${__INSTANCE_ID} TARGET_FIXED 	${__OUT_IS_TARGET_FIXED})
	_retrieve_instance_data(${__INSTANCE_ID} EXTERNAL_INFO 	${__OUT_EXTERNAL_PROJECT_INFO})
	_retrieve_instance_data(${__INSTANCE_ID} REQUIRED 		${__OUT_TARGET_REQUIRED})
endmacro()

function(_store_instance_target __INSTANCE_ID __INSTANCE_NAME) 
#	message(STATUS "_store_instance_target(): Storing target name ${__INSTANCE_NAME}...")
	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_INSTANCE_NAME "${__INSTANCE_NAME}")
	set_property(GLOBAL APPEND PROPERTY __BURAK_ALL_TARGETS "${__INSTANCE_NAME}")
	get_property(__ALL_TARGETS GLOBAL PROPERTY __BURAK_ALL_TARGETS)
#	message(STATUS "...Current list of all immidiate targets: ${__ALL_TARGETS}")
endfunction()

macro(_get_all_instances __OUT_INSTANCE_NAME_LIST) 
	get_property("${__OUT_INSTANCE_NAME_LIST}" GLOBAL PROPERTY __BURAK_ALL_INSTANCES)
endmacro()

#macro(_get_instance_name __INSTANCE_ID __OUT_INSTANCE_NAME __OUT_TARGETS_CMAKE_PATH)
#	get_property(${__OUT_INSTANCE_NAME} GLOBAL PROPERTY __${__INSTANCE_ID}_INSTANCE_NAME)
#	get_property(${__OUT_TARGETS_CMAKE_PATH} GLOBAL PROPERTY __${__INSTANCE_ID}_PATH)
#endmacro()

#macro(_get_template_name __INSTANCE_ID __OUT_TEMPLATE_NAME)
#	get_property(${__OUT_TEMPLATE_NAME} GLOBAL PROPERTY __${__INSTANCE_ID}_TEMPLATE)
#endmacro()

function(_get_number_of_instance_modifier_hashes __TEMPLATE_NAME __OUT_HASH_COUNT)
	get_property(__MODIFIERS_HASHES GLOBAL PROPERTY __${__TEMPLATE_NAME}_MODIFIER_HASHES)
	list(LENGTH __MODIFIERS_HASHES __COUNT)
	set(${__OUT_HASH_COUNT} "${__COUNT}" PARENT_SCOPE)
endfunction()


