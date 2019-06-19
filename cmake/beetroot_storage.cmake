#Function stores all entries to the filedb. 
function(_store_file __ARGS __PARS __TEMPLATE_NAME __TARGETS_CMAKE_PATH __IS_TARGET_FIXED __EXTERNAL_PROJECT_INFO__REF __TARGET_REQUIRED __TEMPLATE_OPTIONS__REF __ALL_TEMPLATE_NAMES __OUT_FILE_HASH __OUT_JOINED_TARGETS)
	_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH)
	set(${__OUT_FILE_HASH} "${__PATH_HASH}" PARENT_SCOPE)
	_retrieve_file_data(${__PATH_HASH} PATH __TARGETS_CMAKE_PATH_CHECK)
	if(__TARGETS_CMAKE_PATH_CHECK)
		return()
	endif()
#	message(STATUS "${__PADDING}_store_file() __PATH_HASH: ${__PATH_HASH} __ALL_TEMPLATE_NAMES: ${__ALL_TEMPLATE_NAMES}")

	_parse_file_options( "${__TARGETS_CMAKE_PATH}" ${__IS_TARGET_FIXED} ${__TEMPLATE_OPTIONS__REF} __SINGLETON_TARGETS __NO_TARGETS __LANGUAGES __NICE_NAME __EXPORTED_VARS __LINK_TO_DEPENDEE __DONT_LINK_TO_DEPENDEE __GENERATE_TARGETS_INCLUDE_LINKPARS __JOINED_TARGETS)
	if(__EXPORTED_VARS)
		foreach(__EVAR IN LISTS __EXPORTED_VARS)
			if(NOT "${__EVAR}" IN_LIST ${__PARS}__LIST)
				message(FATAL_ERROR "Cannot export a variable ${__EVAR} that is not defined as a parameter/feature (${__EXPORTED_VARS})")
			endif()
		endforeach()
	endif()
	if(${__EXTERNAL_PROJECT_INFO__REF}__LIST)
		set(__JOINT_TARGETS 1)
		_parse_external_info(${__EXTERNAL_PROJECT_INFO__REF} "${__TARGETS_CMAKE_PATH}" ASSUME_INSTALLED __ASSUME_INSTALLED)
	
		if(NOT __LINK_TO_DEPENDEE) #Merging LINK_to_DEPENDEE external option with the project option
			_parse_external_info(${__EXTERNAL_PROJECT_INFO__REF} "${__TARGETS_CMAKE_PATH}" LINK_TO_DEPENDEE __LINK_TO_DEPENDEE)
		endif()
		_parse_external_info(${__EXTERNAL_PROJECT_INFO__REF} "${__TARGETS_CMAKE_PATH}" NAME __JOINED_NAME)
	#		message(STATUS "${__PADDING}_store_instance_data(): __INSTANCE_ID: ${__INSTANCE_ID} __LINK_TO_DEPENDEE: ${__LINK_TO_DEPENDEE}")
	else()
		set(__ASSUME_INSTALLED 0)
	endif()
	_serialize_parameters(${__PARS} __SERIALIZED_PARAMETERS)
	if(__LINK_TO_DEPENDEE AND __DONT_LINK_TO_DEPENDEE)
		message(FATAL_ERROR "Beetroot semantic error: cannot set LINK_TO_DEPENDEE and DONT_LINK_TO_DEPENDEE in the same ${__TARGETS_CMAKE_PATH} together. ")
	endif()

	if(__JOINT_TARGETS)
#		_add_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_TEMPLATE_NAME       ${__TEMPLATE_NAME})
		_parse_external_info(${__EXTERNAL_PROJECT_INFO__REF} "${__TARGETS_CMAKE_PATH}" NAME __JOINED_NAME)
		if(__JOINED_NAME)
			list(APPEND __ALL_TEMPLATE_NAMES ${__JOINED_NAME})
		endif()
		set(${__OUT_JOINED_TARGETS} "${__JOINED_TARGETS}")
	else()
		set(__JOINED_NAME)
	endif()


	_set_property_to_db(FILEDB     ${__PATH_HASH} PATH                 "${__TARGETS_CMAKE_PATH}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} SINGLETON_TARGETS    "${__SINGLETON_TARGETS}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} TARGET_FIXED         "${__IS_TARGET_FIXED}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} NO_TARGETS           "${__NO_TARGETS}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} G_INSTANCES           "")
	_set_property_to_db(FILEDB     ${__PATH_HASH} G_FEATUREBASES        "")
	_set_property_to_db(FILEDB     ${__PATH_HASH} PARS                 "${__SERIALIZED_PARAMETERS}")
	
	if(__SERIALIZED_PARAMETERS)
		_retrieve_file_data(${__PATH_HASH} DEFAULTS __SERIALIZED_DEFAULTS)
		if(NOT __SERIALIZED_DEFAULTS)
			#We reset all the variables, so we can learn about the defaults
			foreach(__VAR IN LISTS ${__PARS}__LIST)
				set(${__VAR})
			endforeach()
			_get_variables("${__TARGETS_CMAKE_PATH}" "defaults" "" 0 __DEFAULTS __TMP_PARS __TMP_TEMPLATE_NAMES __TMP_EXTERNAL_PROJECT_INFO __TMP_IS_TARGET_FIXED __TMP_GLOBAL_OPTIONS)

			_instantiate_variables(__DEFAULTS __TMP_PARS "${__DEFAULTS__LIST}")
#			message(STATUS "${__PADDING}_store_file(): __TEMPLATE_NAME ${__TEMPLATE_NAME} DWARF: ${DWARF}")

			_serialize_variables(__DEFAULTS __DEFAULTS__LIST __SERIALIZED_DEFAULTS)
#			message(STATUS "${__PADDING}_store_instance_data(): __SERIALIZED_DEFAULTS: ${__SERIALIZED_DEFAULTS}")
		endif()
		_set_property_to_db(FILEDB     ${__PATH_HASH} DEFAULTS         "${__SERIALIZED_DEFAULTS}")
	else()
#		message(STATUS "${__PADDING}_store_file(): No serialized parameters for __TEMPLATE_NAME ${__TEMPLATE_NAME}")
	endif()
	_set_property_to_db(FILEDB     ${__PATH_HASH} EXTERNAL_INFO         "${${__EXTERNAL_PROJECT_INFO__REF}__LIST}")
	if(__JOINED_NAME)
		_set_property_to_db(FILEDB     ${__PATH_HASH} JOINED_NAME        "${__JOINED_NAME}")
	endif()
	_set_property_to_db(FILEDB     ${__PATH_HASH} TARGETS_REQUIRED       ${__TARGET_REQUIRED})
	_set_property_to_db(FILEDB     ${__PATH_HASH} G_TEMPLATES           "${__ALL_TEMPLATE_NAMES}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} LANGUAGES             "${__LANGUAGES}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} ASSUME_INSTALLED      "${__ASSUME_INSTALLED}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} NICE_NAME             "${__NICE_NAME}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} EXPORTED_VARS         "${__EXPORTED_VARS}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} JOINT_TARGETS         "${__JOINT_TARGETS}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} LINK_TO_DEPENDEE      "${__LINK_TO_DEPENDEE}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} DONT_LINK_TO_DEPENDEE "${__DONT_LINK_TO_DEPENDEE}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} GENERATE_TARGETS_INCLUDE_LINKPARS     "${__GENERATE_TARGETS_INCLUDE_LINKPARS}")	
	_set_property_to_db(FILEDB     ${__PATH_HASH} TEMPLATE_OPTIONS      "${__TEMPLATE_OPTIONS}")
	
endfunction()

#Each featurebase is a distinctly built set of targets (it may be more than one if the targets are joined as is often the case with external targets). 
#It may not know its all arguments, because part of them are features, that are known only after
#consolidating all instances of this featurebases and the relevant promises.
#
#Function sets the featurebase (and returns its ID). It does not make any connection between the featurebase and the instance
#
#TEMPLATE_NAME is needed for the ability to automatically naming the actual targets.
function(_store_featurebase __ARGS __PARS __TEMPLATE_NAMES __TARGETS_CMAKE_PATH __JOINT_TARGETS __OUT_FEATUREBASE_ID)

	_serialize_variables(${__ARGS} ${__PARS}__LIST_MODIFIERS __SERIALIZED_MODIFIERS)
	_serialize_variables(${__ARGS} ${__PARS}__LIST_FEATURES __SERIALIZED_FEATURES)
	
#	message(STATUS "${__PADDING}_store_featurebase(): _make_featurebase_hash_2(\"${__SERIALIZED_MODIFIERS}\" \"${__SERIALIZED_FEATURES}\" ${__TEMPLATE_NAMES} \"${__TARGETS_CMAKE_PATH}\" ${__JOINT_TARGETS} __FEATUREBASE_ID __FEATUREBASE_HASH_SOURCE)")
	_make_featurebase_hash_2("${__SERIALIZED_MODIFIERS}" "${__SERIALIZED_FEATURES}" "${__TEMPLATE_NAMES}" "${__TARGETS_CMAKE_PATH}" ${__JOINT_TARGETS} __FEATUREBASE_ID __FEATUREBASE_HASH_SOURCE)
#	message(STATUS "${__PADDING}_store_featurebase(): __FEATUREBASE_ID: ${__FEATUREBASE_ID} (saving to ${__OUT_FEATUREBASE_ID} in PARENT_SCOPE)")
	set(${__OUT_FEATUREBASE_ID} "${__FEATUREBASE_ID}" PARENT_SCOPE)
#	message(STATUS "${__PADDING}_store_featurebase(): set(${__OUT_FEATUREBASE_ID} \"${__FEATUREBASE_ID}\" PARENT_SCOPE)")
	
	_retrieve_featurebase_args("${__FEATUREBASE_ID}" F_FEATURES __EXISTING_FEATURES)
#	if("${__SERIALIZED_FEATURES}" STREQUAL "")
#		message(FATAL_ERROR "Empty featurebase")
#	endif()
	if(__EXISTING_FEATURES__LIST)
		#We need to try to merge all the features
		_make_promoted_featureset("${__FILE_HASH}" "${${__PARS}__LIST_FEATURES}" ${__PARS} ${__ARGS} __EXISTING_FEATURES __MERGED_ARGS __RELATION)
		if("${__RELATION}" STREQUAL "0" OR "${__RELATION}" STREQUAL "2")
			#do nothing
		elseif("${__RELATION}" STREQUAL "1")
#			message(STATUS "${__PADDING}_store_featurebase(): __FEATUREBASE_ID: ${__FEATUREBASE_ID} __SERIALIZED_FEATURES: ${__SERIALIZED_FEATURES}")
			_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_FEATURES           "${__SERIALIZED_FEATURES}" FORCE)
		elseif("${__RELATION}" STREQUAL "3")
			_serialize_variables(__EXISTING_FEATURES __EXISTING_FEATURES__LIST __SERIALIZED_EXISTING_FEATURES)
#			message(STATUS "${__PADDING}_store_featurebase(): __FEATUREBASE_ID: ${__FEATUREBASE_ID} __SERIALIZED_EXISTING_FEATURES: ${__SERIALIZED_EXISTING_FEATURES}")
			_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_FEATURES           "${__SERIALIZED_EXISTING_FEATURES}" FORCE)
		elseif("${__RELATION}" STREQUAL "4")
			_retrieve_featurebase_data("${__FEATUREBASE_ID}" G_FEATUREBASES __TMP_FEATUREBASES)
			message(FATAL_ERROR "Cannot merge two sets features of ${__TEMPLATE_NAMES}: ${__SERIALIZED_FEATURES} and ${__TMP_FEATUREBASES}")
		endif()
	else()
#		message(STATUS "${__PADDING}_store_featurebase(): first time writing to ${__FEATUREBASE_ID}: __SERIALIZED_FEATURES: ${__SERIALIZED_FEATURES}")
		_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_FEATURES           "${__SERIALIZED_FEATURES}" FORCE)
	endif()

	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} MODIFIERS            "${__SERIALIZED_MODIFIERS}")
#	message(STATUS "${__PADDING}_store_featurebase(): saving F_PATH for featurebase id: ${__FEATUREBASE_ID}: __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH}")
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_PATH               "${__TARGETS_CMAKE_PATH}")
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} TARGET_BUILT          0)
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_HASH_SOURCE         "${__FEATUREBASE_HASH_SOURCE}")
	
	if(__IS_TARGET_FIXED)
#		message(STATUS "${__PADDING}_store_instance_data(): Storing fixed target name for featurebase ${__FEATUREBASE_ID}: template names: ${__TEMPLATE_NAMES}")
		_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_TARGET_NAMES    "${__TEMPLATE_NAMES}")
	endif()
	_add_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_TEMPLATE_NAMES    "${__TEMPLATE_NAMES}")
	
#	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} COMPAT_INSTANCES      "")
	foreach(__TEMPLATE_NAME IN LISTS __TEMPLATE_NAMES)
		_add_property_to_db(TEMPLATEDB ${__TEMPLATE_NAME} TEMPLATE_FEATUREBASES        ${__FEATUREBASE_ID})
		_set_property_to_db(TEMPLATEDB ${__TEMPLATE_NAME} T_PATH                       ${__TARGETS_CMAKE_PATH})
	endforeach()

#	message(STATUS "${__PADDING}_store_featurebase(): Adding ${__FEATUREBASE_ID} to all featurebases")
	_add_property_to_db(GLOBAL ALL FEATUREBASES ${__FEATUREBASE_ID})
endfunction()

function(_link_file_with_featurebase __FEATUREBASE_ID __FILE_HASH)
	_add_property_to_db(FILEDB ${__FILE_HASH} G_FEATUREBASES        "${__FEATUREBASE_ID}")
endfunction()

function(_link_instance_with_featurebase __INSTANCE_ID __FEATUREBASE_ID) #This also assignes target name
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} FEATUREBASE "${__FEATUREBASE_ID}")
	_add_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_INSTANCES "${__INSTANCE_ID}")
endfunction()

#Stores instance data, irrelevant whether it is a promise or not. Instance data that is stored excludes template parameters, 
# because those are handled by FEATUREBASE.
function(_store_instance_data __INSTANCE_ID __ARGS __PARS __TEMPLATE_NAME __IS_TARGET_FIXED __IS_PROMISE __CMAKE_PATH)
	if("${__IS_PROMISE}" STREQUAL "")
		message(FATAL_ERROR "__IS_PROMISE cannot be empty")
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE_BEFORE)
	if(NOT "${__IS_PROMISE_BEFORE}" STREQUAL "")
#		message(STATUS "${__PADDING}_store_instance_data(): __INSTANCE_ID: ${__INSTANCE_ID} already defined. Exiting")
		return()
	endif()
#	message(STATUS "${__PADDING}_store_instance_data(): Defining __INSTANCE_ID: ${__INSTANCE_ID} __IS_PROMISE: ${__IS_PROMISE}")
	_serialize_variables(${__ARGS} ${__PARS}__LIST_FEATURES __SERIALIZED_FEATURES)
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_FEATURES            "${__SERIALIZED_FEATURES}")
	_serialize_variables(${__ARGS} ${__PARS}__LIST_LINKPARS __SERIALIZED_LINKPARS)
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} LINKPARS              "${__SERIALIZED_LINKPARS}")
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} IS_PROMISE             ${__IS_PROMISE} FORCE)
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_TEMPLATE_NAME        ${__TEMPLATE_NAME})
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_PATH                 ${__CMAKE_PATH})
	
	if(__IS_PROMISE)
#		message(STATUS "${__PADDING}_store_instance_data(): Defining virtual __INSTANCE_ID: ${__INSTANCE_ID} with __SERIALIZED_FEATURES: ${__SERIALIZED_FEATURES} and __SERIALIZED_LINKPARS: ${__SERIALIZED_LINKPARS}")
	endif()
	if(__IS_TARGET_FIXED)
#		message(STATUS "${__PADDING}_store_instance_data(): Storing fixed target name for ${__INSTANCE_ID}: ${__TEMPLATE_NAME}")
		_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_TARGET_NAME  ${__TEMPLATE_NAME})
	endif()
	_set_property_to_db(TEMPLATEDB ${__TEMPLATE_NAME} T_PATH               ${__TARGETS_CMAKE_PATH})
	
	
endfunction()

#Makes sure a given instance is stored in the memory as a promise. It does not link the instance with the parent - for that use _link_instances_together()
function(_store_virtual_instance_data __INSTANCE_ID __IN_ARGS __IN_PARS __TEMPLATE_NAME __TARGETS_CMAKE_PATH __IS_TARGET_FIXED  __EXTERNAL_PROJECT_INFO__REF __TARGET_REQUIRED  __TEMPLATE_OPTIONS__REF __ALL_TEMPLATE_NAMES __OUT_FILE_HASH)
#	message(STATUS "${__PADDING}_store_virtual_instance_data(): __INSTANCE_ID: ${__INSTANCE_ID} __ALL_TEMPLATE_NAMES: ${__ALL_TEMPLATE_NAMES} __TEMPLATE_NAME: ${__TEMPLATE_NAME} ")
	_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE_BEFORE)
	if("${__IS_PROMISE_BEFORE}" STREQUAL "1" OR "${__IS_PROMISE_BEFORE}" STREQUAL "0")
#		message(STATUS "${__PADDING}_store_virtual_instance_data(): __INSTANCE_ID: ${__INSTANCE_ID} Nothing to do. __IS_PROMISE_BEFORE: ${__IS_PROMISE_BEFORE}")
		#Nothing to do - either the promise is already set or we are not going to overwrite promise on top of actual instance
		return()
	endif()
	_store_file(${__IN_ARGS} ${__IN_PARS} ${__TEMPLATE_NAME} "${__TARGETS_CMAKE_PATH}" ${__IS_TARGET_FIXED} ${__EXTERNAL_PROJECT_INFO__REF} ${__TARGET_REQUIRED} ${__TEMPLATE_OPTIONS__REF} "${__ALL_TEMPLATE_NAMES}" __FILE_HASH __JOINED_TARGETS)
	set(${__OUT_FILE_HASH} "${__FILE_HASH}" PARENT_SCOPE)
	
	if(${__EXTERNAL_PROJECT_INFO__REF}__LIST)
		_retrieve_file_data(${__FILE_HASH} ASSUME_INSTALLED __ASSUME_INSTALLED)
		if(NOT __ASSUME_INSTALLED)
#			message(STATUS "${__PADDING}_store_virtual_instance_data(): adding virtual __INSTANCE_ID ${__INSTANCE_ID} to external dependencies")
			_add_property_to_db(GLOBAL ALL EXTERNAL_DEPENDENCIES "${__INSTANCE_ID}")
		endif()
	endif()
	
	_store_instance_data(${__INSTANCE_ID} ${__IN_ARGS} ${__IN_PARS} ${__TEMPLATE_NAME} ${__IS_TARGET_FIXED} 1 "${__TARGETS_CMAKE_PATH}")
	_serialize_variables(${__IN_ARGS} ${__IN_ARGS}__LIST_MODIFIERS __SERIALIZED_MODIFIERS)
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} PROMISE_PARAMS "${__SERIALIZED_MODIFIERS}")
#	message(STATUS "${__PADDING}_store_virtual_instance_data(): Virtual instance ${__INSTANCE_ID} got the following PROMISE_PARAMS: ${__SERIALIZED_MODIFIERS}")
	
#	message(STATUS "${__PADDING}_store_virtual_instance_data(): __IS_PROMISE_BEFORE: ${__IS_PROMISE_BEFORE} __ALL_TEMPLATE_NAMES: ${__ALL_TEMPLATE_NAMES} ")
	if(NOT "${__IS_PROMISE_BEFORE}" STREQUAL "1")
		foreach(__TEMPLATE IN LISTS __ALL_TEMPLATE_NAMES)
#			message(STATUS "${__PADDING}_store_virtual_instance_data(): adding ${__INSTANCE_ID} to virtual instances of ${__TEMPLATE}")
			_add_property_to_db(TEMPLATEDB ${__TEMPLATE} VIRTUAL_INSTANCES ${__INSTANCE_ID})
		endforeach()
	endif()
	
	
	_debug_show_instance(${__INSTANCE_ID} 2 "" __MSG __ERRORS)
#	message(STATUS "${__PADDING}_store_virtual_instance_data(): ${__MSG}")
	if(__ERRORS)
		message(STATUS "Error while storing  virtual instance data:\n${__MSG}")
		message(FATAL_ERROR ${__ERRORS})
	endif()

endfunction()

# Basically this function only removes a IS_PROMISE flag and associates the promise with the given featurebase. 
# The rest is just a work needed to keep the internal beetroot state consistent, at the very low level.
function(_unvirtualize_instance __INSTANCE_ID __FEATUREBASE_ID)
#	message(STATUS "${__PADDING}_unvirtualize_instance(): __INSTANCE_ID: ${__INSTANCE_ID} __FEATUREBASE_ID: ${__FEATUREBASE_ID}")
	_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} IS_PROMISE 0 FORCE)
	_remove_property_from_db(TEMPLATEDB ${__TEMPLATE_NAME} VIRTUAL_INSTANCES ${__INSTANCE_ID})
	_link_instance_with_featurebase(${__INSTANCE_ID} ${__FEATUREBASE_ID})
	
	_retrieve_featurebase_data(${__FEATUREBASE_ID} G_TEMPLATES __ALL_TEMPLATE_NAMES)

	foreach(__TEMPLATE IN LISTS __ALL_TEMPLATE_NAMES)
#		message(STATUS "${__PADDING}_unvirtualize_instance(): Removing __INSTANCE_ID ${__INSTANCE_ID} from VIRTUAL_INSTANCES of ${__TEMPLATE}")
		_remove_property_from_db(TEMPLATEDB ${__TEMPLATE} VIRTUAL_INSTANCES ${__INSTANCE_ID} FORCE)
	endforeach()
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} PROMISE_PARAMS "" FORCE)
#	message(STATUS "${__PADDING}_unvirtualize_instance(): Adding ${__FEATUREBASE_ID} to TEMPLATE_FEATUREBASES for ${__TEMPLATE_NAME}")
endfunction()	

# Makes sure a given instance is stored in the memory and creates/links with the featurebase structure. 
# It does not link the instance with the parent - for that use _link_instances_together()
function(_store_nonvirtual_instance_data __INSTANCE_ID __IN_ARGS __IN_PARS __TEMPLATE_NAME __TARGETS_CMAKE_PATH __IS_TARGET_FIXED  __EXTERNAL_PROJECT_INFO__REF __TARGET_REQUIRED  __TEMPLATE_OPTIONS__REF __ALL_TEMPLATE_NAMES __OUT_FILE_HASH __OUT_FEATUREBASE_ID)
	_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE_BEFORE)
	if("${__TARGETS_CMAKE_PATH}" STREQUAL "")
		message(FATAL_ERROR "Internal beetroot error: __TARGETS_CMAKE_PATH cannot be empty")
	endif()
#	message(STATUS "${__PADDING}_store_nonvirtual_instance_data(): __INSTANCE_ID: ${__INSTANCE_ID} __IS_PROMISE_BEFORE: ${__IS_PROMISE_BEFORE}")
	_store_file(${__IN_ARGS} ${__IN_PARS} ${__TEMPLATE_NAME} "${__TARGETS_CMAKE_PATH}" ${__IS_TARGET_FIXED} ${__EXTERNAL_PROJECT_INFO__REF} ${__TARGET_REQUIRED} ${__TEMPLATE_OPTIONS__REF} "${__ALL_TEMPLATE_NAMES}" __FILE_HASH __JOINED_TARGETS)
	set(${__OUT_FILE_HASH} "${__FILE_HASH}" PARENT_SCOPE)
	
	if(${__EXTERNAL_PROJECT_INFO__REF}__LIST)
		_retrieve_file_data(${__FILE_HASH} ASSUME_INSTALLED __ASSUME_INSTALLED)
		if(NOT __ASSUME_INSTALLED)

#			message(STATUS "${__PADDING}_store_nonvirtual_instance_data(): adding __INSTANCE_ID ${__INSTANCE_ID} to external dependencies")
			_add_property_to_db(GLOBAL ALL EXTERNAL_DEPENDENCIES "${__INSTANCE_ID}")
		endif()
		set(__JOINT_TARGETS 1)
	else()
		set(__JOINT_TARGETS 0)
		set(__ALL_TEMPLATE_NAMES "${__TEMPLATE_NAME}") # ALL_TEMPLATE_NAMES should contain all templates only if those templates are joined, i.e. 
		#we cannot build one without the others
	endif()
	
#	message(STATUS "${__PADDING}_store_nonvirtual_instance_data(): _store_featurebase(${__IN_ARGS} ${__IN_PARS} \"${__ALL_TEMPLATE_NAMES}\" \"${__TARGETS_CMAKE_PATH}\" ${__JOINT_TARGETS} __FEATUREBASE_ID)")
	_store_featurebase(${__IN_ARGS} ${__IN_PARS} "${__ALL_TEMPLATE_NAMES}" "${__TARGETS_CMAKE_PATH}" ${__JOINT_TARGETS} __FEATUREBASE_ID)
#	message(STATUS "${__PADDING}_store_nonvirtual_instance_data(): __FEATUREBASE_ID: ${__FEATUREBASE_ID} __FILE_HASH: ${__FILE_HASH}")
	_link_file_with_featurebase(${__FEATUREBASE_ID} ${__FILE_HASH})
	_store_instance_data(${__INSTANCE_ID} ${__IN_ARGS} ${__IN_PARS} ${__TEMPLATE_NAME} ${__IS_TARGET_FIXED} 0 "${__TARGETS_CMAKE_PATH}")
	set(${__OUT_FEATUREBASE_ID} ${__FEATUREBASE_ID} PARENT_SCOPE)
	if("${__IS_PROMISE_BEFORE}" STREQUAL "1")
		_unvirtualize_instance(${__INSTANCE_ID} ${__FEATUREBASE_ID})
	else()
		_link_instance_with_featurebase(${__INSTANCE_ID} ${__FEATUREBASE_ID})
	endif()
	
#	_debug_show_instance(${__INSTANCE_ID} 2 "" __MSG __ERRORS)
#	message(STATUS "${__PADDING}_store_nonvirtual_instance_data(): ${__MSG}")
	if(__ERRORS)
#		message(STATUS "${__PADDING}_store_nonvirtual_instance_data(): ${__MSG}")
		message(FATAL_ERROR ${__ERRORS})
	endif()
endfunction()


#Links two instances together.
#The link from dependee to the dependency is possible only through the featurebase id, so it will not be possible
#(and will trigger the error) if dependee is a promise.
#
#
#If dependee_id is empty, it will be assumed that this instance is top (required by the CMakeLists.txt directly)
#Dependent cannot be empty
#
#DEPENDEE_ID can be empty or non-promise.
#DEPENDENT_ID cannot be empty
function(_link_instances_together __DEPENDEE_ID __DEPENDENT_ID)
	if("${__DEPENDENT_ID}" STREQUAL "")
		message(FATAL_ERROR "Internal beetroot error: __DEPENDENT_ID cannot be empty")
	endif()
	_retrieve_instance_data(${__DEPENDENT_ID} IS_PROMISE __IS_PROMISE)
	if("${__IS_PROMISE}" STREQUAL "")
		message(FATAL_ERROR "Internal beetroot error: __DEPENDENT_ID: ${__DEPENDENT_ID} must be first initialized")
	endif()
#	message(STATUS "${__PADDING}_link_instances_together(): __DEPENDEE_ID: ${__DEPENDEE_ID} __DEPENDENT_ID: ${__DEPENDENT_ID}")
	
	_add_property_to_db(INSTANCEDB ${__DEPENDENT_ID} I_PARENTS "${__DEPENDEE_ID}")
	if(__DEPENDEE_ID)
		_retrieve_instance_data(${__DEPENDEE_ID} IS_PROMISE __IS_PROMISE)
		if("${__IS_PROMISE}" STREQUAL "")
			message(FATAL_ERROR "Internal beetroot error: __DEPENDEE_ID: ${__DEPENDEE_ID} must be first initialized")
		endif()
		if(__IS_PROMISE)
			message(FATAL_ERROR "Internal beetroot error: __DEPENDEE_ID: ${__DEPENDEE_ID} cannot be a promise")
		endif()
		_retrieve_instance_data(${__DEPENDEE_ID} FEATUREBASE __DEPENDEE_FEATUREBASE)
		if("${__DEPENDEE_FEATUREBASE}" STREQUAL "")
			message(FATAL_ERROR "Internal beetroot error")
		endif()
		_add_property_to_db(FEATUREBASEDB ${__DEPENDEE_FEATUREBASE} DEP_INSTANCES ${__DEPENDENT_ID})
	else()
		_add_property_to_db(GLOBAL ALL INSTANCES ${__DEPENDENT_ID})
	endif()
endfunction()

#Moves all parents of the __OLD_INSTANCE_ID to the __NEW_INSTANCE_ID,
#unregisters the dependencies of the __OLD_INSTANCE_ID from it and makes sure __OLD_INSTANCE_ID will not be built.
#
#This is the final stage of promoting the virtual instance into a real one.
#
#We assume the __NEW_INSTANCE_ID has correct dependencies, but is not dependent on anything.
#
#__OLD_INSTANCE_ID can be a promise (and have no dependencies)
function(_move_instance __OLD_INSTANCE_ID __NEW_INSTANCE_ID )
#	message(FATAL_ERROR "OK")
#	#1. For each parent, change its dependency and parent
#	_retrieve_instance_data(${__OLD_INSTANCE_ID} I_PARENTS __PARENTS)
#	message(STATUS "${__PADDING}_move_instance(): Adding parents of ${__OLD_INSTANCE_ID} to the new ${__NEW_INSTANCE_ID}. __PARENTS: ${__PARENTS}")
#	foreach(__PARENT_ID IN LISTS __PARENTS)
#		_retrieve_instance_data(${__PARENT_ID} FEATUREBASE __PARENT_FEATUREBASE)
#		if(NOT __PARENT_FEATUREBASE)
#			message(FATAL_ERROR "Internal beetroot consistency error: Parent does contain a link to the featurebase.")
#		endif()
#		_remove_property_from_db(FEATUREBASEDB ${__PARENT_FEATUREBASE} DEP_INSTANCES ${__OLD_INSTANCE_ID})
#		_add_property_to_db(FEATUREBASEDB ${__PARENT_FEATUREBASE} DEP_INSTANCES ${__NEW_INSTANCE_ID})
#		_add_property_to_db(INSTANCEDB ${__NEW_INSTANCE_ID} I_PARENTS ${__PARENT_ID})
#		_remove_property_from_db(INSTANCEDB ${__OLD_INSTANCE_ID} I_PARENTS ${__PARENT_ID})
#	endforeach()
	
	#2. Change TEMPLATEDB
	_retrieve_instance_data(${__OLD_INSTANCE_ID} VIRTUAL_INSTANCES __PROMISES)
	_retrieve_instance_data(${__OLD_INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
	_retrieve_instance_data(${__OLD_INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	_retrieve_instance_data(${__NEW_INSTANCE_ID} IS_PROMISE __NEW_IS_PROMISE)
	if("${__IS_PROMISE}" STREQUAL "1")
		message(FATAL_ERROR "Internal beetroot error: There should be no need to move a promise")
	endif()
	if(NOT "${__IS_PROMISE}" STREQUAL "${__NEW_IS_PROMISE}")
		message(FATAL_ERROR "Internal beetroot error: __OLD_INSTANCE_ID: ${__OLD_INSTANCE_ID} __IS_PROMISE: ${__IS_PROMISE} __NEW_INSTANCE_ID: ${__NEW_INSTANCE_ID} __NEW_IS_PROMISE: ${__NEW_IS_PROMISE}")
	endif()
	
	#3. Move instance in 
	_retrieve_instance_data(${__NEW_INSTANCE_ID} FEATUREBASE __NEW_FEATUREBASE)
	_retrieve_instance_data(${__OLD_INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	if("${__IS_PROMISE}" STREQUAL "0")
		_retrieve_instance_data(${__OLD_INSTANCE_ID} FEATUREBASE __OLD_FEATUREBASE)
	else()
		set(__OLD_FEATUREBASE)
	endif()
	if(NOT "${__OLD_FEATUREBASE}" STREQUAL "${__NEW_FEATUREBASE}")
		if(NOT "${__OLD_FEATUREBASE}" STREQUAL "")
			_remove_property_from_db(FEATUREBASEDB ${__OLD_FEATUREBASE} F_INSTANCES ${__OLD_INSTANCE_ID})
		endif()
#		message(STATUS "${__PADDING}_move_instance(): Adding instance ${__NEW_INSTANCE_ID} to F_INSTANCES of featurebase ${__NEW_FEATUREBASE}")
		_add_property_to_db(FEATUREBASEDB ${__NEW_FEATUREBASE} F_INSTANCES ${__NEW_INSTANCE_ID})
	endif()
	
	#4. Change __GLOBAL_ALL_INSTANCES
	_retrieve_global_data(INSTANCES __ALL_INSTANCES)
	if(${__OLD_INSTANCE_ID} IN_LIST __ALL_INSTANCES)
		_remove_property_from_db(GLOBAL ALL INSTANCES ${__OLD_INSTANCE_ID})
		_add_property_to_db(GLOBAL ALL INSTANCES ${__NEW_INSTANCE_ID})
	endif()
	_retrieve_global_data(EXTERNAL_DEPENDENCIES __EXTERNAL_DEPENDENCIES)
	if(${__OLD_INSTANCE_ID} IN_LIST __EXTERNAL_DEPENDENCIES)
#		message(STATUS "_move_instance(): Moving instance ${__OLD_INSTANCE_ID} from EXTERNAL_DEPENDENCIES")
		_remove_property_from_db(GLOBAL ALL EXTERNAL_DEPENDENCIES ${__OLD_INSTANCE_ID})
		_add_property_to_db(GLOBAL ALL EXTERNAL_DEPENDENCIES ${__NEW_INSTANCE_ID})
	endif()
endfunction()

function(_move_parents_between_instances __OLD_INSTANCE_ID __NEW_INSTANCE_ID)
	#1. For each parent, change its dependency and parent
	_retrieve_instance_data(${__OLD_INSTANCE_ID} I_PARENTS __PARENTS)
#	message(STATUS "${__PADDING}_move_parents_between_instances(): Adding parents of ${__OLD_INSTANCE_ID} to the new ${__NEW_INSTANCE_ID}. __PARENTS: ${__PARENTS}")
	foreach(__PARENT_ID IN LISTS __PARENTS)
		_retrieve_instance_data(${__PARENT_ID} FEATUREBASE __PARENT_FEATUREBASE)
		if(NOT __PARENT_FEATUREBASE)
			message(FATAL_ERROR "Internal beetroot consistency error: Parent does contain a link to the featurebase.")
		endif()
		_remove_property_from_db(FEATUREBASEDB ${__PARENT_FEATUREBASE} DEP_INSTANCES ${__OLD_INSTANCE_ID})
		_add_property_to_db(FEATUREBASEDB ${__PARENT_FEATUREBASE} DEP_INSTANCES ${__NEW_INSTANCE_ID})
		_add_property_to_db(INSTANCEDB ${__NEW_INSTANCE_ID} I_PARENTS ${__PARENT_ID})
		_remove_property_from_db(INSTANCEDB ${__OLD_INSTANCE_ID} I_PARENTS ${__PARENT_ID})
	endforeach()
endfunction()

#Adds an instance to the system - function is now obsolote
#function(_commit_instance_data __INSTANCE_ID __PARENT_INSTANCE_ID __ARGS __PARS __TEMPLATE_NAME __TARGETS_CMAKE_PATH __IS_TARGET_FIXED __EXTERNAL_PROJECT_INFO__REF __TARGET_REQUIRED __TEMPLATE_OPTIONS__REF __ALL_TEMPLATE_NAMES)

#	_store_nonvirtual_instance_data(${__INSTANCE_ID} ${__ARGS} ${__PARS} ${__TEMPLATE_NAME} "${__TARGETS_CMAKE_PATH}" ${__IS_TARGET_FIXED}  "${__EXTERNAL_PROJECT_INFO__REF}" ${__TARGET_REQUIRED} ${__TEMPLATE_OPTIONS__REF} "${__ALL_TEMPLATE_NAMES}" __FILE_HASH __FEATUREBASE_ID)

#	_link_instances_together("${__PARENT_INSTANCE_ID}" ${__INSTANCE_ID})
#endfunction()

function(_store_instance_dependencies __INSTANCE_ID __DEP_LIST)
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)
#	message(STATUS "${__PADDING}_store_instance_dependencies(): __INSTANCE_ID: ${__INSTANCE_ID} __DEP_LIST: ${__DEP_LIST} __FEATUREBASE_ID: ${__FEATUREBASE_ID}")
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} DEP_INSTANCES        "${__DEP_LIST}" $ARGV2)
endfunction()

#Promotes features on an INSTANCE_ID to the features of the given featurebase. Target names are still not assigned - all this code happens
#before instantianization of targets
#
#The process is basicaly three staged: _unvirtualize_instance() -> _rediscover_dependencies() -> _move_instance().
function(_promote_instance __INSTANCE_ID __FEATUREBASE_ID __SERIALIZED_COMMON_FEATURES__REF __OUT_NEW_INSTANCE_ID)
#	message(STATUS "${__PADDING}_promote_instance(): Promoting __INSTANCE_ID: ${__INSTANCE_ID} to be compatible with featurebase ${__FEATUREBASE_ID} and features ${${__SERIALIZED_COMMON_FEATURES__REF}__LIST}")
	_debug_show_instance(${__INSTANCE_ID} 2 "BEFORE_PROMOTION: " __MSG __ERRORS)
#	message(STATUS "${__PADDING}_promote_instance(): After promotion:\nx x x x x x x x x x x\n${__MSG}")
	if(__ERRORS)
		message(STATUS "Error in instance after promotion:\n${__MSG}")
		message(FATAL_ERROR ${__ERRORS})
	endif()

	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_FEATURES "${${__SERIALIZED_COMMON_FEATURES__REF}__LIST}" FORCE)
#	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} FEATUREBASE "${__FEATUREBASE_ID}")
	_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	if(__IS_PROMISE)
		#We need to tell the promise what is the matched featurebase. Then we proceed with rediscover normally, because the featureset is already initialized
		_unvirtualize_instance(${__INSTANCE_ID} ${__FEATUREBASE_ID})
	else()
		_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __OLD_FEATUREBASE_ID)
		if(NOT "${__OLD_FEATUREBASE_ID}" STREQUAL "${__FEATUREBASE_ID}")
			message(FATAL_ERROR "Internal beetroot error: Promotion wants to change featurebase from ${__OLD_FEATUREBASE_ID} to ${__FEATUREBASE_ID}")
		endif()
	endif()
	_add_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} COMPAT_INSTANCES ${__INSTANCE_ID})
#	message(STATUS "${__PADDING}_promote_instance(): ${__SERIALIZED_COMMON_FEATURES__REF}__LIST: ${${__SERIALIZED_COMMON_FEATURES__REF}__LIST}")
#	message(STATUS "${__PADDING}_move_instance(): moving ${__INSTANCE_ID} -> ${__NEW_INSTANCE_ID}")
	set(__NEW_INSTANCE_ID)
#	message(STATUS "${__PADDING}_promote_instance(): _rediscover_dependencies(${__INSTANCE_ID} ${__SERIALIZED_COMMON_FEATURES__REF} __NEW_INSTANCE_ID)")
	_rediscover_dependencies(${__INSTANCE_ID} ${__SERIALIZED_COMMON_FEATURES__REF} __NEW_INSTANCE_ID)
	
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_FEATURES __SERIALIZED_FEATURES)
#	message(STATUS "${__PADDING}_promote_instance(): __FEATUREBASE_ID: ${__FEATUREBASE_ID} __SERIALIZED_FEATURES: ${__SERIALIZED_FEATURES}")
#	message(STATUS "${__PADDING}_promote_instance(): moving ${__INSTANCE_ID} -> ${__NEW_INSTANCE_ID}")
#	_move_instance(${__INSTANCE_ID} ${__NEW_INSTANCE_ID} )
	_debug_show_instance(${__NEW_INSTANCE_ID} 3 "AFTER_PROMOTION: " __MSG __ERRORS)
#	message(STATUS "${__PADDING}_promote_instance(): After promotion:\nx x x x x x x x x x x\n${__MSG}")
	if(__ERRORS)
		message(STATUS "Error in instance efter promotion:\n${__MSG}")
		message(FATAL_ERROR "${__ERRORS}")
	endif()
#	message(FATAL_ERROR "!!!!")
	
	set(${__OUT_NEW_INSTANCE_ID} ${__NEW_INSTANCE_ID} PARENT_SCOPE )
endfunction()

function(_change_instance_id __OLD_INSTANCE_ID __NEW_INSTANCE_ID)
#	_debug_show_instance(${__OLD_INSTANCE_ID} 2 "  " __STR __ERROR)
#	if(__ERROR)
#		message(FATAL_ERROR "${__ERROR}")
#	endif()
#	message(STATUS "${__PADDING}_change_instance_id(): __OLD_INSTANCE_ID: ${__OLD_INSTANCE_ID} __NEW_INSTANCE_ID: ${__NEW_INSTANCE_ID}")
#	message(STATUS "${__PADDING}_change_instance_id(): ${__STR}")
	#1. For each parent, change its dependency and parent
	_retrieve_instance_data(${__OLD_INSTANCE_ID} I_PARENTS __PARENTS)
	foreach(__PARENT_ID IN LISTS __PARENTS)
		_retrieve_instance_data(${__PARENT_ID} FEATUREBASE __PARENT_FEATUREBASE)
		if(NOT __PARENT_FEATUREBASE)
			message(FATAL_ERROR "Internal beetroot consistency error: Parent does contain a link to the featurebase.")
		endif()
		_remove_property_from_db(FEATUREBASEDB ${__PARENT_FEATUREBASE} DEP_INSTANCES ${__OLD_INSTANCE_ID})
		_add_property_to_db(FEATUREBASEDB ${__PARENT_FEATUREBASE} DEP_INSTANCES ${__NEW_INSTANCE_ID})
		_add_property_to_db(INSTANCEDB ${__NEW_INSTANCE_ID} I_PARENTS ${__PARENT_ID})
	endforeach()
	
	#2. Change TEMPLATEDB
	_retrieve_instance_data(${__OLD_INSTANCE_ID} VIRTUAL_INSTANCES __PROMISES)
	_retrieve_instance_data(${__OLD_INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
	_retrieve_instance_data(${__OLD_INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	_retrieve_instance_data(${__NEW_INSTANCE_ID} IS_PROMISE __NEW_IS_PROMISE)
	if(__IS_PROMISE)
		message(FATAL_ERROR "Internal beetroot error: There should be no need to change id of a promise")
		_remove_property_from_db(TEMPLATEDB ${__TEMPLATE_NAME} VIRTUAL_INSTANCES ${__OLD_INSTANCE_ID})
	else()
		if(__NEW_IS_PROMISE)
			_remove_property_from_db(TEMPLATEDB ${__TEMPLATE_NAME} VIRTUAL_INSTANCES ${__NEW_INSTANCE_ID})
		endif()
	endif()
	_retrieve_instance_data(${__NEW_INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	if(__IS_PROMISE)
		message(FATAL_ERROR "Internal beetroot error: There should be no need to change id of a promise")
		_add_property_to_db(TEMPLATEDB ${__TEMPLATE_NAME} VIRTUAL_INSTANCES ${__NEW_INSTANCE_ID})
	endif()
	
	
	
	#3. Change __GLOBAL_ALL_INSTANCES
	_retrieve_global_data(INSTANCES __ALL_INSTANCES)
	if(${__OLD_INSTANCE_ID} IN_LIST __ALL_INSTANCES)
		_remove_property_from_db(GLOBAL ALL INSTANCES ${__OLD_INSTANCE_ID})
		_add_property_to_db(GLOBAL ALL INSTANCES ${__NEW_INSTANCE_ID})
	endif()
	
endfunction()
