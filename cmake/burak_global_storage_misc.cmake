#     Global variables:
#
#
# __BURAK_STACK_TOP - Integer. The depth of the dependency searching during "discovering dependencies" phase.
# __BURAK_STACK_<integer> - List of INSTANCE_ID. It is a list of all dependencies discovered during the dependency call. Used in the "discovering dependencies" phase
# 
# __BURAK_GET_TARGET_BEHAVIOR - One of the <DEFINING_TARGETS, OUTSIDE_DEFINING_TARGETS>, used to indicate the behavior of the user-facing beetroot functions, in particular get_targets()
#                               Together with the stack depth (used when OUTSIDE_DEFINING_TARGETS) it allows to query the behavior using _get_target_behavior().
#
# __


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

macro(_get_stack_depth __OUT_DEPTH)
	get_property(${__OUT_DEPTH} GLOBAL PROPERTY __BURAK_STACK_TOP)
endmacro()

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


