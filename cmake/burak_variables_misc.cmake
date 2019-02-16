

# Function injects variables from __ARG_IN into the calling scope, so the variables are ready to be used by user-supplied function 
# generate_targets() or declare_dependencies()
function(_instantiate_variables __ARGS __PARS __ARGS_LIST)
	if(NOT __ARGS_LIST)
		return()
		message(FATAL_ERROR "No variables to instantiate")
	endif()
	foreach(__VAR IN LISTS __ARGS_LIST)
		if(__PARS)
			if(NOT ${__PARS}_${__VAR}__CONTAINER)
				message(FATAL_ERROR "Internal beetroot error: Unknown container: ${__PARS}_${__VAR}__CONTAINER is empty")
			endif()
			if("${${__PARS}_${__VAR}__CONTAINER}" STREQUAL "OPTION")
				if(${__ARGS}_${__VAR})
					set(${__VAR} "1" PARENT_SCOPE)
				else()
					set(${__VAR} "0" PARENT_SCOPE)
				endif()
			else()
				set(${__VAR} "${${__ARGS}_${__VAR}}" PARENT_SCOPE)
			endif()
		else()
			set(${__VAR} "${${__ARGS}_${__VAR}}" PARENT_SCOPE)
		endif()
	endforeach()
endfunction()

function(_make_cmake_args __PARS __ARGS __ARGS_LIST __OUT_CMAKE_ARGS)
#	message(STATUS "_make_cmake_args(): __PARS: ${__PARS} __ARGS: ${__ARGS} __ARGS_LIST: ${__ARGS_LIST}")
	set(__CMAKE_ARGS)
	foreach(__VAR IN LISTS __ARGS_LIST)
#		message(STATUS "_make_cmake_args(): processing ${__ARGS}_${__VAR}. Container ${__PARS}_${__VAR}__CONTAINER: ${${__PARS}_${__VAR}__CONTAINER}") # Container ${__PARS}_${__VAR}_CONTAINER: ${${__PARS}_${__VAR}_CONTAINER}, ${__PARS}_${__VAR}_TYPE: ${{__PARS}_${__VAR}_TYPE}
		if("${${__PARS}_${__VAR}__CONTAINER}" STREQUAL "OPTION" )	
			if(${__ARGS}_${__VAR})
				list(APPEND __CMAKE_ARGS "-D${__VAR}:BOOL=ON")
			else()
				list(APPEND __CMAKE_ARGS "-D${__VAR}:BOOL=OFF")
			endif()
		elseif("${${__PARS}_${__VAR}__TYPE}" STREQUAL "INTEGER")
			list(APPEND __CMAKE_ARGS "-D${__VAR}:STRING=${${__ARGS}_${__VAR}}")
		elseif("${${__PARS}_${__VAR}__TYPE}" STREQUAL "BOOL")
			list(APPEND __CMAKE_ARGS "-D${__VAR}:BOOL=${${__ARGS}_${__VAR}}")
		else()
			message(FATAL_ERROR "Unknown way to pass an argument ${__VAR} into the cmake, because it is ${${__PARS}_${__VAR}__CONTAINER} of type ${${__PARS}_${__VAR}__TYPE}")
		endif()
	endforeach()
#	message(STATUS "_make_cmake_args(): finished processing. ${__OUT_CMAKE_ARGS}: ${__CMAKE_ARGS}") 
	set(${__OUT_CMAKE_ARGS} "${__CMAKE_ARGS}" PARENT_SCOPE)
endfunction()


function(_single_feature_relation __FILE_HASH __VARNAME __PARS_PREFIX __ARG1_PREFIX __ARG2_PREFIX __OUT_RELATION)
#	message(STATUS "_single_feature_relation(): __FILE_HASH: ${__FILE_HASH} __VARNAME: ${__VARNAME} __PARS_PREFIX: ${__PARS_PREFIX} __ARG1_PREFIX: ${__ARG1_PREFIX} __ARG2_PREFIX: ${__ARG2_PREFIX}")
#	message(STATUS "_single_feature_relation(): __FILE_HASH: ${__FILE_HASH} ${__ARG1_PREFIX}_${__VARNAME}: ${${__ARG1_PREFIX}_${__VARNAME}} ${__ARG2_PREFIX}_${__VARNAME}: ${${__ARG2_PREFIX}_${__VARNAME}}")
	if("${${__PARS_PREFIX}_${__VARNAME}__CONTAINER}" STREQUAL "OPTION")
		if(${__ARG1_PREFIX}_${__VARNAME})
			if(${__ARG2_PREFIX}_${__VARNAME})
				set(${__OUT_RELATION} 0 PARENT_SCOPE)
			else()
				set(${__OUT_RELATION} 1 PARENT_SCOPE)
			endif()
		else()
			if(${__ARG2_PREFIX}_${__VARNAME})
				set(${__OUT_RELATION} 2 PARENT_SCOPE)
			else()
				set(${__OUT_RELATION} 0 PARENT_SCOPE)
			endif()
		endif()
	elseif("${${__PARS_PREFIX}_${__VARNAME}__CONTAINER}" STREQUAL "SCALAR")
		_retrieve_file_args("${__FILE_HASH}" DEFAULTS __ARG_DEFAULTS)
		if("${${__ARG1_PREFIX}_${__VARNAME}}" STREQUAL "${${__ARG2_PREFIX}_${__VARNAME}}")
			set(${__OUT_RELATION} 0 PARENT_SCOPE)
		else()
			if("${${__PARS_PREFIX}_${__VARNAME}__TYPE}" STREQUAL "INTEGER")
				if("${${__ARG1_PREFIX}_${__VARNAME}}" GREATER "${${__ARG2_PREFIX}_${__VARNAME}}")
					set(${__OUT_RELATION} 1 PARENT_SCOPE)
				else()
					set(${__OUT_RELATION} 2 PARENT_SCOPE)
				endif()
			elseif("${${__PARS_PREFIX}_${__VARNAME}__TYPE}" STREQUAL "BOOL" OR 
				"${${__PARS_PREFIX}_${__VARNAME}__TYPE}" STREQUAL "STRING" OR
				"${${__PARS_PREFIX}_${__VARNAME}__TYPE}" STREQUAL "PATH" OR
				"${${__PARS_PREFIX}_${__VARNAME}__TYPE}" MATCHES "^CHOICE.*")
				if("${__ARG_DEFAULTS_${__VARNAME}}" STREQUAL "${${__ARG1_PREFIX}_${__VARNAME}}" )
					if("${__ARG_DEFAULTS_${__VARNAME}}" STREQUAL "${${__ARG2_PREFIX}_${__VARNAME}}" )
						message(FATAL_ERROR "Internal beetroot error: this code path should be dead")
					else()
						set(${__OUT_RELATION} 2 PARENT_SCOPE)
					endif()
				else()
					if("${__ARG_DEFAULTS_${__VARNAME}}" STREQUAL "${${__ARG2_PREFIX}_${__VARNAME}}" )
						set(${__OUT_RELATION} 1 PARENT_SCOPE)
					else()
						message(STATUS "_single_feature_relation(): No way to unite ${__ARG1_PREFIX}_${__VARNAME}: ${${__ARG1_PREFIX}_${__VARNAME}}  and ${__ARG2_PREFIX}_${__VARNAME}: ${${__ARG2_PREFIX}_${__VARNAME}} because both are non-default and different (__ARG_DEFAULTS_${__VARNAME}: ${__ARG_DEFAULTS_${__VARNAME}})")
						set(${__OUT_RELATION} 4 PARENT_SCOPE)
					endif()
				endif()
			else()
				message(FATAL_ERROR "Internal beetroot error: Unknown variable type: ${__PARS_PREFIX}_${__VARNAME}__TYPE: ${${__PARS_PREFIX}_${__VARNAME}__TYPE}")
			endif()
		endif()
	elseif("${${__PARS_PREFIX}_${__VARNAME}__CONTAINER}" STREQUAL "VECTOR")
		list_diff(__DIFF12 ${__ARG1_PREFIX}_${__VARNAME} ${__ARG2_PREFIX}_${__VARNAME})
		list_diff(__DIFF21 ${__ARG2_PREFIX}_${__VARNAME} ${__ARG1_PREFIX}_${__VARNAME})
#		message(STATUS "_single_feature_relation(): __DIFF12: ${__DIFF12} __DIFF21: ${__DIFF21}")
		if(__DIFF12)
			if(__DIFF21)
				set(${__OUT_RELATION} 3 PARENT_SCOPE)
			else()
				set(${__OUT_RELATION} 1 PARENT_SCOPE)
			endif()
		else()
			if(__DIFF21)
				set(${__OUT_RELATION} 2 PARENT_SCOPE)
			else()
				set(${__OUT_RELATION} 0 PARENT_SCOPE)
			endif()
		endif()
	else()
		message(FATAL_ERROR "Internal beetroot error: unsupported container ${__PARS_PREFIX}_${__VARNAME}__CONTAINER: ${${__PARS_PREFIX}_${__VARNAME}__CONTAINER}")
	endif()
endfunction()

function(_compare_featuresets __FILE_HASH __PARS_PREFIX __ARG1_PREFIX __ARG2_PREFIX __OUT_RELATION)
	list_union(__VARS ${__ARG1_PREFIX}__LIST ${__ARG2_PREFIX}__LIST)
#	message(STATUS "_compare_featuresets(): __VARS: ${__VARS} __PARS_PREFIX: ${__PARS_PREFIX}")
	_make_promoted_featureset(${__FILE_HASH} "${__VARS}" ${__PARS_PREFIX} ${__ARG1_PREFIX} ${__ARG2_PREFIX} __TMP __COMP)
	set(${__OUT_RELATION} ${__COMP} PARENT_SCOPE)
endfunction()


#Function compiles a set of smallest features that are greater or equal to features in __ARG1_PREFIX and __ARG2_PREFIX. 
#It also returns __OUT_RELATION that inform what is the direction of the changes.
#If __OUT_RELATION==3 it means that there is no way to promote both featuresets to the common denominator, 
#  and __OUT_ARGS__LIST points to the list of the conflict variables.
function(_make_promoted_featureset __FILE_HASH __VARNAMES __PARS_PREFIX __ARG1_PREFIX __ARG2_PREFIX __OUT_ARGS __OUT_RELATION)
	set(__RESULT_RELATION 0)
	set(__CONFLICTS)
	set(__COMMON__LIST)
#	message(STATUS "_make_promoted_featureset(): __VARNAMES: ${__VARNAMES}")
	foreach(__VARNAME IN LISTS __VARNAMES)
		list(APPEND __COMMON__LIST ${__VARNAME})
		_single_feature_relation(${__FILE_HASH} ${__VARNAME} ${__PARS_PREFIX} ${__ARG1_PREFIX} ${__ARG2_PREFIX} __SINGLE_RELATION)
#		message(STATUS "_make_promoted_featureset(): __VARNAME: ${__VARNAME}, ${__ARG1_PREFIX}: ${${__ARG1_PREFIX}_${__VARNAME}} vs ${__ARG2_PREFIX}: ${${__ARG2_PREFIX}_${__VARNAME}} __SINGLE_RELATION: ${__SINGLE_RELATION}")
		if("${__SINGLE_RELATION}" STREQUAL "0")
			set(__COMMON_${__VARNAME} "${${__ARG1_PREFIX}_${__VARNAME}}")
		elseif("${__SINGLE_RELATION}" STREQUAL "1")
			set(__COMMON_${__VARNAME} "${${__ARG1_PREFIX}_${__VARNAME}}")
			list(APPEND __LEFTS ${__VARNAME})
			if("${__RESULT_RELATION}" STREQUAL "2" OR "${__RESULT_RELATION}" STREQUAL "3")
				set(__RESULT_RELATION 3)
			elseif("${__RESULT_RELATION}" STREQUAL "0" OR "${__RESULT_RELATION}" STREQUAL "1")
				set(__RESULT_RELATION 1)
			elseif("${__RESULT_RELATION}" STREQUAL "4")
				#do nothing
			else()
				message(FATAL_ERROR "Internal beetroot error: dead code")
			endif()
		elseif("${__SINGLE_RELATION}" STREQUAL "2")
			set(__COMMON_${__VARNAME} "${${__ARG2_PREFIX}_${__VARNAME}}")
			list(APPEND __RIGHTS ${__VARNAME})
			if("${__RESULT_RELATION}" STREQUAL "1" OR "${__RESULT_RELATION}" STREQUAL "3")
				set(__RESULT_RELATION 3)
			elseif("${__RESULT_RELATION}" STREQUAL "0" OR "${__RESULT_RELATION}" STREQUAL "2")
				set(__RESULT_RELATION 2)
			elseif("${__RESULT_RELATION}" STREQUAL "4")
				#do nothing
			else()
				message(FATAL_ERROR "Internal beetroot error: dead code")
			endif()
		elseif("${__SINGLE_RELATION}" STREQUAL "3")
			list_union(__COMMON_${__VARNAME} ${__ARG2_PREFIX}_${__VARNAME} ${__ARG1_PREFIX}_${__VARNAME})
			list(APPEND __RIGHTS ${__VARNAME})
			list(APPEND __LEFTS ${__VARNAME})
			if("${__RESULT_RELATION}" STREQUAL "0" OR "${__RESULT_RELATION}" STREQUAL "1" OR "${__RESULT_RELATION}" STREQUAL "2" OR "${__RESULT_RELATION}" STREQUAL "3")
				set(__RESULT_RELATION 3)
			elseif("${__RESULT_RELATION}" STREQUAL "4")
				#do nothing
			else()
				message(FATAL_ERROR "Internal beetroot error: dead code")
			endif()
		elseif("${__SINGLE_RELATION}" STREQUAL "4")
			list(APPEND __CONFLICTS ${__VARNAME})
			set(__RESULT_RELATION 4)
		else()
			message(FATAL_ERROR "Internal beetroot error: dead branch. This statement should not have executed.")
		endif()
	endforeach()
	set(${__OUT_RELATION} "${__RESULT_RELATION}" PARENT_SCOPE)
	if("${__RESULT_RELATION}" STREQUAL "4")
		set(${__OUT_ARGS}__LIST "${__CONFLICTS}" PARENT_SCOPE)
	else()
		_pass_arguments_higher(__COMMON ${__OUT_ARGS})
	endif()
endfunction()


macro(_pass_arguments_higher __IN_PREFIX __OUT_PREFIX)
#	message(FATAL_ERROR "${__IN_PREFIX}__LIST: ${${__IN_PREFIX}__LIST}")
	foreach(__VAR IN LISTS ${__IN_PREFIX}__LIST)
#		message(FATAL_ERROR "set(${__OUT_PREFIX}_${__VAR} \"${${__IN_PREFIX}_${__VAR}}\" PARENT_SCOPE)")
		set(${__OUT_PREFIX}_${__VAR} "${${__IN_PREFIX}_${__VAR}}" PARENT_SCOPE)
		if(NOT "${${__IN_PREFIX}__SRC_${__VAR}}" STREQUAL "")
			set(${__OUT_PREFIX}__SRC_${__VAR} "${${__IN_PREFIX}__SRC_${__VAR}}" PARENT_SCOPE)
		endif()
	endforeach()
	set(${__OUT_PREFIX}__LIST "${${__IN_PREFIX}__LIST}" PARENT_SCOPE)
endmacro()

macro(_pass_parameters_higher __IN_PREFIX __OUT_PREFIX)
	foreach(__VAR IN LISTS ${__IN_PREFIX}__LIST)
		set(${__OUT_PREFIX}_${__VAR}__CONTAINER "${${__IN_PREFIX}_${__VAR}__CONTAINER}" PARENT_SCOPE)
		set(${__OUT_PREFIX}_${__VAR}__TYPE "${${__IN_PREFIX}_${__VAR}__TYPE}" PARENT_SCOPE)
	endforeach()
	set(${__OUT_PREFIX}__LIST "${${__IN_PREFIX}__LIST}" PARENT_SCOPE)
	set(${__OUT_PREFIX}__LIST_MODIFIERS "${${__IN_PREFIX}__LIST_MODIFIERS}" PARENT_SCOPE)
	set(${__OUT_PREFIX}__LIST_FEATURES "${${__IN_PREFIX}__LIST_FEATURES}" PARENT_SCOPE)
	set(${__OUT_PREFIX}__LIST_LINKPARS "${${__IN_PREFIX}__LIST_LINKPARS}" PARENT_SCOPE)
endmacro()

