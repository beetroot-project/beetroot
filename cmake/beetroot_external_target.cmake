macro(_parse_all_external_info __EXTERNAL_INFO__REF __OUT_PREFIX)
	set(__OPTIONS ASSUME_INSTALLED LINK_TO_DEPENDEE)
	set(__oneValueArgs SOURCE_PATH INSTALL_PATH NAME EXPORTED_TARGETS_PATH)
	set(__multiValueArgs WHAT_COMPONENTS_NAME_DEPENDS_ON COMPONENTS BUILD_PARAMETERS APT_PACKAGES SPACK_PACKAGES)
	
	cmake_parse_arguments("${__OUT_PREFIX}" "${__OPTIONS}" "${__oneValueArgs}" "${__multiValueArgs}" ${${__EXTERNAL_INFO__REF}__LIST})
#	message(STATUS "${__PADDING}_parse_all_external_info(): __EXTERNAL_INFO__REF: ${__EXTERNAL_INFO__REF}")
#	message(WARNING "${__PADDING}_parse_all_external_info(): ${__EXTERNAL_INFO__REF}__LIST: ${${__EXTERNAL_INFO__REF}__LIST}")
#	message(STATUS "${__PADDING}_parse_all_external_info(): cmake_parse_arguments(\"${__OUT_PREFIX}\" \"${__OPTIONS}\" \"${__oneValueArgs}\" \"${__multiValueArgs}\" ${${__EXTERNAL_INFO__REF}__LIST})")
	set(__unparsed ${__PARSED_UNPARSED_ARGUMENTS})
	if(__unparsed)
		message(FATAL_ERROR "Undefined options for external project: ${__unparsed}. All options: ${${__EXTERNAL_INFO__REF}__LIST}")
	endif()
endmacro()

function(_parse_external_info __EXTERNAL_INFO__REF __TARGETS_CMAKE_PATH __PROPERTY __OUT)
	_parse_all_external_info(${__EXTERNAL_INFO__REF} ___P)
#	message(STATUS "_parse_external_info(): __EXTERNAL_INFO__REF: ${__EXTERNAL_INFO__REF}: ${${__EXTERNAL_INFO__REF}__LIST}")
	if(NOT ${__PROPERTY} IN_LIST __OPTIONS AND NOT ${__PROPERTY} IN_LIST __oneValueArgs AND NOT ${__PROPERTY} IN_LIST __multiValueArgs)
		message(FATAL_ERROR "Internal Beetroot error: property name ${__PROPERTY} is not valid for external project options in file ${__TARGETS_CMAKE_PATH}")
	endif()
	set(${__OUT} "${___P_${__PROPERTY}}" PARENT_SCOPE)
#	message(STATUS "_parse_external_info(): setting ${__OUT}: ${___P_${__PROPERTY}}")
endfunction()

#`_get_target_external(<TEMPLATE_NAME> <var_dictionary> <out_instance_name> <EXTERNAL_PROJECT_ARGS>)`
# The function gets called only when there is EXTERNAL_PROJECT_INFO during the superbuild phase.
# On superbuild phase it calls ExternalProject_Add, otherwise makes sure there is `apply_dependency_to_target` user function to call.

# __DEP_TARGETS contains a list of other external projects this project depends on
function(_get_target_external __INSTANCE_ID __DEP_TARGETS)
#	message(STATUS "_get_target_external(): first entry __INSTANCE_ID: ${__INSTANCE_ID}, because it depends on ${__DEP_TARGETS}")
	message("${__MESSAGE}")
	if(__ERROR)
		_debug_show_instance(${__INSTANCE_ID} 2 "EXTERNAL_TARGET: " __MESSAGE __ERROR)
		message(FATAL_ERROR "${__ERROR}")
	endif()


	_retrieve_instance_data(${__INSTANCE_ID} EXTERNAL_INFO __EXTERNAL_INFO__LIST) 
	_parse_all_external_info(__EXTERNAL_INFO __PARSED)
	
	if(NOT __PARSED_SOURCE_PATH AND NOT __PARSED_ASSUME_INSTALLED)
		message(FATAL_ERROR "External project must name PATH or be ASSUME_INSTALLED")
	else()
		get_filename_component(__PARSED_SOURCE_PATH "${__PARSED_SOURCE_PATH}" REALPATH BASE_DIR "${SUPERBUILD_ROOT}")
	endif()
	
	if(__DEP_TARGETS)
		set(__DEP_STR "DEPENDS ${__DEP_TARGETS}")
	else()
		set(__DEP_STR )
	endif()
	
	_retrieve_instance_data(${__INSTANCE_ID} PATH __TARGETS_CMAKE_PATH) 
		
	_workout_install_dir_for_external(${__INSTANCE_ID} "${__PARSED_INSTALL_PATH}" __INSTALL_DIR __INSTALL_DIR_STEM __BUILD_DIR __FEATUREFILETMP __FEATURES __MODIFIERS __EXTERNAL_ID __REUSED_EXISTING)
	if("${__INSTALL_DIR_STEM}" STREQUAL "")
	   message(FATAL_ERROR "We need to cache those data")
	endif()
#	message(STATUS "_get_target_external(): __BUILD_DIR: ${__BUILD_DIR} __FEATUREFILETMP: ${__FEATUREFILETMP} __INSTALL_DIR: ${__INSTALL_DIR} __INSTALL_DIR_STEM: ${__INSTALL_DIR_STEM}")
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)

	_make_instance_name(${__INSTANCE_ID} __INSTANCE_NAME)
	
#	message(STATUS "_get_target_external(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH}")
	if(NOT __PARSED_ASSUME_INSTALLED)
#		message(STATUS "_get_target_external(): Setting INSTALL_DIR: ${__INSTALL_DIR} on __PATH_HASH: ${__PATH_HASH} __PARSED_SOURCE_PATH: ${__PARSED_SOURCE_PATH}")
		_retrieve_instance_data(${__INSTANCE_ID} F_PATH __TARGETS_CMAKE_PATH)
		_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH) 
		_set_property_to_db(FILEDB ${__PATH_HASH} SOURCE_DIR ${__PARSED_SOURCE_PATH})
		_retrieve_file_data(${__PATH_HASH} INSTALL_DIR __TMP_INSTALL_DIR)
		if(NOT "${__TMP_INSTALL_DIR}" STREQUAL "" )
			if(NOT "${__TMP_INSTALL_DIR}" STREQUAL "${__INSTALL_DIR}")
				message(FATAL_ERROR "Hash of the installation path of the external project has changed from old ${__TMP_INSTALL_DIR} to ${__INSTALL_DIR}. This may be likely because you may have changed the set of parameters of this external project. If that is the case, simply remove path ${__INSTALL_DIR} and ${__BUILD_DIR}.")
			endif()
		endif()
		_set_property_to_db(FILEDB ${__PATH_HASH} INSTALL_DIR ${__INSTALL_DIR})
	endif()
#	message(STATUS "_get_target_external(): Going to add external project for ${__TEMPLATE_NAME} defined in the path ${__TEMPLATE_DIR}. We expect it will generate a target ${__INSTANCE_NAME}. The project will be installed in ${__INSTALL_DIR}")
	if(NOT __NOT_SUPERBUILD)
		if(NOT __PARSED_ASSUME_INSTALLED AND NOT __REUSED_EXISTING)
			string(REPLACE "::" "_" __INSTANCE_NAME_FIXED ${__INSTANCE_NAME})

			_retrieve_instance_args(${__INSTANCE_ID} F_FEATURES __ARGS)
			
			_debug_show_instance(${__INSTANCE_ID} 2 "EXTERNAL " __MSG __ERRORS)
			if(__ERRORS)
				message(STATUS "Error when constructing: ${__MSG}")
				message(FATAL_ERROR ${__ERRORS})
			endif()
			
			
			
			_retrieve_instance_data(${__INSTANCE_ID} F_FEATURES __SERIALIZED_FEATURES)
#			message(STATUS "_get_target_external(): 1 __INSTANCE_NAME: ${__INSTANCE_NAME} __FEATUREBASE_ID: ${__FEATUREBASE_ID} __SERIALIZED_FEATURES: ${__SERIALIZED_FEATURES}")
			set(__ARGS__LIST_FEATURES "${__ARGS__LIST}")
			_retrieve_instance_args(${__INSTANCE_ID} MODIFIERS __ARGS)
			set(__ARGS__LIST_MODIFIERS "${__ARGS__LIST}")
			list(APPEND __ARGS__LIST ${__ARGS__LIST_FEATURES})
			if(__PARSED_BUILD_PARAMETERS)
				foreach(__PAR IN LISTS __PARSED_BUILD_PARAMETERS)
					if(NOT "${__PAR}" IN_LIST __ARGS__LIST)
						message(FATAL_ERROR "Cannot find ${__PAR} among list of declared BUILD_PARAMETERS and BUILD_FEATURES. Remove ${__PAR} from BUILD_PARAMETERS in DEFINE_EXTERNAL_PROJECT.")
					endif()
				endforeach()
				set(__ARGS__LIST ${__PARSED_BUILD_PARAMETERS})
			endif()
			_retrieve_instance_pars(${__INSTANCE_ID} __PARS)
			_make_cmake_args(__PARS __ARGS "${__ARGS__LIST}" __CMAKE_ARGS)
			message(STATUS "External project ${__INSTANCE_NAME_FIXED} will be compiled with parameters: ${__CMAKE_ARGS}")
			ExternalProject_Add("${__INSTANCE_NAME_FIXED}" 
				PREFIX ${__PARSED_SOURCE_PATH}
				${__DEP_STR}
				SOURCE_DIR ${__PARSED_SOURCE_PATH}
				TMP_DIR ${__BUILD_DIR}/tmp
				STAMP_DIR ${__BUILD_DIR}/timestamps
				DOWNLOAD_DIR ${BEETROOT_BUILD_DIR}/download
				BINARY_DIR ${__BUILD_DIR}
				INSTALL_DIR ${__INSTALL_DIR}
				CMAKE_ARGS ${__CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${__INSTALL_DIR}
			)
			if(NOT "${__FEATUREFILETMP}" STREQUAL "")
#				message(STATUS "_get_target_external(): mv \"${__FEATUREFILETMP}\" \"${__INSTALL_DIR_STEM}/${__FEATUREBASE_ID}.cmake\"")
				ExternalProject_Add_Step("${__INSTANCE_NAME_FIXED}" postinstall
					COMMAND           mkdir -p "${__INSTALL_DIR_STEM}"
					COMMAND           cp "${__FEATUREFILETMP}" "${__INSTALL_DIR_STEM}/${__EXTERNAL_ID}.cmake"
					COMMENT           "Commiting the external build"
					ALWAYS            TRUE
					EXCLUDE_FROM_MAIN FALSE
				)
			endif()
#			message(STATUS "_get_target_external(): 2 Setting external project ${__INSTANCE_NAME_FIXED} with the following arguments: ${__CMAKE_ARGS}")
			_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} TARGET_BUILT 1)
		else()
		   if(__PARSED_ASSUME_INSTALLED)
	   		_add_property_to_db(GLOBAL ALL EXTERNAL_TARGETS "${__INSTANCE_NAME}") 
	   	endif()

			if(__REUSED_EXISTING)
				message(STATUS "External dependency ${__INSTANCE_NAME} (${__FEATUREBASE_ID}) is already compiled in subdirectory ${__EXTERNAL_ID} with compatible arguments ${__FEATURES}")
			endif()
		endif()
	else()
		message(FATAL_ERROR "This code should not be reachable!")
#		message(STATUS "_get_target_external(): 3 __EXTERNAL_BARE_NAME: ${__EXTERNAL_BARE_NAME} __INSTANCE_NAME: ${__INSTANCE_NAME} __TEMPLATE_NAME: ${__TEMPLATE_NAME} ${__INSTANCE_NAME}_DIR: ${${__INSTANCE_NAME}_DIR}")
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
#		message(STATUS "_get_target_external(): find_package(${__EXTERNAL_BARE_NAME} ${__PATHS} ${__COMPONENTS})")
		find_package(${__EXTERNAL_BARE_NAME} ${__PATHS} ${__COMPONENTS}  )
		if(NOT TARGET ${__INSTANCE_NAME} AND NOT __NO_TARGETS)
			_get_nice_instance_name(${__INSTANCE_ID} __DESCRIPTION)
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
function(_external_prepare_feature_file __FILENAME __FEATUREBASE_ID __EXTERNAL_ID __INSTALL_DIR __BUILD_DIR __MODIFIERS__REF __FEATURES__REF __EXTERNAL_ID_SOURCE)
#	message(STATUS "_external_prepare_feature_file(): ${__FEATURES__REF}__LIST: ${${__FEATURES__REF}__LIST}")
	file(WRITE "${__FILENAME}" "set(__${__EXTERNAL_ID}_SERIALIZED_MODIFIERS__LIST ${${__MODIFIERS__REF}__LIST})\n")
#	file(APPEND "${__FILENAME}" "set(__${__EXTERNAL_ID}_MODIFIERS_HASH ${__FEATUREBASE_ID})\n")
	file(APPEND "${__FILENAME}" "set(__${__EXTERNAL_ID}_SERIALIZED_FEATURES__LIST ${${__FEATURES__REF}__LIST})\n")
	file(APPEND "${__FILENAME}" "set(__${__EXTERNAL_ID}_INSTALL_DIR \"${__INSTALL_DIR}\")\n")
	file(APPEND "${__FILENAME}" "set(__${__EXTERNAL_ID}_BUILD_DIR \"${__INSTALL_DIR}\")\n")
	if(NOT "${__EXTERNAL_ID_SOURCE}" STREQUAL "")
		file(APPEND "${__FILENAME}" "set(__${__EXTERNAL_ID}_HASH_SOURCE \"${__EXTERNAL_ID_SOURCE}\")\n")
	endif()
	file(APPEND "${__FILENAME}" "list(APPEND __${__FEATUREBASE_ID}__LIST ${__EXTERNAL_ID})\n")
endfunction()

# loads all installed versions of the external dependency with the given prefix __INSTALL_DIR_STEM.
# After invoking this macro, a new elements will be added to lists __<featurebase_id>__LIST for each
# found installed version of the external dependency that contain its EXTERNAL_ID.
# User then can query the features of that dependency by inspecting __<EXTERNAL_ID>_[SERIALIZED_FEATURES__LIST; SERIALIZED_MODIFIERS__LIST; INSTALL_DIR; BUILD_DIR; HASH_SOURCE]
macro(_get_existing_targets __INSTALL_DIR_STEM __PATH_HASH)
	file(GLOB __FILE_LIST LIST_DIRECTORIES false "${__INSTALL_DIR_STEM}/*.cmake")
	set(${__PATH_HASH}__LIST)
#	message(STATUS "${__PADDING}_get_existing_targets(): ${__INSTALL_DIR_STEM}/*.cmake __FILE_LIST: ${__FILE_LIST}")
	foreach(__FILE IN LISTS __FILE_LIST)
		get_filename_component(__INSTALL_UPDIR "${__FILE}" DIRECTORY)
		get_filename_component(__INSTALL_NAME "${__FILE}" NAME_WE)
		#Check if the install subdirectory with that hash really exists and is not empty
		file(GLOB __ANY_FILE LIST_DIRECTORIES true "${__INSTALL_UPDIR}/${__INSTALL_NAME}/*")
#		message(STATUS "${__PADDING}_get_existing_targets(): __FILE: ${__FILE}, ${__INSTALL_UPDIR}/${__INSTALL_NAME}/* -> __ANY_FILE: ${__ANY_FILE}")
		if(__ANY_FILE)
#			message(STATUS "${__PADDING}_get_existing_targets(): OK: __FILE: ${__FILE}")
			# Here we load the information about the installed library, so it can be decided whether it has compatible features
			include("${__FILE}" OPTIONAL RESULT_VARIABLE __FILE_LOADED)
			if("${__FILE_LOADED}" STREQUAL "NOTFOUND")
				message(FATAL_ERROR "Internal beetroot error: cannot find \"${__FILE}\" using GLOB.")
			endif()
		else()
#			message(STATUS "${__PADDING}_get_existing_targets(): BAD: __FILE: ${__INSTALL_UPDIR}/${__INSTALL_NAME}")
			file(REMOVE "${__FILE}")
#			file(REMOVE_RECURSE "${__INSTALL_UPDIR}/${__INSTALL_NAME}")
#			message(FATAL_ERROR "Check file")
		endif()
#		message(STATUS "${__PADDING}_get_existing_targets(): loaded ${__FILE}")
	endforeach()
endmacro()

#Function makes a path to the install directory for the external project based on its modifiers, features and a list
#of already installed versions, to avoid building project when a compatible version may already be installed
function(_workout_install_dir_for_external __INSTANCE_ID __OVERRIDE_INSTALL_DIR __OUT_INSTALL_DIR __OUT_INSTALL_STEM __OUT_BUILD_DIR __OUT_FEATUREBASETMP __OUT_FEATURES __OUT_MODIFIERS __OUT_EXTERNAL_ID __OUT_REUSE_EXISTING)
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)
   _retrieve_featurebase_data(${__FEATUREBASE_ID} INSTALL_PATH __INSTALL_DIR)
   if(NOT "${__INSTALL_DIR}" STREQUAL "")
      set(${__OUT_INSTALL_DIR} "${__INSTALL_DIR}" PARENT_SCOPE)
      set(${__OUT_INSTALL_STEM} "" PARENT_SCOPE)
#	   set(${__OUT_FEATUREBASETMP} "${__FEATUREFILETMP}" PARENT_SCOPE)
#	   set(${__OUT_REUSE_EXISTING} 0 PARENT_SCOPE)
#	   _set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} INSTALL_PATH "${__INSTALL_DIR}" FORCE)      
	   return()
   endif()
#   message(WARNING "${__PADDING}_workout_install_dir_for_external for ${__INSTANCE_ID}")

	if(__OVERRIDE_INSTALL_DIR)
		get_filename_component(__OVERRIDE_INSTALL_DIR "${__OVERRIDE_INSTALL_DIR}" REALPATH BASE_DIR "${SUPERBUILD_ROOT}")
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} MODIFIERS __SERIALIZED_MODIFIERS__LIST)
	set(${__OUT_MODIFIERS} "${__SERIALIZED_MODIFIERS__LIST}" PARENT_SCOPE)

	# Get the stem of the installation dir - a folder with all the system-dependend prefixes that
	#   define the version of all the manually typed dependencies
	_retrieve_instance_data(${__INSTANCE_ID} F_PATH __TARGETS_CMAKE_PATH)
	_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH) 
#	message(STATUS "${__PADDING}_workout_install_dir_for_external(): __INSTANCE_ID: ${__INSTANCE_ID} __WHAT_COMPONENTS_NAME_DEPENDS_ON: ${__WHAT_COMPONENTS_NAME_DEPENDS_ON}")
#	message(WARNING "${__PADDING}_workout_install_dir_for_external(): __INSTANCE_ID: ${__INSTANCE_ID} __EXTERNAL_BARE_NAME: ${__EXTERNAL_BARE_NAME}")
	_name_external_project(${__INSTANCE_ID} __EXTERNAL_NAME)
#	message("${__PADDING}_workout_install_dir_for_external(): __EXTERNAL_NAME: ${__EXTERNAL_NAME}")
#	message(STATUS "_name_external_project(): __INSTANCE_ID: ${__INSTANCE_ID} __EXTERNAL_NAME: ${__EXTERNAL_NAME}")
#	message(STATUS "${__PADDING}_workout_install_dir_for_external(): entry for __INSTANCE_ID: ${__INSTANCE_ID} __WHAT_COMPONENTS_NAME_DEPENDS_ON: ${__WHAT_COMPONENTS_NAME_DEPENDS_ON} __EXTERNAL_NAME: ${__EXTERNAL_NAME}")
	set(${__OUT_INSTALL_STEM} "${BEETROOT_EXTERNAL_INSTALL_DIR}/${__EXTERNAL_NAME}" PARENT_SCOPE)
#	message(STATUS "_name_external_project(): INSTALL_STEM: ${BEETROOT_EXTERNAL_INSTALL_DIR}/${__EXTERNAL_NAME}")
	
	# Generate hash of the external project based on the required modifiers and features
	_make_external_project_id(${__INSTANCE_ID} __EXTERNAL_ID __EXTERNAL_ID_SOURCE)
	set(${__OUT_EXTERNAL_ID} "${__EXTERNAL_ID}" PARENT_SCOPE)

	# Append this hash to the build (install dir may need special treatment becasue there may be a different version of the external project installed with compatible features)
	set(__BUILD_DIR  "${BEETROOT_BUILD_DIR}/${__EXTERNAL_NAME}/${__EXTERNAL_ID}")
#	message(STATUS "${__PADDING}_workout_install_dir_for_external(): __BUILD_DIR: ${__BUILD_DIR}")
	set(${__OUT_BUILD_DIR} "${__BUILD_DIR}" PARENT_SCOPE)
	
	if(__OVERRIDE_INSTALL_DIR)
		get_filename_component(__FORCED_INSTALL_DIR "${__OVERRIDE_INSTALL_DIR}" REALPATH BASE_DIR "${SUPERBUILD_ROOT}")
#		message(STATUS "${__PADDING}_workout_install_dir_for_external(): __OVERRIDE_INSTALL_DIR: ${__OVERRIDE_INSTALL_DIR}")
	else()

		# Prepare our identification - check if the installed version has compatible featuresets
		_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)
		_retrieve_instance_pars(${__INSTANCE_ID} __PARS)
		_retrieve_featurebase_args(${__FEATUREBASE_ID} F_FEATURES __OUR_ARGS)
		_retrieve_featurebase_data(${__FEATUREBASE_ID} F_FEATURES __SERIALIZED_OUR_ARGS__LIST)
#		message(STATUS "${__PADDING}_workout_install_dir_for_external(): __INSTANCE_ID: ${__INSTANCE_ID} __FEATUREBASE_ID: ${__FEATUREBASE_ID} __EXTERNAL_ID: ${__EXTERNAL_ID}...")
#		message(STATUS "${__PADDING}_workout_install_dir_for_external(): __FEATUREBASE_ID: ${__FEATUREBASE_ID} OUR_ARGS: ${__SERIALIZED_OUR_ARGS__LIST}")
	
		# Get the list of all installed versions that maybe compatible with our requirement
		_get_existing_targets("${BEETROOT_EXTERNAL_INSTALL_DIR}/${__EXTERNAL_NAME}" "${__PATH_HASH}")
#		message(STATUS "${__PADDING}_workout_install_dir_for_external(): _get_existing_targets(\"${BEETROOT_EXTERNAL_INSTALL_DIR}/${__EXTERNAL_NAME}\" \"${__PATH_HASH}\")")
#		message(STATUS "${__PADDING}_workout_install_dir_for_external(): THEIR_ARGS: __${__FEATUREBASE_ID}__LIST: ${__${__FEATUREBASE_ID}__LIST}")
	
		if(__${__FEATUREBASE_ID}__LIST) # If we found at least one already installed external project...
			foreach(__INSTALLED_EXTERNAL IN LISTS __${__FEATUREBASE_ID}__LIST)
				_unserialize_variables(__${__INSTALLED_EXTERNAL}_SERIALIZED_FEATURES __THEIR_ARGS)
#				message(STATUS "${__PADDING}_workout_install_dir_for_external(): __THEIR_ARGS: ${__${__INSTALLED_EXTERNAL}_SERIALIZED_FEATURES__LIST}")
				# Check if the features of the installed version are compatible with ours
				_compare_featuresets(${__PATH_HASH} __PARS __OUR_ARGS __THEIR_ARGS __OUT_RELATION)
#				message(STATUS "${__PADDING}_workout_install_dir_for_external(): __INSTANCE_ID: ${__INSTANCE_ID} __OUT_RELATION: ${__OUT_RELATION}")

				if("${__OUT_RELATION}" STREQUAL "0" OR "${__OUT_RELATION}" STREQUAL "2") # If installed project
				# is compatible, then use it and exit this function
					set(${__OUT_INSTALL_DIR} "${__${__INSTALLED_EXTERNAL}_INSTALL_DIR}" PARENT_SCOPE)
#         		message(STATUS "${__PADDING}_workout_install_dir_for_external(): EXISTING __INSTANCE_ID: ${__INSTANCE_ID} ${__${__INSTALLED_EXTERNAL}_INSTALL_DIR}")
					set(${__OUT_FEATUREBASETMP} "" PARENT_SCOPE)
					set(${__OUT_FEATURES} "${__${__INSTALLED_EXTERNAL}_SERIALIZED_FEATURES__LIST}" PARENT_SCOPE)
					set(${__OUT_REUSE_EXISTING} 1 PARENT_SCOPE)
					set(${__OUT_EXTERNAL_ID} "${__INSTALLED_EXTERNAL}" PARENT_SCOPE)
					return()
				endif()
			endforeach()
		endif()
		# We could not find an existing project so we set the install dir ourselves - we append __EXTERNAL_ID to the installation 
		# directory the same way as we did for __BUILD_DIR
		set(__INSTALL_DIR "${BEETROOT_EXTERNAL_INSTALL_DIR}/${__EXTERNAL_NAME}/${__EXTERNAL_ID}")
#		message(STATUS "${__PADDING}_workout_install_dir_for_external(): __INSTANCE_ID: ${__INSTANCE_ID} __INSTALL_DIR: ${__INSTALL_DIR}")
#		message(STATUS "${__PADDING}_workout_install_dir_for_external(): BEETROOT_EXTERNAL_INSTALL_DIR: ${BEETROOT_EXTERNAL_INSTALL_DIR}, __EXTERNAL_NAME: ${__EXTERNAL_NAME}  __EXTERNAL_ID: ${__EXTERNAL_ID}")
	endif()
	
	#Prepare the feature file, so other calls to the external project could find us
	_retrieve_instance_data(${__INSTANCE_ID} F_FEATURES __SERIALIZED_FEATURES__LIST)
	set(${__OUT_FEATURES} "${__SERIALIZED_FEATURES__LIST}" PARENT_SCOPE)
#	message(STATUS "${__PADDING}_workout_install_dir_for_external(): __SERIALIZED_MODIFIERS: ${__SERIALIZED_MODIFIERS}")
	set(__FEATUREFILETMP "${BEETROOT_BUILD_DIR}/${__EXTERNAL_ID}.cmake")
#	message(STATUS "${__PADDING}_workout_install_dir_for_external(): __INSTANCE_ID: ${__INSTANCE_ID} __SERIALIZED_MODIFIERS: ${__SERIALIZED_MODIFIERS}")

	_external_prepare_feature_file("${__FEATUREFILETMP}" "${__FEATUREBASE_ID}" "${__EXTERNAL_ID}" "${__INSTALL_DIR}" "${__BUILD_DIR}" __SERIALIZED_MODIFIERS __SERIALIZED_FEATURES "${__EXTERNAL_ID_SOURCE}")
	set(${__OUT_INSTALL_DIR} "${__INSTALL_DIR}" PARENT_SCOPE)
	set(${__OUT_FEATUREBASETMP} "${__FEATUREFILETMP}" PARENT_SCOPE)
	set(${__OUT_REUSE_EXISTING} 0 PARENT_SCOPE)
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} INSTALL_PATH "${__INSTALL_DIR}" FORCE)
endfunction()

##Function returns name based on version string of the external dependencies
#function(_name_external_project __COMPONENTS __BASE_NAME __OUT_NAME)
#	string(TOLOWER ${__BASE_NAME} __PART1)
#	list(REMOVE_DUPLICATES __COMPONENTS)
#	list(SORT __COMPONENTS)
#	set(__PART2 )
#	foreach(__COMPONENT IN LISTS __COMPONENTS)
#	   message(STATUS "_name_external_project(): __COMPONENT: ${__COMPONENT}")
#		string(TOLOWER "${__COMPONENT}" __COMPONENT_SMALL)
#		string(TOUPPER "${__COMPONENT}" __COMPONENT_LARGE)
#		set(__COMPONENT_PLUGIN "${SUPERBUILD_ROOT}/cmake/build_install_prefix_plugins/${__COMPONENT_SMALL}.cmake")
#		include(${__COMPONENT_PLUGIN} OPTIONAL RESULT_VARIABLE __COMPONENT_STATUS)
#		if("${__COMPONENT_STATUS}" STREQUAL "NOTFOUND")
#			set(__COMPONENT_PLUGIN "${SUPERBUILD_ROOT}/cmake/beetroot/build_install_prefix_plugins/${__COMPONENT_SMALL}.cmake")
#			include(${__COMPONENT_PLUGIN} OPTIONAL RESULT_VARIABLE __COMPONENT_STATUS)
#			if("${__COMPONENT_STATUS}" STREQUAL "NOTFOUND")
#				message(FATAL_ERROR "Component plugin ${__COMPONENT_SMALL}.cmake was not found in ${SUPERBUILD_ROOT}/cmake/build_install_prefix_plugins/${__COMPONENT_SMALL}.cmake directory. It was required by the ${__BASE_NAME} external project definition.")
#			endif()
#		endif()
#		set(__PART2 "${__PART2}-${${__COMPONENT_LARGE}_VERSION_STRING}")
#	endforeach()
#	string(TOLOWER "${__PART2}" __PART2)
#	set(${__OUT_NAME} "${__PART1}${__PART2}" PARENT_SCOPE)
#endfunction()

#Function returns name based on version string of the external dependencies
function(_name_external_project __INSTANCE_ID __OUT_NAME)
   set(__ALL_DEPENDENCIES "")
#   message(STATUS "${__PADDING}_name_external_project() __INSTANCE_ID: ${__INSTANCE_ID}")
   _name_external_project_int("${__INSTANCE_ID}" __TMP_WHOLE_NAME __TMP_DEP)
#   message(STATUS "${__PADDING}_name_external_project() __TMP_DEP: ${__TMP_DEP}")   
   list(SORT __TMP_DEP)
   set(__OUT ${__TMP_WHOLE_NAME})
   foreach(__DEP_STR IN_LISTS("${__TMP_DEP}"))
      set(__OUT "${__OUT}-${__DEP_STR}")
   endforeach()
   set(${__OUT_NAME} "${__TMP_WHOLE_NAME}" PARENT_SCOPE)
endfunction()

#Function returns name based on version string of the external dependencies.
#Function relies on implicitely passed __ALL_DEPENDENCIES that contains a chain of all nested
#dependencies, and is used to track circular dependencies
function(_name_external_project_int __INSTANCE_ID __OUT_WHOLE_NAME __OUT_DEPENDENCIES)
#   message(STATUS "${__PADDING}_name_external_project_int() __INSTANCE_ID: ${__INSTANCE_ID} __ALL_DEPENDENCIES: ${__ALL_DEPENDENCIES}" )   
   if("${__INSTANCE_ID}" IN_LIST __ALL_DEPENDENCIES)
      _get_nice_instance_names(__ALL_DEPENDENCIES __NICE_LIST)
      message(FATAL_ERROR "Beetroot error: Circular dependencies encountered among external projects: ${__NICE_LIST}, ${__ALL_DEPENDENCIES}")
   endif()
   set(__ALL_DEPENDENCIES ${__ALL_DEPENDENCIES} ${__INSTANCE_ID})

	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)
	if("${__FEATUREBASE_ID}" STREQUAL "")
	   message(FATAL_ERROR "Beetroot error: External dependency ${__INSTANCE_ID} is a promise!")
   endif()
   
	_retrieve_instance_data(${__INSTANCE_ID} I_CHILDREN __DEPENDENCIES)
#   message(STATUS "${__PADDING}_name_external_project_int() __INSTANCE_ID: ${__INSTANCE_ID} __DEPENDENCIES: ${__DEPENDENCIES} __ALL_DEPENDENCIES: ${__ALL_DEPENDENCIES}" )   

   set(__EXTERNAL_DEPENDENCIES "") #List of all nested external dependencies
   if(__DEPENDENCIES)
#      set(__ALL_DEPENDENCIES_COPY "${__ALL_DEPENDENCIES}")
      foreach(__I_DEPENDENCY IN LISTS __DEPENDENCIES)
      	_retrieve_instance_data(${__I_DEPENDENCY} EXTERNAL_INFO __DEP_EXTERNAL_INFO)
      	if("${__DEP_EXTERNAL_INFO}" STREQUAL "")
      	   _get_nice_instance_name(${__INSTANCE_ID} __NICE_NAME)
      	   _get_nice_instance_name(${__I_DEPENDENCY} __NICE_NAME_DEP)
      	   message(FATAL_ERROR "Beetroot error: All dependencies external target can have must be external targets themselves. Target ${__NICE_NAME} depends on ${__NICE_NAME_DEP} which is not external.")
      	endif()
#         _name_external_project_int(${__I_DEPENDENCY} __DEP_NAME __IGNORE)
         list(APPEND __EXTERNAL_DEPENDENCIES ${__DEP_NAME})
      endforeach()
   endif()   
   set(${__OUT_DEPENDENCIES} "${__EXTERNAL_DEPENDENCIES}" PARENT_SCOPE)
   
   _find_base_name(${__INSTANCE_ID} __BASE_NAME)
   _retrieve_instance_data(${__INSTANCE_ID} T_PATH __TARGETS_CMAKE_PATH)
   _make_path_hash("${__TARGETS_CMAKE_PATH}" __FILE_HASH)
   _make_build_version_string(${__FILE_HASH} __VERSION_EXISTS __VERSION_STRING)
   if(NOT __VERSION_EXISTS)
      _get_nice_instance_name(${__INSTANCE_ID} __NICE_INSTANCE_NAME)
      message(FATAL_ERROR "Beetroot error: file defining external ${__NICE_INSTANCE_NAME} does not define its build_version_string() function. Each external dependency should define that in order to avoid stale versions when updating.")
   endif()
#   set(__BASE_NAME "${__BASE_NAME}_${__FEATUREBASE_ID}")

   if(NOT "${__VERSION_STRING}" STREQUAL "")
      set(__BASE_NAME "${__BASE_NAME}_${__VERSION_STRING}")
   endif()
   set(${__OUT_WHOLE_NAME} "${__BASE_NAME}" PARENT_SCOPE)
endfunction()

