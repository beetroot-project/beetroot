#     Global variables:
#
#
# __BURAK_STACK_TOP - Integer. The depth of the dependency searching during "discovering dependencies" phase.
# __BURAK_STACK_<integer> - List of INSTANCE_ID. It is a list of all dependencies discovered during the dependency call. Used in the "discovering dependencies" phase
# 
# __BURAK_GET_TARGET_BEHAVIOR - One of the <DEFINING_TARGETS, OUTSIDE_DEFINING_TARGETS>, used to indicate the behavior of the user-facing beetroot functions, in particular get_targets()
#                               Together with the stack depth (used when OUTSIDE_DEFINING_TARGETS) it allows to query the behavior using _get_target_behavior().
#
# __BURAK_INSIDE_TARGETS_FILE - TRUE or nothing. TRUE only inside reading targets.cmake. 
#
# __BURAK_TCRB_FOR_DEPENDENCIES - full name: TARGET_CMAKE_RECURRENCE_BREAKER_FOR_DEPENDENCIES. lists all FEATUREBASES included in the current dependency call stack.
# __BURAK_TCRB_FOR_PREPROCESS - full name: TARGET_CMAKE_RECURRENCE_BREAKER_FOR_PREPROCESS. lists all targets files included by using include_build_parameters_of() or similar functions when reading them.
# __BURAK_LOADED - true if the beetroot is loaded. It prevents reading in beetroot more than once (which is important, because beetroot overrides one built-in function)
# __BURAK_VARIABLES_NOT_ADDED - if set, it means that the include_parameters() did not properly included variables, probably because the target name depended on some variable itself.

function(_descend_dependencies_stack )
	get_property(__STACK_TOP GLOBAL PROPERTY __BURAK_STACK_TOP)
	math(EXPR __NEW_STACK_TOP "${__STACK_TOP} + 1")
	set_property(GLOBAL PROPERTY __BURAK_STACK_TOP "${__NEW_STACK_TOP}")
#	message(STATUS "_descend_dependencies_stack(): __NEW_STACK_TOP: ${__NEW_STACK_TOP}")
endfunction()

function(_ascend_dependencies_stack )
	get_property(__STACK_TOP GLOBAL PROPERTY __BURAK_STACK_TOP)
	set_property(GLOBAL  PROPERTY __BURAK_STACK_${__STACK_TOP} "")
	math(EXPR __NEW_STACK_TOP "${__STACK_TOP} - 1")
	set_property(GLOBAL PROPERTY __BURAK_STACK_TOP "${__NEW_STACK_TOP}")

	get_property(__OLD_STACK GLOBAL  PROPERTY __BURAK_STACK_${__STACK_TOP})
#	message(STATUS "_ascend_dependencies_stack(): Removing old stack top: __BURAK_STACK_${__STACK_TOP}: ${__OLD_STACK} __NEW_STACK_TOP: ${__NEW_STACK_TOP}")
endfunction()

macro(_get_stack_depth __OUT_DEPTH)
	get_property(${__OUT_DEPTH} GLOBAL PROPERTY __BURAK_STACK_TOP)
endmacro()

function(_put_dependencies_into_stack __DEPENDENCY_LIST)
	get_property(__STACK_TOP GLOBAL PROPERTY __BURAK_STACK_TOP)
	set_property(GLOBAL APPEND  PROPERTY __BURAK_STACK_${__STACK_TOP} ${__DEPENDENCY_LIST})
#	message(STATUS "_put_dependencies_into_stack: put __DEPENDENCY_LIST: ${__DEPENDENCY_LIST} into __BURAK_STACK_${__STACK_TOP}")
endfunction()

function(_get_parent_dependency_from_stack __OUT_PARENT)
	get_property(__STACK_TOP GLOBAL PROPERTY __BURAK_STACK_TOP)
#	message(STATUS "_get_parent_dependency_from_stack(): __STACK_TOP: ${__STACK_TOP}")
	if(${__STACK_TOP} GREATER 0)
		math(EXPR __NEW_STACK_TOP "${__STACK_TOP} - 1")
		get_property(__TMP_LIST GLOBAL PROPERTY __BURAK_STACK_${__NEW_STACK_TOP})
		if(NOT __TMP_LIST)
			message(FATAL_ERROR "Internal beetroot error: empty parent on stack at pos __BURAK_STACK_${__NEW_STACK_TOP}")
		endif()
#		message(STATUS "_get_parent_dependency_from_stack(): __TMP_LIST: ${__TMP_LIST}")
		list(LENGTH __TMP_LIST __TMP_LENGTH)
#		message(STATUS "_get_parent_dependency_from_stack(): __TMP_LENGTH: ${__TMP_LENGTH}")
		math(EXPR __TMP_LENGTH "${__TMP_LENGTH} - 1")
		list(GET __TMP_LIST ${__TMP_LENGTH} __TMP_LAST )
#		message(STATUS "_get_parent_dependency_from_stack(): __BURAK_STACK_${__NEW_STACK_TOP}: ${__TMP_LIST} dependency: ${__TMP_LAST}")
		set(${__OUT_PARENT} ${__TMP_LAST} PARENT_SCOPE)
	else()
		set(${__OUT_PARENT} "" PARENT_SCOPE)
	endif()
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

macro(_is_inside_targets_file __OUT_IS)
	get_property(${__OUT_IS} GLOBAL PROPERTY __BURAK_INSIDE_TARGETS_FILE)
endmacro()

function(_set_inside_targets_file)
	set_property(GLOBAL PROPERTY __BURAK_INSIDE_TARGETS_FILE 1)
endfunction()

function(_set_skip_targets_file)
	set_property(GLOBAL PROPERTY __BURAK_INSIDE_TARGETS_FILE 2)
endfunction()

macro(_clear_inside_targets_file)
	set_property(GLOBAL PROPERTY __BURAK_INSIDE_TARGETS_FILE 0)
endmacro()



#__STACK can be one of "DEPENDENCIES" or "PREPROCESS"
function(_can_descend_recursively __ID __STACK __OUT)
	set(__VALID_OPTS "DEPENDENCIES" "PREPROCESS" "DEBUG_PRINT_INSTANCE" "DEBUG_PRINT_FEATUREBASE")
	if(NOT ${__STACK} IN_LIST __VALID_OPTS)
		message(FATAL_ERROR "Internal beetroot error: unknown recursive stack: ${__STACK}")
	endif()
	get_property(__LIST GLOBAL PROPERTY __BURAK_TCRB_FOR_${__STACK})

		list(LENGTH __LIST __LASTNR)
#		message(STATUS "_can_descend_recursively(): descending position ${__LASTNR} __STACK: ${__STACK} __ID: ${__ID}")
		
	if( NOT "${__ID}" IN_LIST __LIST)
		set(${__OUT} 1 PARENT_SCOPE)
		set_property(GLOBAL APPEND PROPERTY __BURAK_TCRB_FOR_${__STACK} "${__ID}")
	else()
		set(${__OUT} 0 PARENT_SCOPE)
	endif()
endfunction()

function(_ascend_from_recurency __ID __STACK)
	set(__VALID_OPTS "DEPENDENCIES" "PREPROCESS" "DEBUG_PRINT_INSTANCE" "DEBUG_PRINT_FEATUREBASE")
	if(NOT ${__STACK} IN_LIST __VALID_OPTS)
		message(FATAL_ERROR "Internal beetroot error: unknown recursive stack: ${__STACK}")
	endif()
	get_property(__LIST GLOBAL PROPERTY __BURAK_TCRB_FOR_${__STACK})
	list(LENGTH __LIST __LASTNR)
	math(EXPR __LASTNR "${__LASTNR}-1")
	list(GET __LIST ${__LASTNR} __LAST_ITEM)
	if( "${__ID}" STREQUAL "${__LAST_ITEM}")
		list(REMOVE_AT __LIST ${__LASTNR})
#		message(STATUS "_ascend_from_recurency(): OK position in stack: ${__LAST_ITEM} __ID: ${__ID}")
		set_property(GLOBAL PROPERTY __BURAK_TCRB_FOR_${__STACK} ${__LIST})
	else()
		message(FATAL_ERROR "Unexpected out-of-order return from recurency stack ${__STACK} with ID ${__ID}. Expected ${__LAST_ITEM}")
	endif()
endfunction()

function(_get_recurency_list __STACK __OUT)
	get_property(__LIST GLOBAL PROPERTY __BURAK_TCRB_FOR_${__STACK})
#	message(STATUS "_get_recurency_list(): __LIST: ${__LIST}")
	set(${__OUT} "${__LIST}" PARENT_SCOPE)
endfunction()

set_property(GLOBAL PROPERTY __BURAK_TCRB_FOR_DEPENDENCIES "")
set_property(GLOBAL PROPERTY __BURAK_TCRB_FOR_PREPROCESS "")
_clear_inside_targets_file()


