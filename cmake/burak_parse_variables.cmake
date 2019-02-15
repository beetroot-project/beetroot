# _get_variables(<path to targets.cmake> <out_arguments_prefix> <out_template_names> <out_DEFINE_EXTERNAL_PROJECT> <Args...>)
#
# Parses targets.cmake and gets the actual value of the variables based on the 
# 1. defaults declared in targets.cmake,
# 2. overriden by pre-existing CMake variables which names matches the declared parameters in the targets.cmake
# 3. overriden by named arguments passed in Args... .
# The values are checked for validity and stored in the standard format in prefix out_arguments_prefix. 
# Moreover it saves template names declared in the targets.cmake (in ${out_template_names}) and information about external project in ${out_external}.
#
# The algorithm allows for default values for parameters to be dependent on other variables, which allows to encode parameter transformation logic, because the
# values for the variables will be taken _after_ injecting the cached variables and - which is non trivial - the arguments Args... (which override everything).
#
# Moreover, the mentioned algorithm is run several times, as long as the names of the variables stabilise. That means, that variable defined as 
#
# set(LINK_PARAMETERS 
#	NEVER_ENDING_INTEGER	SCALAR	INTEGER "${NEVER_ENDING_INTEGET}+1")
#
# Will never parse, because on each run of the algorithm the value for NEVER_ENDING_INTEGET will be different. 
#
# But this is usefull for e.g.
#
# if("${MY_OTHER_ARG}" STREQUAL "1" )
#	set(TMP "SINGULAR")
# else()
#	set(TMP "PLURAL")
# endif()
#
# set(LINK_PARAMETERS 
#	MY_OTHER_ARG	SCALAR	INTEGER 1
#	ARG	SCALAR	CHOICE(SINGULAR;PLURAL) ${TMP}
# )
function(_get_variables __TARGETS_CMAKE_PATH __CALLING_FILE __ARGS_IN __FLAG_VERIFY __OUT_VARIABLE_DIC __OUT_PARAMETERS_DIC __OUT_TEMPLATE_NAMES __OUT_EXTERNAL_PROJECT_INFO __OUT_IS_TARGET_FIXED __OUT_GLOBAL_OPTIONS)
	set(__ARGUMENT_HASH)
	set(__ITERATION_COUNT 0)

	set(__ARGUMENT_HASH_OLD "")
	set(__ARG_LIST "${ARGN}")
#	message(STATUS "_get_variables(): ARGN: ${ARGN} __ARG_LIST: ${__ARG_LIST}")

	set(__DEBUG_VAR_NAME LIB_MYVAR)
	if(__ARGS_LIB_MYVAR)
		message(FATAL_ERROR "__ARGS_LIB_MYVAR is set to ${__ARGS_LIB_MYVAR}")
	endif()
#	message(STATUS "_get_variables(): __ARGS_IN: ${__ARGS_IN} __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH}")
#	message(STATUS "_get_variables(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH} __CALLING_FILE: ${__CALLING_FILE}")
	foreach(__ITERATION RANGE 10)
#		if(__ARGS_${__DEBUG_VAR_NAME})
#			message(STATUS "_get_variables(): __ITERATION: ${__ITERATION}, phase 1, __ARGS_${__DEBUG_VAR_NAME}: ${__ARGS_${__DEBUG_VAR_NAME}}")
#		endif()
		if(${__ITERATION} EQUAL 0)
			_read_parameters("${__TARGETS_CMAKE_PATH}" "${__ARGS_IN}" __PARS __ARGS __IN_TEMPLATE_NAMES __IN_EXTERNAL_PROJECT_INFO __IN_IS_TARGET_FIXED __GLOBAL_OPTIONS)
		else()
			_read_parameters("${__TARGETS_CMAKE_PATH}" __ARGS __PARS __ARGS __IN_TEMPLATE_NAMES __IN_EXTERNAL_PROJECT_INFO __IN_IS_TARGET_FIXED __GLOBAL_OPTIONS)
		endif()

#		message(STATUS "_get_variables(): __PARS_${__DEBUG_VAR_NAME}__TYPE: ${__PARS_${__DEBUG_VAR_NAME}__TYPE}")
#		if(__ARGS_${__DEBUG_VAR_NAME})
#			message(STATUS "_get_variables(): __ITERATION: ${__ITERATION}, phase 2, __ARGS_${__DEBUG_VAR_NAME}: ${__ARGS_${__DEBUG_VAR_NAME}}")
#		endif()

		if(NOT __PARS__LIST)
			if(__ARG_LIST)
				message(FATAL_ERROR "Passed variables ${__ARG_LIST} to the target ${__TARGETS_CMAKE_PATH} from ${__CALLING_FILE} when the target does not accept any kind of parameters")
			endif()
			break() #no variables
		endif()
		_read_variables_from_cache(__PARS __ARGS "" cache __ARGS)
#		if(__ARGS_${__DEBUG_VAR_NAME})
#			message(STATUS "_get_variables(): __ITERATION: ${__ITERATION}, phase 3, __ARGS_${__DEBUG_VAR_NAME}: ${__ARGS_${__DEBUG_VAR_NAME}} ARGN: ${ARGN}")
#		endif()
#		message(STATUS "_get_variables(): ARGN: ${__ARG_LIST}")

		_read_variables_from_args(__PARS __ARGS __ARGS ${__ARG_LIST})
#		if(__ARGS_${__DEBUG_VAR_NAME})
#			message(STATUS "_get_variables(): __ITERATION: ${__ITERATION}, phase 4, __ARGS_${__DEBUG_VAR_NAME}: ${__ARGS_${__DEBUG_VAR_NAME}}")
#		endif()
#		message(STATUS "_get_variables(): __ARGS__SRC_BCTYPE: ${__ARGS__SRC_BCTYPE}")
		_calculate_hash(__ARGS "${__ARGS__LIST}" "_getvars_" __ARGUMENT_HASH_NEW __HASH_SOURCE)
		
#		message(STATUS "_get_variables(): __ARGUMENT_HASH_OLD: ${__ARGUMENT_HASH_OLD}, __ARGUMENT_HASH_NEW: ${__ARGUMENT_HASH_NEW}, __IN_EXTERNAL_PROJECT_INFO: ${__IN_EXTERNAL_PROJECT_INFO}")
		if("${__ARGUMENT_HASH_NEW}" STREQUAL "${__ARGUMENT_HASH_OLD}")
			break()
		endif()
		set(__ARGUMENT_HASH_OLD "${__ARGUMENT_HASH_NEW}")
	endforeach()
#	if("${__TARGETS_CMAKE_PATH}" MATCHES "/serialbox.cmake")
#		message(WARNING "_get_variables(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH} __IN_EXTERNAL_PROJECT_INFO: ${__IN_EXTERNAL_PROJECT_INFO} __IN_TEMPLATE_NAMES: ${__IN_TEMPLATE_NAMES} __OUT_EXTERNAL_PROJECT_INFO: ${__OUT_EXTERNAL_PROJECT_INFO}")
#	else()
#		message(STATUS "_get_variables(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH} __IN_EXTERNAL_PROJECT_INFO: ${__IN_EXTERNAL_PROJECT_INFO} __IN_TEMPLATE_NAMES: ${__IN_TEMPLATE_NAMES}")
#	endif()
	if(NOT "${__ARGUMENT_HASH_NEW}" STREQUAL "${__ARGUMENT_HASH_OLD}")
		message(FATAL_ERROR "Could not converge the values of arguments after ${__ITERATION} iterations")
	endif()
#	message(STATUS "_get_variables(): __FLAG_VERIFY: ${__FLAG_VERIFY}")
	if(__FLAG_VERIFY)
		foreach(__VAR_NAME IN LISTS __PARS__LIST)
#			message(STATUS "_get_variables(): Veryfying variable ${__VAR_NAME}")
			if("${__ARGS__SRC_${__VAR_NAME}}" STREQUAL "default")
				set(__SRC "as default parameter in ${__TARGETS_CMAKE_PATH}")
			elseif("${__ARGS__SRC_${__VAR_NAME}}" STREQUAL "cache")
				set(__SRC "as already set variable, perhaps in the calling CMakeLists.txt")
			elseif("${__ARGS__SRC_${__VAR_NAME}}" STREQUAL "args")
				set(__SRC "as explicitely set function named argument in the ${__CALLING_FILE}")
			else()
				message(FATAL_ERROR "Internal beetroot error: Unknown source of variable ${__VAR_NAME}: __ARGS__SRC_${__VAR_NAME}: ${__ARGS__SRC_${__VAR_NAME}}")
			endif()
			if(${__VAR_NAME} IN_LIST __PARS__LIST_FEATURES)
				set(__BOOL_FEATURES 1)
			else()
				set(__BOOL_FEATURES 0)
			endif()
			_verify_parameter("${__VAR_NAME}" "${__SRC}" "${__PARS_${__VAR_NAME}__CONTAINER}" "${__PARS_${__VAR_NAME}__TYPE}" "${__ARGS_${__VAR_NAME}}" ${__BOOL_FEATURES})
			if("${__PARS_${__VAR_NAME}__TYPE}" STREQUAL "BOOL")
				set(__TMP)
				foreach(__VAL IN LISTS __ARGS_${__VAR_NAME})
					if(__VAL)
						list(APPEND __TMP 1)
					else()
						list(APPEND __TMP 0)
					endif()
				endforeach()
				set(__ARGS_${__VAR_NAME} ${__TMP})
			endif()
		endforeach()
	endif()
	
	foreach(__VAR_NAME IN LISTS __PARS__LIST)
		if("${__PARS_${__VAR_NAME}__TYPE}" STREQUAL "BOOL")
			set(__TMP)
			foreach(__VAL IN LISTS __ARGS_${__VAR_NAME})
				if(__VAL)
					list(APPEND __TMP 1)
				else()
					list(APPEND __TMP 0)
				endif()
			endforeach()
			set(__ARGS_${__VAR_NAME} ${__TMP})
		endif()
	endforeach()
	
	_pass_arguments_higher(__ARGS ${__OUT_VARIABLE_DIC})
	_pass_parameters_higher(__PARS ${__OUT_PARAMETERS_DIC})
	set(${__OUT_TEMPLATE_NAMES} "${__IN_TEMPLATE_NAMES}" PARENT_SCOPE)
	set(${__OUT_EXTERNAL_PROJECT_INFO} "${__IN_EXTERNAL_PROJECT_INFO}" PARENT_SCOPE)
	set(${__OUT_IS_TARGET_FIXED} "${__IN_IS_TARGET_FIXED}" PARENT_SCOPE)
	set(${__OUT_GLOBAL_OPTIONS} "${__GLOBAL_OPTIONS}" PARENT_SCOPE)
	
endfunction()

macro(_parse_parameters __DEFINITIONS __OUT_ARGS __OUT_PARS __TARGETS_CMAKE_PATH __BOOL_FEATURES)
#	set(__DEFINITIONS ${__DEFINITIONS})
	list(LENGTH ${__DEFINITIONS} __TMP)
	
#	message(STATUS "_parse_parameters(), __DEFINITIONS=${${__DEFINITIONS}} ${__OUT_ARGS}__LIST: ${${__OUT_ARGS}__LIST}")
	math(EXPR __PARS_LENGTH "${__TMP} / 4 - 1")
	math(EXPR __PARS_CHECK "${__TMP} % 4")
	if(NOT "${__PARS_CHECK}" STREQUAL "0")
		message(FATAL_ERROR "Wrong number of elements in the PARAMETERS/FEATURES variable defined in ${__TARGETS_CMAKE_PATH}. Expected number of elements divisible by 4, but got ${__TMP} elements: ${${__DEFINITIONS}}")
	endif()
#	message(STATUS "_parse_parameters(), __PARS_LENGTH=${__PARS_LENGTH}")
	if(NOT "${__TMP}" STREQUAL 0)
		set(__LIST)
		foreach(__VAR_NR RANGE "${__PARS_LENGTH}")
			math(EXPR __TMP "${__VAR_NR}*4")
			list(GET ${__DEFINITIONS} ${__TMP} __VAR_NAME )
			if( "${__VAR_NAME}" MATCHES "^_.*$")
				message(FATAL_ERROR "Cannot declare variables that start with underscore (like \"${__VARNAME}\"). Error encountered in ${__TARGETS_CMAKE_PATH}.")
			endif()
			if(NOT "${__VAR_NAME}" MATCHES "^[A-Za-z][A-Za-z0-9_]*$")
				message(FATAL_ERROR "Variables must start with the letter and consit only from letters, digits and underscores, not like \"${__VARNAME}\" encounterd in ${__TARGETS_CMAKE_PATH}.")
			endif()
			math(EXPR __TMP_CONTAINER "${__VAR_NR}*4 + 1")
			list(GET ${__DEFINITIONS} ${__TMP_CONTAINER} __TMP_CONTAINER)
			math(EXPR __TMP_TYPE "${__VAR_NR}*4 + 2")
			list(GET ${__DEFINITIONS} ${__TMP_TYPE} __TMP_TYPE)
			math(EXPR __TMP_DEFAULT "${__VAR_NR}*4 + 3")
			list(GET ${__DEFINITIONS} ${__TMP_DEFAULT} __TMP_DEFAULT)
			if("${__TMP_CONTAINER}" STREQUAL "VECTOR")
				string(REPLACE ":" ";" __TMP_DEFAULT "${__TMP_DEFAULT}")
			elseif("${__TMP_CONTAINER}" STREQUAL "OPTION")
				if("${__TMP_TYPE}" STREQUAL "")
					set(__TMP_TYPE BOOL)
				elseif(NOT "${__TMP_TYPE}" STREQUAL "BOOL")
					message(FATAL_ERROR "Type of the OPTION variable ${__VAR_NAME} defined in ${__TARGETS_CMAKE_PATH} must always be BOOL (or simply left empty like \"\").")
				endif()
				if(__TMP_DEFAULT)
					set(__TMP_DEFAULT 1)
				else()
					set(__TMP_DEFAULT 0)
				endif()
			endif()
			set(__SKIP 0)
			if("${__VAR_NAME}" STREQUAL "LIB_MYVAR")
#				message(STATUS "_parse_parameters(): ${__OUT_ARGS}_${__VAR_NAME}__CONTAINER: ${__TMP_CONTAINER} ${__OUT_ARGS}_${__VAR_NAME}__TYPE: ${__TMP_TYPE} ${__OUT_ARGS}_${__VAR_NAME}: ${__TMP_DEFAULT}")
			endif()
			if("${__VAR_NAME}" IN_LIST ${__OUT_ARGS}__LIST)
#				message(STATUS "_parse_parameters(): ${__OUT_PARS}_${__VAR_NAME}__CONTAINER: ${__TMP_CONTAINER} ${__OUT_PARS}_${__VAR_NAME}__TYPE: ${__TMP_TYPE} ${__OUT_ARGS}_${__VAR_NAME}: ${__TMP_DEFAULT}")
				if(NOT "${${__OUT_PARS}_${__VAR_NAME}__CONTAINER}" STREQUAL "${__TMP_CONTAINER}" OR
					NOT "${${__OUT_PARS}_${__VAR_NAME}__TYPE}" STREQUAL "${__TMP_TYPE}" OR
					NOT "${${__OUT_ARGS}_${__VAR_NAME}}" STREQUAL "${__TMP_DEFAULT}")
					message(FATAL_ERROR "Multiple definitions of the same variable/modifier (here: \"${__VAR_NAME}\") are not the same. One definition is a ${${__OUT_PARS}_${__VAR_NAME}__CONTAINER} of type ${${__OUT_PARS}_${__VAR_NAME}__TYPE} = \"${${__OUT_ARGS}_${__VAR_NAME}}\" and the other is a ${__TMP_CONTAINER} of type ${__TMP_TYPE} = \"${__TMP_DEFAULT}\". Modifiers and variables share the same namespace. Error encountered in ${__TARGETS_CMAKE_PATH}.")
				else()
					set(__SKIP 1)
				endif()
			endif()
			if(NOT __SKIP)
#				message(STATUS "_parse_parameters(): exporting ${__OUT_PARS}_${__VAR_NAME}__CONTAINER: ${__TMP_CONTAINER} ${__OUT_PARS}_${__VAR_NAME}__TYPE: ${__TMP_TYPE} ${__OUT_ARGS}_${__VAR_NAME}: ${__TMP_DEFAULT}")
				set(${__OUT_PARS}_${__VAR_NAME}__CONTAINER ${__TMP_CONTAINER})
				set(${__OUT_PARS}_${__VAR_NAME}__TYPE ${__TMP_TYPE})
				set(${__OUT_ARGS}_${__VAR_NAME} "${__TMP_DEFAULT}")
				set(${__OUT_ARGS}__SRC_${__VAR_NAME} default)
				list(APPEND ${__OUT_ARGS}__LIST "${__VAR_NAME}")
				list(APPEND ${__OUT_PARS}__LIST "${__VAR_NAME}")
			endif()
#			message(STATUS "_parse_parameters(): Found variable ${__VAR_NAME} with container ${__OUT_PARS}_${__VAR_NAME}__CONTAINER: ${${__OUT_PARS}_${__VAR_NAME}__CONTAINER}")
		endforeach()
	endif()
endmacro()

# Reads, parses and checks parameter definition from targets.cmake.
# Also initializes argument list with the default value of each parameter.
function(_read_parameters __TARGETS_CMAKE_PATH __EXISTING_ARGS __OUT_PARAMETERS_PREFIX __OUT_ARGUMENTS_PREFIX __OUT_TEMPLATE_NAMES __OUT_EXTERNAL_PROJECT_INFO __OUT_IS_TARGET_FIXED __OUT_GLOBAL_OPTIONS)
	if(__EXISTING_ARGS)
		_instantiate_variables(${__EXISTING_ARGS} "" "${${__EXISTING_ARGS}__LIST}" )
	endif()
	_read_targets_file("${__TARGETS_CMAKE_PATH}" 0 __READ_PREFIX __IS_TARGET_FIXED)
	

	set(${__OUT_ARGUMENTS_PREFIX}__LIST)
	set(${__OUT_PARAMETERS_PREFIX}__LIST_MODIFIERS)
	set(${__OUT_PARAMETERS_PREFIX}__LIST_FEATURES)
	set(${__OUT_PARAMETERS_PREFIX}__LIST_LINKPARS)

	set(${__OUT_PARAMETERS_PREFIX}__LIST)
#	message(STATUS "_read_parameters(): __READ_PREFIX_LINK_PARAMETERS: ${__READ_PREFIX_LINK_PARAMETERS}")
	
	_parse_parameters(__READ_PREFIX_TARGET_PARAMETERS ${__OUT_ARGUMENTS_PREFIX} ${__OUT_PARAMETERS_PREFIX} "${__TARGETS_CMAKE_PATH}" 0)
	
#	message(STATUS "_read_parameters(): __READ_PREFIX_TARGET_PARAMETERS: ${__READ_PREFIX_TARGET_PARAMETERS}")
#	message(STATUS "_read_parameters(): ${__OUT_PARAMETERS_PREFIX}__LIST: ${${__OUT_PARAMETERS_PREFIX}__LIST}")
	set(${__OUT_PARAMETERS_PREFIX}__LIST_MODIFIERS "${${__OUT_PARAMETERS_PREFIX}__LIST}")


	set(${__OUT_PARAMETERS_PREFIX}__LIST)
	_parse_parameters(__READ_PREFIX_TARGET_FEATURES ${__OUT_ARGUMENTS_PREFIX} ${__OUT_PARAMETERS_PREFIX} "${__TARGETS_CMAKE_PATH}" 1)
	set(${__OUT_PARAMETERS_PREFIX}__LIST_FEATURES "${${__OUT_PARAMETERS_PREFIX}__LIST}")
	list_intersect(__INTERSECT ${__OUT_PARAMETERS_PREFIX}__LIST_MODIFIERS ${__OUT_PARAMETERS_PREFIX}__LIST_FEATURES)
	if(__INTERSECT)
		message(FATAL_ERROR "The parameters ${__INTERSECT} are defined both in TARGET_PARAMETERS and TARGET_FEATURES. Parameters in TARGET_FEATURES, TARGET_PARAMETERS and LINK_PARAMETERS share the same namespace and it is illegal to re-define already defined parameter.")
	endif()

	set(${__OUT_PARAMETERS_PREFIX}__LIST)
	_parse_parameters(__READ_PREFIX_LINK_PARAMETERS ${__OUT_ARGUMENTS_PREFIX} ${__OUT_PARAMETERS_PREFIX} "${__TARGETS_CMAKE_PATH}" 0)
	set(${__OUT_PARAMETERS_PREFIX}__LIST_LINKPARS "${${__OUT_PARAMETERS_PREFIX}__LIST}")
	set(__LIST ${${__OUT_PARAMETERS_PREFIX}__LIST_MODIFIERS} ${${__OUT_PARAMETERS_PREFIX}__LIST_FEATURES})
	list_intersect(__INTERSECT __LIST ${__OUT_PARAMETERS_PREFIX}__LIST_LINKPARS)
	if(__INTERSECT)
		message(FATAL_ERROR "The parameters ${__INTERSECT} are defined both in LINK_PARAMETERS and one of TARGET_PARAMETERS and TARGET_FEATURES. Parameters in TARGET_FEATURES, TARGET_PARAMETERS and LINK_PARAMETERS share the same namespace and it is illegal to re-define already defined parameter.")
	endif()
	
	set(${__OUT_PARAMETERS_PREFIX}__LIST ${${__OUT_PARAMETERS_PREFIX}__LIST_MODIFIERS} ${${__OUT_PARAMETERS_PREFIX}__LIST_FEATURES} ${${__OUT_PARAMETERS_PREFIX}__LIST_LINKPARS})
	
	_pass_arguments_higher(${__OUT_ARGUMENTS_PREFIX} ${__OUT_ARGUMENTS_PREFIX})
	_pass_parameters_higher(${__OUT_PARAMETERS_PREFIX} ${__OUT_PARAMETERS_PREFIX})
	
	
	set(${__OUT_TEMPLATE_NAMES} "${__READ_PREFIX_ENUM_TEMPLATES}" PARENT_SCOPE)
	set(${__OUT_EXTERNAL_PROJECT_INFO} "${__READ_PREFIX_DEFINE_EXTERNAL_PROJECT}" PARENT_SCOPE)
	set(${__OUT_IS_TARGET_FIXED} "${__IS_TARGET_FIXED}" PARENT_SCOPE)
	set(${__OUT_GLOBAL_OPTIONS} "${__READ_PREFIX_TEMPLATE_OPTIONS}" PARENT_SCOPE)
endfunction()

# _read_variables_from_cache(__PARS __ARGS __VALUES __OUT_ARGS)
#
# Iterates over all variables in __PARS, and combines the values taken from __ARGS with overrides taken as the same name, but with optional prefix __VALUES.
#
# It also validates the variable, if it is taken from __VALUES and __PARS is not equal ""
function(_read_variables_from_cache __PARS __ARGS __VALUES __SOURCE __OUT_ARGS)
	foreach(__VAR IN LISTS ${__ARGS}__LIST)
		if(NOT "${${__VAR}}" STREQUAL "")
			set(__EXT_VARNAME ${__VAR})
		else()
			set(__EXT_VARNAME ${__VALUES}_${__VAR})
		endif()
		if(DEFINED ${__EXT_VARNAME})
			if(__PARS)
				if("${__VAR}" IN_LIST ${__PARS}__LIST_FEATURES)
					set(__FEATURE 1)
				else()
					set(__FEATURE 0)
				endif()
#				_verify_parameter("${__VAR}" "as defined value ${__EXT_VARNAME}" "${${__PARS}_${__VAR}__CONTAINER}" "${${__PARS}_${__VAR}__TYPE}" "${${__EXT_VARNAME}}" __FEATURE)
			endif()
			set(${__OUT_ARGS}_${__VAR} "${${__EXT_VARNAME}}" PARENT_SCOPE)
#			message(STATUS "_read_variables_from_cache(): Setting ${__OUT_ARGS}__SRC_${__VAR}: ${__SOURCE}")
			set(${__OUT_ARGS}__SRC_${__VAR} "${__SOURCE}" PARENT_SCOPE)
		else()
			set(${__OUT_ARGS}_${__VAR} "${${__ARGS}_${__VAR}}" PARENT_SCOPE)
		endif()
	endforeach()
	set(${__OUT_ARGS}__LIST "${${__ARGS}__LIST}" PARENT_SCOPE)
	set(${__OUT_ARGS}__LIST_MODIFIERS "${${__ARGS}__LIST_MODIFIERS}" PARENT_SCOPE)
	
endfunction()

function(_verify_parameter NAME CONTEXT CONTAINER TYPE VALUE IS_FEATURE)
#When IS_FEATURE is set, there is smaller set of valid type+container combinations
	set(VALID_CONTAINERS OPTION SCALAR VECTOR)
	set(VALID_TYPES INTEGER PATH STRING BOOL)
	if(NOT "${TYPE}" MATCHES "^CHOICE\(.+\)$" AND NOT "${TYPE}" IN_LIST VALID_TYPES)
		message(FATAL_ERROR "Wrong type for variable ${NAME} ${CONTEXT}. Must be INTEGER, PATH, STRING or CHOICE(opt1,opt2,...,optN) format, but got ${TYPE}")
	endif()
	if(NOT "${CONTAINER}" IN_LIST VALID_CONTAINERS)
		message(FATAL_ERROR "Wrong container for variable ${NAME} ${CONTEXT}. Container must be one of OPTION SCALAR or VECTOR, but got ${CONTAINER}")
	endif()
	if("${CONTAINER}" STREQUAL "OPTION")
		if(NOT "${TYPE}" STREQUAL "BOOL")
			message(FATAL_ERROR "Container OPTION can only contain boolean variables. Please specify type of the variable as BOOL in the definition of ${NAME} ${CONTEXT}")
		endif()
		_verify_value("${NAME}" "${CONTEXT}" BOOL "${VALUE}" ${IS_FEATURE})
	else()
		foreach(VAL IN LISTS VALUE)
			_verify_value("${NAME}" "${CONTEXT}" "${TYPE}" "${VAL}" ${IS_FEATURE})
		endforeach()
	endif()
endfunction()

function(_verify_value NAME CONTEXT TYPE VALUE IS_FEATURE)
	if("${TYPE}" STREQUAL "INTEGER")
		if(NOT "${VALUE}" MATCHES "^[0-9]+$")
			message(FATAL_ERROR "Wrong value of the variable ${NAME} ${CONTEXT}. Expected integer, but got ${VALUE}")
		endif()
	elseif("${TYPE}" STREQUAL "BOOL")
		set(VALID_YES ON YES TRUE Y)
		set(VALID_NO 0 OFF NO FALSE N IGNORE NOTFOUND)
		set(VALID_ALL ${VALID_YES} ${VALID_NO})
		if ("${VALUE}" MATCHES "^[1-9][0-9]*$")
			return() #OK, yes
		endif()
		if("${VALUE}" IN_LIST VALID_ALL)
			return() #OK, yes or no
		endif()
		if("${VALUE}" STREQUAL "")
			return() #OK, no
		endif()
		message(FATAL_ERROR "Wrong value of the variable ${NAME} ${CONTEXT}. Expected BOOL, but got ${VALUE}")
	elseif("${TYPE}" STREQUAL "STRING")
		return() #String is always ok
	elseif("${TYPE}" STREQUAL "PATH")
		return() #Path is always ok - for now...;-)
	else()
#		message(FATAL_ERROR "string(REGEX_MATCH \"^CHOICE\\((.*)\\)$\" CHOICES \"${TYPE}\")")
		string(REGEX REPLACE "^CHOICE\\((.*)\\)$" "\\1" CHOICES "${TYPE}")
		if(NOT CHOICES)
			message(FATAL_ERROR "Wrong format of type: ${TYPE} ${CONTEXT} for variable ${NAME}.")
		endif()
		string(REPLACE ":" ";" CHOICES_LIST "${CHOICES}")
		if(NOT "${VALUE}" IN_LIST CHOICES_LIST)
			message(FATAL_ERROR "Value \"${VALUE}\" of the variable ${NAME} not in choices ${CHOICES_LIST}")
		endif()
		return() #OK
	endif()
endfunction()

function(_read_variables_from_args __PARS __ARGS __OUT_ARGS ${ARGN})
	set(__OPTIONS)
	set(__oneValueArgs )
	set(__multiValueArgs)
	
	foreach(__PAR IN LISTS ${__PARS}__LIST)
		if("${${__PARS}_${__PAR}__CONTAINER}" STREQUAL "OPTION")
			list(APPEND __OPTIONS ${__PAR})
		elseif("${${__PARS}_${__PAR}__CONTAINER}" STREQUAL "SCALAR")
			list(APPEND __oneValueArgs ${__PAR})
		elseif("${${__PARS}_${__PAR}__CONTAINER}" STREQUAL "VECTOR")
			list(APPEND __multiValueArgs ${__PAR})
		else()
			message(FATAL_ERROR "Wrong type of container (${__PARS}_${__PAR}__CONTAINER = ${${__PARS}_${__PAR}__CONTAINER}) for variable ${__PAR}")
		endif()
	endforeach()
	
	cmake_parse_arguments(__PARSED "${__OPTIONS}" "${__oneValueArgs}" "${__multiValueArgs}" ${ARGN})
#	message(STATUS "_read_variables_from_args(): __multiValueArgs:${__multiValueArgs}")
	set(__unparsed ${__PARSED_UNPARSED_ARGUMENTS})
	if(__unparsed)
		message(FATAL_ERROR "Undefined variables passed as arguments: ${__unparsed} (all variables: ${ARGN})")
	endif()
	foreach(__OPTION IN LISTS __OPTIONS)
		if(NOT __PARSED_${__OPTION})
			unset(__PARSED_${__OPTION})
		endif()
	endforeach()
#	message(FATAL_ERROR "${__ARGS}__LIST: ${${__ARGS}__LIST}")
	_read_variables_from_cache(${__PARS} ${__ARGS} __PARSED args __IN_ARGS)
#	message(STATUS "_read_variables_from_args(): __IN_ARGS__SRC_BCTYPE: ${__IN_ARGS__SRC_BCTYPE}")
#	message(FATAL_ERROR "__IN_ARGS__LIST: ${__IN_ARGS__LIST}")
	_pass_arguments_higher(__IN_ARGS ${__OUT_ARGS})
endfunction()

