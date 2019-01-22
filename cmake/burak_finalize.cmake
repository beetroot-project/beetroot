#Macro that generates a local project as the external dependency in the SUPERBUILD phase
#that depends on all external dependencies.
#
#It must be macro, because it has to enable languages, if enabled by any of the targets.
macro(finalizer)
	_get_target_behavior(__TARGET_BEHAVIOR)
	if("${__TARGET_BEHAVIOR}" STREQUAL "DEFINING_TARGETS")
		message(WARNING "finalizer called second time. This function is meant to be called only once at the very end of the root CMakeLists. Ignoring this call.")
		return()
	endif()
	message("")
	message("")
	message("")
	if(__NOT_SUPERBUILD)
		message("    DEFINING  TARGETS  IN  PROJECT BUILD")
	else()
		message("    DEFINING  TARGETS  IN  SUPERBUILD")
	endif()
	message("")
	_set_behavior_defining_targets() #To make sure we never call declare_dependencies()
	_resolve_features()
	#Now we can assume that all features in all featuresets agree with the features in instances, which means that we can concatenate features to the target parameters (modifiers)
	_get_all_languages(__LANGUAGES)
	if(__LANGUAGES)
		foreach(__LANGUAGE IN LISTS __LANGUAGES)
			message(STATUS "finalizer(): About to enable language ${__LANGUAGE}")
			enable_language(${__LANGUAGE})
		endforeach()
	endif()
	#Now we need to instantiate all the targets. 
	_get_all_instance_ids(__INSTANCE_ID_LIST)
#	message(STATUS "finalizer: __INSTANCE_ID_LIST: ${__INSTANCE_ID_LIST}")
	if(__INSTANCE_ID_LIST)
		foreach(__DEP_ID IN LISTS __INSTANCE_ID_LIST)
#			message(STATUS "finalizer(): Going to instantiate ${__DEP_ID}")
			_instantiate_target(${__DEP_ID})
		endforeach()
		if(NOT __NOT_SUPERBUILD)
			get_property(__EXTERNAL_DEPENDENCIES GLOBAL PROPERTY __BURAK_EXTERNAL_DEPENDENCIES)
			if(__EXTERNAL_DEPENDENCIES)
				set(__EXT_DEP_STR "DEPENDS")
				foreach(__EXT_DEP IN LISTS __EXTERNAL_DEPENDENCIES)
					string(REPLACE "::" "_" __EXT_DEP_FIXED ${__EXT_DEP})
					set(__EXT_DEP_STR ${__EXT_DEP_STR} ${__EXT_DEP_FIXED})
				endforeach()
			endif()
			message(STATUS "End of SUPERBUILD phase. External projects: ${__EXT_DEP_STR} CMAKE_PROJECT_NAME: ${CMAKE_PROJECT_NAME}")
			set(__EXT_DEP_STR ${__EXT_DEP_STR})
#			message(STATUS "finalizer(): ExternalProject_Add(${CMAKE_PROJECT_NAME} PREFIX ${CMAKE_SOURCE_DIR} SOURCE_DIR ${CMAKE_SOURCE_DIR} TMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/tmp STAMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/stamps DOWNLOAD_DIR \"${CMAKE_CURRENT_BINARY_DIR}\" INSTALL_COMMAND \"\" BUILD_ALWAYS ON BINARY_DIR \"${CMAKE_CURRENT_BINARY_DIR}/project\" ${__EXT_DEP_STR} CMAKE_ARGS -D__NOT_SUPERBUILD=ON)")
			ExternalProject_Add(${CMAKE_PROJECT_NAME}
				${__EXT_DEP_STR}
				PREFIX ${CMAKE_SOURCE_DIR}
				SOURCE_DIR ${CMAKE_SOURCE_DIR}
				TMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/tmp
				STAMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/stamps
				DOWNLOAD_DIR "${CMAKE_CURRENT_BINARY_DIR}"
				INSTALL_COMMAND ""
				BUILD_ALWAYS ON
				BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/project"
				CMAKE_ARGS -D__NOT_SUPERBUILD=ON
			)
		endif()
	else()
		message(WARNING "No targets declared")
	endif()
endmacro()


macro(finalize)
	finalizer()
endmacro()

macro(_get_all_languages __OUT_LANGUAGES) 
	_gather_languages()
	get_property("${__OUT_LANGUAGES}" GLOBAL PROPERTY __BURAK_ALL_LANGUAGES)
endmacro()

function(_gather_languages )
	_get_all_instance_ids(__INSTANCE_ID_LIST)
	foreach(__INSANCE_ID IN LISTS __INSTANCE_ID_LIST)
		_gather_language_rec(${__INSANCE_ID})
	endforeach()
endfunction()

function(_gather_language_rec __INSTANCE_ID)
	_retrieve_instance_data(${__INSTANCE_ID} LANGUAGES __LANGUAGES)
	if(__LANGUAGES)
		_retrieve_instance_data(${__INSTANCE_ID} F_PATH __PATH)
		_make_path_hash("${__PATH}" __KEY)
		_add_property_to_db(BURAK ALL LANGUAGES "${__LANGUAGES}")
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __DEP_IDS)
	if(__DEP_IDS)
		foreach(__DEP_ID IN LISTS __DEP_IDS)
			_gather_language_rec(${__DEP_ID})
		endforeach()
	endif()
endfunction()

function(_resolve_features)
	#First we need to make sure all instances that connect to the same featurebase agree in their feature lists
	get_property(__ALL_FEATUREBASES GLOBAL PROPERTY __BURAK_ALL_FEATUREBASES)
	while(__ALL_FEATUREBASES)
		list(GET __ALL_FEATUREBASES 0 __FEATUREBASE_ID)
		_retrieve_featurebase_data(${__FEATUREBASE_ID} F_INSTANCES __FEATURE_INSTANCES)
		list(LENGTH __FEATURE_INSTANCES __INSTANCES_COUNT)
		if(${__INSTANCES_COUNT} EQUAL 0)
			message(FATAL_ERROR "Internal beetroot error: no instances in the featurebase __INSTANCES_COUNT")
		endif()
#		if(${__INSTANCES_COUNT} EQUAL 1)
#			#Only one featurebase - there is little to do. 
#			_remove_property_from_db(BURAK ALL FEATUREBASES ${__FEATUREBASE_ID} )
#			continue()
#		endif()
		_retrieve_featurebase_args(${__FEATUREBASE_ID} F_FEATURES __BASE_ARGS)
		_calculate_hash(__BASE_ARGS "${__BASE_ARGS__LIST}" "" __BASE_HASH)
		foreach(__INSTANCE_ID IN LISTS __FEATURE_INSTANCES)
			#We must make sure, that all features agree with the features declared in the featureabase
			_retrieve_instance_data(${__INSTANCE_ID} I_FEATURES __I_ARGS)
			_calculate_hash(__I_ARGS "${__I_ARGS__LIST}" "" __I_HASH)
			if(NOT "${__I_HASH}" STREQUAL "${__BASE_HASH}")
				_serialize_variables(__BASE_ARGS "${__BASE_ARGS__LIST}" __SERIALIZED_BASE_ARGS)
				_serialize_variables(__I_ARGS "${__I_ARGS__LIST}" __SERIALIZED_I_ARGS)
				#TODO: Sprawdź, czy można promować __I_HASH i __BASE_HASH do wspólnego mianownika. 
				#Jeśli można to promuj odpowiednio albo baseline, albo tylko instance.
				#W zależności, co promowałeś, należy ponownie sprawdzić zależności: albo tej jednej instancji, albo ...
				#
				message(FATAL_ERROR "Internal Beetroot error: features in the instance ${__INSTANCE_ID} (${__SERIALIZED_I_ARGS} with hash ${__I_HASH}) does not agree with features in the featurebase (${__SERIALIZED_BASE_ARGS} with hash ${__BASE_HASH})")
			endif()
		endforeach()
		_remove_property_from_db(BURAK ALL FEATUREBASES ${__FEATUREBASE_ID} )
		get_property(__ALL_FEATUREBASES GLOBAL PROPERTY __BURAK_ALL_FEATUREBASES)
	endwhile()
endfunction()


