macro(_parse_all_external_info __EXTERNAL_INFO __OUT_PREFIX)
	set(__OPTIONS ASSUME_INSTALLED LINK_TO_DEPENDEE)
	set(__oneValueArgs SOURCE_PATH INSTALL_PATH NAME EXPORTED_TARGETS_PATH)
	set(__multiValueArgs WHAT_COMPONENTS_NAME_DEPENDS_ON COMPONENTS BUILD_PARAMETERS APT_PACKAGES SPACK_PACKAGES)
	
	cmake_parse_arguments(${__OUT_PREFIX} "${__OPTIONS}" "${__oneValueArgs}" "${__multiValueArgs}" ${${__EXTERNAL_INFO}})
	set(__unparsed ${__PARSED_UNPARSED_ARGUMENTS})
	if(__unparsed)
		message(FATAL_ERROR "Undefined options for external project: ${__unparsed}. All options: ${__EXTERNAL_INFO}")
	endif()
endmacro()

function(_parse_external_info __EI __TARGETS_CMAKE_PATH __PROPERTY __OUT)
	_parse_all_external_info(${__EI} ___P)
#	message(STATUS "_parse_external_info(): __EI: ${__EI}: ${${__EI}}")
	if(NOT ${__PROPERTY} IN_LIST __OPTIONS AND NOT ${__PROPERTY} IN_LIST __oneValueArgs AND NOT ${__PROPERTY} IN_LIST __multiValueArgs)
		message(FATAL_ERROR "Internal Beetroot error: property name ${__PROPERTY} is not valid for external project options in file ${__TARGETS_CMAKE_PATH}")
	endif()
	set(${__OUT} "${___P_${__PROPERTY}}" PARENT_SCOPE)
#	message(STATUS "_parse_external_info(): setting ${__OUT}: ${___P_${__PROPERTY}}")
endfunction()

#`_get_target_external(<TEMPLATE_NAME> <var_dictionary> <out_instance_name> <EXTERNAL_PROJECT_ARGS>)`

#2. Jeśli etap SUPERBUILD - Wywołuje `ExternalProject_Add` dla nazwy targetu policzonej na `var_dictionary` i zwraca tą nazwę targetu w `out_instance_name`
#3. Jeśli etap naszego projektu - wywołuje `find_packages`, tworzy alias dla importowanego targetu i zwraca nazwę `INSTANCE_NAME`.

# Pass empty __HASH if the external project does not support multiple instances (because the targets names are fixed)
function(_get_target_external __INSTANCE_ID __DEP_TARGETS)
	_retrieve_instance_data(${__INSTANCE_ID} EXTERNAL_INFO __EXTERNAL_INFO) 
	_parse_all_external_info(__EXTERNAL_INFO __PARSED)
	
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
	
	if(__PARSED_INSTALL_PATH)
		get_filename_component(__OVERRIDE_INSTALL_DIR "${__PARSED_INSTALL_PATH}" REALPATH BASE_DIR "${SUPERBUILD_ROOT}")
	endif()
	
	_workout_install_dir_for_external(${__INSTANCE_ID} "${__PARSED_WHAT_COMPONENTS_NAME_DEPENDS_ON}" "${__EXTERNAL_BARE_NAME}"  "${__PARSED_INSTALL_PATH}" __INSTALL_DIR_STEM __INSTALL_DIR __BUILD_DIR __FEATUREFILETMP)
#	message(STATUS "_get_target_external(): __BUILD_DIR: ${__BUILD_DIR} __FEATUREFILETMP: ${__FEATUREFILETMP} __INSTALL_DIR: ${__INSTALL_DIR} __INSTALL_DIR_STEM: ${__INSTALL_DIR_STEM}")
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)

	_make_instance_name(${__INSTANCE_ID} __INSTANCE_NAME)
	
#	message(STATUS "_get_target_external(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH}")
#	message(STATUS "_get_target_external(): Setting INSTALL_DIR: ${__INSTALL_DIR} on __PATH_HASH: ${__PATH_HASH}")
	if(NOT __PARSED_ASSUME_INSTALLED)
		_retrieve_instance_data(${__INSTANCE_ID} F_PATH __TARGETS_CMAKE_PATH)
		_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH) 
		_set_property_to_db(FILEDB ${__PATH_HASH} SOURCE_DIR ${__PARSED_SOURCE_PATH})
		_set_property_to_db(FILEDB ${__PATH_HASH} INSTALL_DIR ${__INSTALL_DIR})
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
				PREFIX ${__PARSED_SOURCE_PATH}
				${__DEP_STR}
				SOURCE_DIR ${__PARSED_SOURCE_PATH}
				TMP_DIR ${__BUILD_DIR}/tmp
				STAMP_DIR ${__BUILD_DIR}/timestamps
				DOWNLOAD_DIR ${SUPERBUILD_ROOT}/build/download
				BINARY_DIR ${__BUILD_DIR}
				INSTALL_DIR ${__INSTALL_DIR}
				CMAKE_ARGS ${__CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${__INSTALL_DIR}
			)
			ExternalProject_Add_Step("${__INSTANCE_NAME_FIXED}" postinstall
				COMMAND           mkdir -p "${__INSTALL_DIR_STEM}"
				COMMAND           mv "${__FEATUREFILETMP}" "${__INSTALL_DIR_STEM}/${__FEATUREBASE_ID}.cmake"
				COMMENT           "Commiting the external build"
				ALWAYS            TRUE
				EXCLUDE_FROM_MAIN FALSE
			)
#			message(STATUS "_get_target_external(): Setting external project ${__INSTANCE_NAME_FIXED} with the following arguments: ${__CMAKE_ARGS}")
			_add_property_to_db(GLOBAL ALL EXTERNAL_DEPENDENCIES "${__INSTANCE_NAME}") 
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

#Writes a temporary file to the binary directory that lists the features and modifiers of the external project
function(_external_prepare_feature_file __FILENAME __FEATUREBASE_ID __PATH_HASH __INSTALL_DIR __BUILD_DIR __MODIFIERS __FEATURES)
	file(WRITE "${__FILENAME}" "set(__${__PATH_HASH}_SERIALIZED_MODIFIERS ${${__MODIFIERS}})\n")
	file(APPEND "${__FILENAME}" "set(__${__PATH_HASH}_MODIFIERS_HASH ${__FEATUREBASE_ID})\n")
	file(APPEND "${__FILENAME}" "set(__${__PATH_HASH}_SERIALIZED_FEATURES ${${__FEATURES}})\n")
	file(APPEND "${__FILENAME}" "set(__${__PATH_HASH}_INSTALL_DIR ${__INSTALL_DIR})\n")
	file(APPEND "${__FILENAME}" "set(__${__PATH_HASH}_BUILD_DIR ${__INSTALL_DIR})\n")
	file(APPEND "${__FILENAME}" "list(APPEND __${__FEATUREBASE_ID}__LIST ${__PATH_HASH})\n")
endfunction()

macro(_get_existing_targets __INSTALL_DIR_STEM __PATH_HASH)
	file(GLOB __FILE_LIST LIST_DIRECTORIES false "${__INSTALL_DIR_STEM}/*.cmake")
	set(${__PATH_HASH}__LIST)
	foreach(__FILE IN LISTS __FILE_LIST)
		include("${__FILE}" OPTIONAL RESULT_VARIABLE __FILE_LOADED)
		if("${__FILE_LOADED}" STREQUAL "NOTFOUND")
			message(FATAL_ERROR "Internal beetroot error: cannot find \"${__FILE}\" using GLOB.")
		endif()
	endforeach()
endmacro()

#Function conjoures an install directory for the external project based on its modifiers, features and a list
#of already installed versions, to avoid building project when a compatible version may already be installed
function(_workout_install_dir_for_external __INSTANCE_ID __WHAT_COMPONENTS_NAME_DEPENDS_ON __EXTERNAL_BARE_NAME __OVERRIDE_INSTALL_DIR __OUT_INSTALL_STEM __OUT_INSTALL_DIR __OUT_BUILD_DIR __OUT_FEATUREBASETMP)
	# Get the stem of the installation dir - a folder with all the system-dependend prefixes that
	#   define the version of all the manually typed dependencies
	_retrieve_instance_data(${__INSTANCE_ID} F_PATH __TARGETS_CMAKE_PATH)
	_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH) 
#	message(STATUS "_workout_install_dir_for_external(): __INSTANCE_ID: ${__INSTANCE_ID} __WHAT_COMPONENTS_NAME_DEPENDS_ON: ${__WHAT_COMPONENTS_NAME_DEPENDS_ON}")
	name_external_project("${__WHAT_COMPONENTS_NAME_DEPENDS_ON}" "${__EXTERNAL_BARE_NAME}" __EXTERNAL_NAME)
	set(${__OUT_INSTALL_STEM} "${SUPERBUILD_ROOT}/install/${__EXTERNAL_NAME}" PARENT_SCOPE)
	set(__BUILD_DIR  "${SUPERBUILD_ROOT}/build/${__EXTERNAL_NAME}/${__FEATUREBASE_ID}")
#	message(STATUS "_workout_install_dir_for_external(): __BUILD_DIR: ${__BUILD_DIR}")
	set(${__OUT_BUILD_DIR} "${__BUILD_DIR}" PARENT_SCOPE)
	
	if(__OVERRIDE_INSTALL_DIR)
		get_filename_component(__FORCED_INSTALL_DIR "${__OVERRIDE_INSTALL_DIR}" REALPATH BASE_DIR "${SUPERBUILD_ROOT}")
#		message(STATUS "_workout_install_dir_for_external(): __OVERRIDE_INSTALL_DIR: ${__OVERRIDE_INSTALL_DIR}")
	else()

		# Prepare our identification
		_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)
		_retrieve_instance_pars(${__INSTANCE_ID} __PARS)
		_retrieve_instance_args(${__INSTANCE_ID} I_FEATURES __OUR_ARGS)
	
		# Get the list of all features
		_get_existing_targets("${SUPERBUILD_ROOT}/install/${__EXTERNAL_NAME}" "${__PATH_HASH}")
# 		message(STATUS "_workout_install_dir_for_external(): ${__FEATUREBASE_ID}__LIST: ${${__FEATUREBASE_ID}__LIST}")
	
		if(${__FEATUREBASE_ID}__LIST)
			foreach(__INSTALLED_EXTERNAL IN LISTS __${__FEATUREBASE_ID}__LIST)
				_unserialize_variables("${__${__FEATUREBASE_ID}_SERIALIZED_FEATURES}" __THEIR_ARGS)
				_compare_featuresets(${__PATH_HASH} __PARS __OUR_ARGS __THEIR_ARGS __OUT_RELATION)
#				message(STATUS "_workout_install_dir_for_external(): __INSTANCE_ID: ${__INSTANCE_ID} __OUT_RELATION: ${__OUT_RELATION}")

				if(${__OUT_RELATION} STRRQUAL 0 OR ${__OUT_RELATION} STRRQUAL 2)
					set(${__OUT_INSTALL_DIR} "${__${__FEATUREBASE_ID}_INSTALL_DIR}" PARENT_SCOPE)
					set(${__OUT_FEATUREBASETMP} "" PARENT_SCOPE)
					return()
				endif()
			endforeach()
		endif()
		#We could not find an existing project so we set the install dir ourselves
		set(__INSTALL_DIR "${SUPERBUILD_ROOT}/install/${__EXTERNAL_NAME}/${__FEATUREBASE_ID}")
#		message(STATUS "_workout_install_dir_for_external(): __INSTANCE_ID: ${__INSTANCE_ID} __INSTALL_DIR: ${__INSTALL_DIR}")
	endif()
	
	#Prepare the feature file, so other calls to the external project could find us
	_retrieve_instance_data(${__INSTANCE_ID} I_FEATURES __SERIALIZED_FEATURES)
	_retrieve_instance_data(${__INSTANCE_ID} MODIFIERS __SERIALIZED_MODIFIERS)
#	message(STATUS "_workout_install_dir_for_external(): __SERIALIZED_MODIFIERS: ${__SERIALIZED_MODIFIERS}")
	set(__FEATUREFILETMP "${SUPERBUILD_ROOT}/build/${__FEATUREBASE_ID}.cmake")
#	message(STATUS "_workout_install_dir_for_external(): __INSTANCE_ID: ${__INSTANCE_ID} __SERIALIZED_MODIFIERS: ${__SERIALIZED_MODIFIERS}")

	_external_prepare_feature_file("${__FEATUREFILETMP}" "${__FEATUREBASE_ID}" "${__PATH_HASH}" "${__INSTALL_DIR}" "${__BUILD_DIR}" __SERIALIZED_MODIFIERS __SERIALIZED_FEATURES)
	set(${__OUT_INSTALL_DIR} "${__INSTALL_DIR}" PARENT_SCOPE)
	set(${__OUT_FEATUREBASETMP} "${__FEATUREFILETMP}" PARENT_SCOPE)
endfunction()
