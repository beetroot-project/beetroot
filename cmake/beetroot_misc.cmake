
function(_invoke_apply_dependency_to_target __DEPENDEE_INSTANCE_ID __INSTANCE_ID __OUT_FUNCTION_EXISTS)
#	message(STATUS "_invoke_apply_dependency_to_target() __DEPENDEE_INSTANCE_ID: ${__DEPENDEE_INSTANCE_ID} __INSTANCE_ID: ${__INSTANCE_ID}")
	_retrieve_instance_data(${__INSTANCE_ID} PATH __TARGETS_CMAKE_PATH)
	_retrieve_instance_args(${__INSTANCE_ID} MODIFIERS __ARGS)

#	    _serialize_variables(__ARGS __ARGS__LIST __ARGS_SERIALIZED)
#	    message(STATUS "_invoke_apply_dependency_to_target() MODIFIERS list: ${__ARGS_SERIALIZED}")

	set(__TMP_LIST "${__ARGS__LIST}")
	_retrieve_instance_args(${__INSTANCE_ID} I_FEATURES __ARGS)
#	    _serialize_variables(__ARGS __ARGS__LIST __ARGS_SERIALIZED)
#	    message(STATUS "_invoke_apply_dependency_to_target() FEATURES list: ${__ARGS_SERIALIZED}")
	list(APPEND __TMP_LIST ${__ARGS__LIST})
	_retrieve_instance_args(${__INSTANCE_ID} LINKPARS __ARGS)
#	    _serialize_variables(__ARGS __ARGS__LIST __ARGS_SERIALIZED)
#	    message(STATUS "_invoke_apply_dependency_to_target() LINKPARS list: ${__ARGS_SERIALIZED}")
	_retrieve_instance_pars(${__INSTANCE_ID} __PARS)
#	message(STATUS "_invoke_apply_dependency_to_target() linkpar list: ${__ARGS__LIST}")
	list(APPEND __TMP_LIST ${__ARGS__LIST})
	set(__ARGS__LIST ${__TMP_LIST})
	if(__DEPENDEE_INSTANCE_ID)
		_make_instance_name(${__DEPENDEE_INSTANCE_ID} __DEP_INSTANCE_NAME)
		get_target_property(__TYPE ${__DEP_INSTANCE_NAME} TYPE)
		if("${__TYPE}" STREQUAL "INTERFACE_LIBRARY" )
			set(KEYWORD "INTERFACE")
		else()
			set(KEYWORD "PUBLIC")
		endif()
	else()
		set(__DEP_INSTANCE_NAME)
		set(KEYWORD "NONE")
	endif()
	
#	_serialize_variables(__ARGS __TMP_LIST __ARGS_SERIALIZED)
#	message(STATUS "_invoke_apply_dependency_to_target() Got variables: ${__ARGS_SERIALIZED}")
	
	_make_instance_name(${__INSTANCE_ID} __INSTANCE_NAME)
	
	_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __DEP_ID_LIST)
	_insert_names_from_dependencies("${__DEP_ID_LIST}" __ARGS)

	get_filename_component(__TEMPLATE_DIR "${__TARGETS_CMAKE_PATH}" DIRECTORY)
	_read_functions_from_targets_file("${__TARGETS_CMAKE_PATH}")
#	message(STATUS "_invoke_apply_dependency_to_target() Serialbox_SerialboxCStatic_INSTALL_DIR: ${Serialbox_SerialboxCStatic_INSTALL_DIR}")
	
	set(CMAKE_CURRENT_SOURCE_DIR "${__TEMPLATE_DIR}")

	_instantiate_variables(__ARGS __PARS "${__ARGS__LIST}")
#	message(STATUS "_invoke_apply_dependency_to_target(): __TEMPLATE_NAME ${__TEMPLATE_NAME} got __INSTANCE_ID: ${__INSTANCE_ID}. IMPLICIT_GLOBAL: ${IMPLICIT_GLOBAL} IMPLICIT_LOCAL: ${IMPLICIT_LOCAL} IMPLICIT_IMPORTED: ${IMPLICIT_IMPORTED} IMPLICIT_EXPORTED: ${IMPLICIT_EXPORTED} IMPLICIT_EXPORTED_DEFAULT: ${IMPLICIT_EXPORTED_DEFAULT} IMPLICIT_LINK: ${IMPLICIT_LINK} ")

	unset(__NO_OP)
#	apply_to_target(${__DEPENDEE_INSTANCE_ID} ${__INSTANCE_NAME})
#	take_dependency_from_target(${__DEPENDEE_INSTANCE_ID} ${__INSTANCE_NAME})



	apply_dependency_to_target("${__DEP_INSTANCE_NAME}" ${__INSTANCE_NAME})

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
	set(__ARG_I -1)
	set(__TO_REMOVE )
	set(__ALL_PARS ${__POSITIONAL} ${__OPTIONS} ${__oneValueArgs} ${__multiValueArgs})
	set(__ALL_PARS_COPY ${__ALL_PARS})
	list(REMOVE_DUPLICATES __ALL_PARS_COPY)
	list(LENGTH __ALL_PARS __ALL_PARS_COUNT)
	list(LENGTH __ALL_PARS_COPY __UNIQUE_PARS_COUNT)
	if(__PARENT_SCOPE)
		set(__PARENT_SCOPE "PARENT_SCOPE")
	endif()
	if(${__UNIQUE_PARS_COUNT} LESS ${__ALL_PARS_COUNT})
		message(FATAL_ERROR "Internal beetroot error: non-unique names of parameters passed to _parse_general_function_arguments(\"${__POSITIONAL}\" \"${__OPTIONS}\" \"${__oneValueArgs}\" \"${__multiValueArgs}\" ${__OUT_PREFIX})")
	endif()
	foreach(__VAR IN LISTS __POSITIONAL __OPTIONS __oneValueArgs __multiValueArgs)
#		message(STATUS "_parse_general_function_arguments(): resetting ${__OUT_PREFIX}_${__VAR}...")
		set(${__OUT_PREFIX}_${__VAR} "" PARENT_SCOPE)
	endforeach()
	if(__POSITIONAL)
		foreach(__POS_ITEM IN LISTS __POSITIONAL)
#			message(STATUS "_parse_general_function_arguments(): __POS_ITEM: ${__POS_ITEM}")
			math(EXPR __ARGSKIP "${__ARGSKIP} + 1")
			math(EXPR __ARG_I "${__ARG_I} + 1")
			list(APPEND __TO_REMOVE ${__ARG_I})
#			message(STATUS "_parse_general_function_arguments(): __ARGSKIP: ${__ARGSKIP}")
			if(${ARGC} LESS_EQUAL ${__ARGSKIP})
				message(FATAL_ERROR "Internal beetroot error: _append_postprocessing_action(${__ACTION}) was passed less arguments than the number of obligatory positional parameters ${__POSITIONAL}")
			endif()
			set(___PARSED_${__POS_ITEM} "${ARGV${__ARGSKIP}}")
#			message(STATUS "_parse_general_function_arguments(): Got positional value ___PARSED_${__POS_ITEM}: ${ARGV${__ARGSKIP}} __TO_REMOVE: ${__TO_REMOVE}. ")
		endforeach()
#		message(STATUS "_parse_general_function_arguments(): ARGV${__ARGSKIP}: ${ARGV${__ARGSKIP}}")
		set(__COPY_ARGS "${ARGN}")
#		message(STATUS "_parse_general_function_arguments(): Going to remove: ${__TO_REMOVE} from __COPY_ARGS: ${__COPY_ARGS} ")
		list(REMOVE_AT __COPY_ARGS ${__TO_REMOVE})
	else()
		set(__COPY_ARGS ${ARGV})
	endif()
	
#	message(STATUS "_parse_general_function_arguments(): After positional arguments: __COPY_ARGS: ${__COPY_ARGS}")
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


function(_parse_file_options __TARGETS_CMAKE_PATH __IS_TARGET_FIXED __FILE_OPTIONS__REF __OUT_SINGLETON_TARGETS __OUT_NO_TARGETS __OUT_LANGUAGES __OUT_NICE_NAME __OUT_EXPORTED_VARIABLES __OUT_LINK_TO_DEPENDEE __OUT_DONT_LINK_TO_DEPENDEE __OUT_GENERATE_TARGETS_INCLUDE_LINKPARS __OUT_JOINED_TARGETS)
	set(__OPTIONS SINGLETON_TARGETS NO_TARGETS LINK_TO_DEPENDEE DONT_LINK_TO_DEPENDEE GENERATE_TARGETS_INCLUDE_LINKPARS JOINED_TARGETS)
	set(__oneValueArgs NICE_NAME)
	set(__multiValueArgs LANGUAGES EXPORTED_VARIABLES)
	
	set(__PARSED_LANGUAGES)
	set(__PARSED_SINGLETON_TARGETS)
	set(__PARSED_NO_TARGETS)
	cmake_parse_arguments(__PARSED "${__OPTIONS}" "${__oneValueArgs}" "${__multiValueArgs}" ${${__FILE_OPTIONS__REF}__LIST})
	set(__unparsed ${__PARSED_UNPARSED_ARGUMENTS})
	if(__unparsed)
		_get_relative_path("${__TARGETS_CMAKE_PATH}" __TARGETS_CMAKE_PATH_REL)
		message(FATAL_ERROR "Undefined FILE_OPTIONS in ${__TARGETS_CMAKE_PATH_REL}: ${__unparsed}")
	endif()
	
	#message(STATUS "_parse_file_options(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH} ${__FILE_OPTIONS__REF}__LIST: ${${__FILE_OPTIONS__REF}__LIST}")
	if(__PARSED_LANGUAGES)
		set(__CMAKE_LANGUAGES CXX C CUDA Fortran ASM)
		foreach(__LANGUAGE IN LISTS __PARSED_LANGUAGES)
			if(NOT ${__LANGUAGE} IN_LIST __CMAKE_LANGUAGES)
				message(FATAL_ERROR "Option LANGUAGES in FILE_OPTIONS defined in ${__TARGETS_CMAKE_PATH} contains unknown language \"${__LANGUAGE}\".")
			endif()
		endforeach()
		set(${__OUT_LANGUAGES} ${__PARSED_LANGUAGES} PARENT_SCOPE)
	else()
		set(${__OUT_LANGUAGES} "" PARENT_SCOPE)
	endif()
	
	_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH)
	if(__PARSED_SINGLETON_TARGETS)
		set(${__OUT_SINGLETON_TARGETS} 1 PARENT_SCOPE)
		if(NOT __IS_TARGET_FIXED)
			message(FATAL_ERROR "When using SINGLETON_TARGETS option, please list all targets using ENUM_TARGETS rather than ENUM_TEMPLATES.")
		endif()
	else()
		set(${__OUT_SINGLETON_TARGETS} 0 PARENT_SCOPE)
	endif()

	if(__PARSED_NO_TARGETS)
		set(${__OUT_NO_TARGETS} 1 PARENT_SCOPE)
	else()
		set(${__OUT_NO_TARGETS} 0 PARENT_SCOPE)
	endif()

	if(__PARSED_NICE_NAME)
		set(${__OUT_NICE_NAME} "${__PARSED_NICE_NAME}" PARENT_SCOPE)
	else()
		set(${__OUT_NICE_NAME} "" PARENT_SCOPE)
	endif()
	
	if(__PARSED_EXPORTED_VARIABLES)
		set(${__OUT_EXPORTED_VARIABLES} "${__PARSED_EXPORTED_VARIABLES}" PARENT_SCOPE)
	else()
		set(${__OUT_EXPORTED_VARIABLES} "" PARENT_SCOPE)
	endif()

	if(__PARSED_LINK_TO_DEPENDEE)
		set(${__OUT_LINK_TO_DEPENDEE} "1" PARENT_SCOPE)
	else()
		set(${__OUT_LINK_TO_DEPENDEE} "0" PARENT_SCOPE)
	endif()

	if(__PARSED_DONT_LINK_TO_DEPENDEE)
		set(${__OUT_DONT_LINK_TO_DEPENDEE} "1" PARENT_SCOPE)
	else()
		set(${__OUT_DONT_LINK_TO_DEPENDEE} "0" PARENT_SCOPE)
	endif()

	if(__PARSED_GENERATE_TARGETS_INCLUDE_LINKPARS)
		set(${__OUT_GENERATE_TARGETS_INCLUDE_LINKPARS} "1" PARENT_SCOPE)
	else()
		set(${__OUT_GENERATE_TARGETS_INCLUDE_LINKPARS} "0" PARENT_SCOPE)
	endif()

	if(__PARSED_JOINED_TARGETS)
		message(FATAL_ERROR "Template option JOINED_TARGETS has not been implemented")
		set(${__OUT_JOINED_TARGETS} "1" PARENT_SCOPE)
	else()
		set(${__OUT_JOINED_TARGETS} "0" PARENT_SCOPE)
	endif()
endfunction()

function(_nice_arg_list __ARGS __ARGS_LIST __OUT)
	set(__TMP)
	foreach(__VAR IN LISTS ${__ARGS_LIST})
		list(APPEND __TMP "${__VAR}=\"${${__ARGS}_${__VAR}}\"")
	endforeach()
	nice_list_output(OUTVAR __TXT LIST ${__TMP})
	set(${__OUT} ${__TXT} PARENT_SCOPE)
endfunction()
