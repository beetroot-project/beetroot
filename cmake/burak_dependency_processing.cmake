
# Function that calls declare_dependencies() and gathers all dependencies into the global storage. The dependency information is sufficient to properly call generate_target() or apply_to_target() user functions.
function(_discover_dependencies __INSTANCE_ID __TEMPLATE_NAME __TARGETS_CMAKE_PATH __ARGS __PARS __EXTERNAL_PROJECT_INFO __IS_TARGET_FIXED __TEMPLATE_OPTIONS )
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID )
#	if(__FEATUREBASE_ID)
#		message(STATUS "_discover_dependencies(): __FEATUREBASE_ID: ${__FEATUREBASE_ID} for __INSTANCE_ID: ${__INSTANCE_ID}")
#		_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __FEATUREBASE_DEFINED )
#		message(STATUS "_discover_dependencies(): DEP_INSTANCES: ${__FEATUREBASE_DEFINED} for __INSTANCE_ID: ${__INSTANCE_ID}")
#	else()
#		set(__FEATUREBASE_DEFINED)
#	endif()
	_put_dependencies_into_stack("${__INSTANCE_ID}")
	if(NOT __FEATUREBASE_ID)
		set(__LIST ${${__PARS}__LIST_MODIFIERS})
		list(APPEND __LIST ${__${__PARS}__LIST_LINKPARS} )

		message(STATUS "Discovering dependencies for ${__TEMPLATE_NAME} (${__INSTANCE_ID})...")
	#	_read_targets_file("${__TARGETS_CMAKE_PATH}" __READ __IS_TARGET_FIXED)
		_instantiate_variables(${__ARGS} "${__LIST}")

		_descend_dependencies_stack()
		declare_dependencies(${__TEMPLATE_NAME}) #May call get_target() which will call _discover_dependencies() recursively
	#	message(FATAL_ERROR "__LIST: ${__LIST}")
		_get_dependencies_from_stack(__DEP_INSTANCE_IDS)
	#	message(STATUS "_discover_dependencies(): __TEMPLATE_NAME: ${__TEMPLATE_NAME} __DEP_INSTANCE_IDS: ${__DEP_INSTANCE_IDS}")
		_ascend_dependencies_stack()
	
	endif()
	_get_target_behavior(__GET_TARGET_BEHAVIOR)
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
		set(__TARGET_REQUIRED 1)
	else()
		set(__TARGET_REQUIRED 0)
	endif()
	_get_parent_dependency_from_stack(__PARENT_INSTANCE_ID)
	_store_instance_data(
		 ${__INSTANCE_ID}
		"${__PARENT_INSTANCE_ID}"
		${__ARGS} 
		${__PARS}
		 ${__TEMPLATE_NAME} 
		 ${__TARGETS_CMAKE_PATH} 
		 ${__IS_TARGET_FIXED}
		"${__EXTERNAL_PROJECT_INFO}"
		 ${__TARGET_REQUIRED}
		"${__TEMPLATE_OPTIONS}"
		 )
	if(NOT __FEATUREBASE_ID)
		_store_instance_dependencies(${__INSTANCE_ID} "${__DEP_INSTANCE_IDS}")
	endif()
endfunction()

#Instantiates target. The function is called during the target building phase. Behavior is different on SUPERBUILD and in the project build.
function(_instantiate_target __INSTANCE_ID)
	_get_target_behavior(__TARGET_BEHAVIOR)
	if(NOT "${__TARGET_BEHAVIOR}" STREQUAL "DEFINING_TARGETS")
		message(FATAL_ERROR "Burak internal error: _get_dependencies() called when not DEFINIG_TARGETS")
	endif()
	
	_retrieve_instance_data(${__INSTANCE_ID} F_TEMPLATE_NAME __TARGET_IS_NON_VIRTUAL)
	if(NOT __TARGET_IS_NON_VIRTUAL)
		message(FATAL_ERROR "Cannot build ${__INSTANCE_ID} because it was only declared using get_existing_target(), and never actually defined by get_target().")
	else()
#		message(STATUS "_instantiate_target(): __INSTANCE_ID: ${__INSTANCE_ID} F_TEMPLATE_NAME: ${__TARGET_IS_NON_VIRTUAL}")
	endif()
	
	
	_retrieve_instance_data(${__INSTANCE_ID} TARGET_BUILT __IS_TARGET_BUILT)
	if(__IS_TARGET_BUILT)
		return() #Nothing to do in this run
	endif()

	_make_instance_name(${__INSTANCE_ID} __TARGET_NAME)
#	message(STATUS "_instantiate_target(): Named ${__INSTANCE_ID}: ${__TARGET_NAME}")
	set(__DEP_TARGETS)
	_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __DEP_IDS)

#	message(STATUS "_instantiate_target(): Named ${__INSTANCE_ID}: ${__TARGET_NAME}, __DEP_IDS: ${__DEP_IDS}")
	if(__DEP_IDS)
		foreach(__DEP_ID IN LISTS __DEP_IDS)
#			message(STATUS "_instantiate_target(): Defining ${__DEP_ID} required by target ${__TARGET_NAME}")
			_instantiate_target(${__DEP_ID})
			_make_instance_name(${__DEP_ID} __DEP_TARGET_NAME)
			if(NOT __NOT_SUPERBUILD) #On superbuild the only targets we care about are external projects that are not assumed installed
				_retrieve_instance_data(${__INSTANCE_ID} EXTERNAL_INFO __EXTERNAL_INFO)
				_retrieve_instance_data(${__INSTANCE_ID} ASSUME_INSTALLED __ASSUME_INSTALLED)
				
			else()
				set(__EXTERNAL_INFO "JUST_TO_FOOL_THE_NEXT_COMMAND_IN_THIS_LOOP") #We pretend that any target is external in the project build, to save few more commands in this loop.
			endif()
			if(__DEP_TARGET_NAME)
				if(__EXTERNAL_INFO AND NOT __ASSUME_INSTALLED)
					list(APPEND __DEP_TARGETS ${__DEP_TARGET_NAME})
				endif()
			endif()
		endforeach()
		
#		message(STATUS "_instantiate_target(): Gathered the following dependencies for ${__TARGET_NAME}: ${__DEP_TARGETS}")
	endif()
#	message(STATUS "Entry to _instantiate_target, __TEMPLATE_NAME: ${__TEMPLATE_NAME}, __TARGETS_CMAKE_PATH=${__TARGETS_CMAKE_PATH}. Dependencies: ${__DEP_LIST} ")
	if(NOT __NOT_SUPERBUILD)
		string(REPLACE "::" "_" __TARGET_NAME ${__TARGET_NAME})
	endif()
	
	_retrieve_instance_data(${__INSTANCE_ID} EXTERNAL_INFO __EXTERNAL_PROJECT_INFO)
	if(__EXTERNAL_PROJECT_INFO)
		#Handling external project
		_get_target_external(${__INSTANCE_ID} "${__DEP_TARGETS}")
	else()
		if(__NOT_SUPERBUILD) # We ignore internal dependencies on SUPERBUILD phase
#			message(STATUS "_instantiate_target(): Calling _get_target_internal(${__TEMPLATE_NAME} ${__TARGET_NAME} \"${__TARGETS_CMAKE_PATH}\" __ARGS)")
			_get_target_internal(${__INSTANCE_ID} __FUNCTION_EXISTS)
			foreach(__DEP_INSTANCE_ID IN LISTS __DEP_IDS)
				_make_instance_name(${__DEP_INSTANCE_ID} __DEP_TARGET_NAME)
				if(NOT __DEP_TARGET_NAME)
					message(FATAL_ERROR "No target name")
				endif()
				if(TARGET ${__TARGET_NAME})
					_invoke_apply_dependency_to_target(${__INSTANCE_ID} ${__DEP_INSTANCE_ID} __FUNCTION_EXISTS)
				else()
					message(FATAL_ERROR "Template that does not produce targets: ${__TARGET_NAME} currently cannot have any dependencies")
				endif()
#				message(STATUS "_instantiate_target(): __TARGET_NAME: ${__TARGET_NAME} __DEP_TARGET_NAME: ${__DEP_TARGET_NAME} __FUNCTION_EXISTS: ${__FUNCTION_EXISTS}")
				if(NOT __FUNCTION_EXISTS)
					if(TARGET "${__DEP_TARGET_NAME}")
						get_target_property(__TYPE ${__TARGET_NAME} TYPE)
						if("${__TYPE}" STREQUAL "INTERFACE_LIBRARY" )
							target_link_libraries(${__TARGET_NAME} INTERFACE ${__DEP_TARGET_NAME}) 
							set(__X INTERFACE)
						else()
							target_link_libraries(${__TARGET_NAME} PUBLIC ${__DEP_TARGET_NAME})
							set(__X LINK)
						endif()
#						message(STATUS "_instantiate_target(): about to call target_link_libraries:\n __INSTANCE_ID: ${__INSTANCE_ID} Linking ${__TARGET_NAME} to ${__DEP_TARGET_NAME}. ${__X} ")
					else()
						_retrieve_instance_data(${__DEP_INSTANCE_ID} _I_TEMPLATE_NAME __DEP_TEMPLATE_NAME )
						message(FATAL_ERROR "${__DEP_TEMPLATE_NAME} does not produce targets and it does not define apply_dependency_to_target(). You must either define targets or define function apply_dependency_to_target().")
					endif()
				endif()
			endforeach()
		endif()
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} TARGET_BUILT 1)
endfunction()

