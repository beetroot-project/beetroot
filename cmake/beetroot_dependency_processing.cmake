# This function assumes the dependencies have already been discovered once.
# It is triggered when beetroot promoted this instance from being a promised instance (defined by get_existing_target())
# into the normal instance with the associated featurebase. 
#
# The task is to rediscover the dependencies. Last discovery failed, because the pure promise does not contain a final
# (nor complete) set of parameters - those are acquired by its discovered virtual siblings and the base instance. 
# That's why the dependency discovery got deferred into this moment, when we finally have a chance to know the final set of the parameters.
# Keep in mind that it is possible, that in this process of deferred dependency search we will encounter 
# virtual instances that are compatible with those we have already promoted. In that corner case, and only 
# if the set of parameters changed, we would run the rediscovery again.
#
# __NEW_FEATURES_SERIALIZED__REF are the 
# all features (possible some new) and parameters that got associated in this process, that came from other virtual instances
# that get promoted to the same featurebase or from the call to the get_target() that defined the basis instance.
# __NEW_FEATURES_SERIALIZED__REF contains also link parameters, but these are not expected to change from the last run.
#
# This is also the only instance, when the code inside a single declare_dependencies() gets executed more than once.
function(_rediscover_dependencies __INSTANCE_ID __NEW_FEATURES_SERIALIZED__REF __OUT_NEW_INSTANCE_ID)
	_increase_padding()

	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)
#	message(STATUS "${__PADDING}_rediscover_dependencies(): __INSTANCE_ID: ${__INSTANCE_ID} __FEATUREBASE_ID: ${__FEATUREBASE_ID}")
	_retrieve_instance_args(${__INSTANCE_ID} LINKPARS __ARGS)
	_retrieve_instance_data(${__INSTANCE_ID} LINKPARS __TMP)
#	message(STATUS "${__PADDING}_rediscover_dependencies(): __INSTANCE_ID: ${__INSTANCE_ID} LINKPARS: ${__TMP}")
	set(__PARS__LIST_LINKPARS ${__ARGS__LIST})
	_retrieve_instance_args(${__INSTANCE_ID} MODIFIERS __ARGS)
	_retrieve_instance_data(${__INSTANCE_ID} MODIFIERS __TMP)
#	message(STATUS "${__PADDING}_rediscover_dependencies(): __INSTANCE_ID: ${__INSTANCE_ID} MODIFIERS: ${__TMP}")
	set(__PARS__LIST_MODIFIERS ${__ARGS__LIST})
#	message(STATUS "${__PADDING}_rediscover_dependencies(): __INSTANCE_ID: ${__INSTANCE_ID} FEATURES: ${${__NEW_FEATURES_SERIALIZED__REF}}")
	_unserialize_variables(${__NEW_FEATURES_SERIALIZED__REF} __ARGS)
	set(__PARS__LIST_FEATURES  ${__ARGS__LIST})
	set(__ARGS__LIST_LINKPARS  ${__PARS__LIST_LINKPARS})
	set(__ARGS__LIST_MODIFIERS ${__PARS__LIST_MODIFIERS})
	set(__ARGS__LIST_FEATURES  ${__PARS__LIST_FEATURES})
	set(__ARGS__LIST ${__PARS__LIST_LINKPARS} ${__PARS__LIST_MODIFIERS} ${__PARS__LIST_FEATURES})
	
	_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
	_retrieve_instance_data(${__INSTANCE_ID} I_PARENTS __PARENT_INSTANCE_IDS)
	_retrieve_instance_data(${__INSTANCE_ID} PATH __TARGETS_CMAKE_PATH)
	_retrieve_instance_data(${__INSTANCE_ID} TARGET_FIXED __IS_TARGET_FIXED)
	_retrieve_instance_data(${__INSTANCE_ID} EXTERNAL_INFO __EXTERNAL_PROJECT_INFO__LIST)
	_retrieve_instance_data(${__INSTANCE_ID} FILE_OPTIONS __FILE_OPTIONS__LIST)
	_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	_retrieve_instance_pars(${__INSTANCE_ID} PARS __PARS)
		
	#Now let's make a new INSTANCE_ID for the newly resolved virtual instance:
	_make_instance_id(${__TEMPLATE_NAME} __ARGS "${__IS_PROMISE}" __NEW_INSTANCE_ID __HASH_SOURCE)
	_move_parents_between_instances(${__INSTANCE_ID} ${__NEW_INSTANCE_ID}) 
	set(${__OUT_NEW_INSTANCE_ID} ${__NEW_INSTANCE_ID} PARENT_SCOPE)
#	message(STATUS "${__PADDING}_rediscover_dependencies(): (old)__INSTANCE_ID: ${__INSTANCE_ID} __TEMPLATE_NAME: ${__TEMPLATE_NAME} __NEW_INSTANCE_ID: ${__NEW_INSTANCE_ID} __HASH_SOURCE: ${__HASH_SOURCE}")
#	message(STATUS "${__PADDING}_rediscover_dependencies(): __PARS__LIST_MODIFIERS: ${__PARS__LIST_MODIFIERS}")
	if("${__NEW_INSTANCE_ID}" STREQUAL "${__INSTANCE_ID}")
#		message(FATAL_ERROR "Internal beetroot error: Hashes did not change (but should have)")
		#Nothing to do
		return()
	endif()
	
	
	set(__PARENT_DISCOVERY_DEPTH 1)
	_discover_dependencies(${__NEW_INSTANCE_ID} ${__TEMPLATE_NAME} "${__TARGETS_CMAKE_PATH}" __ARGS __PARS __EXTERNAL_PROJECT_INFO ${__IS_TARGET_FIXED} __FILE_OPTIONS "" 0)

	_move_instance(${__INSTANCE_ID} ${__NEW_INSTANCE_ID})
	_add_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} COMPAT_INSTANCES ${__NEW_INSTANCE_ID})
endfunction()


# Function that calls declare_dependencies() and gathers all dependencies into the global storage. The dependency information is sufficient to properly call generate_target() or apply_to_target() user functions. 
# After the dependencies are gathered, the dependee instance is saved and is linked with those already declared dependencies (child instances)
function(_discover_dependencies __INSTANCE_ID __TEMPLATE_NAME __TARGETS_CMAKE_PATH __ARGS __PARS __EXTERNAL_PROJECT_INFO__REF __IS_TARGET_FIXED __FILE_OPTIONS__REF __ALL_TEMPLATE_NAMES __INCREASE_PADDING)
	if(__INCREASE_PADDING)
		_increase_padding()
	endif()
#	if("${__INSTANCE_ID}" STREQUAL "LIB_GRIDTOOLS_UPWIND_GPUBC_bd90ae98f168595c8037bf6df1102630")
#		message(FATAL_ERROR "HERE!")
#	endif()
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID) #Lack of the featurebase_id means that this
	# is the featurebase has not yet been defined, so it is the first context in which this instance is encountered.
	# In that case we must a do much more work, since featurebase contains all the information except how to link
	
	_make_path_hash("${__TARGETS_CMAKE_PATH}" __FILE_HASH)
	
#	if(__FEATUREBASE_ID)
#		message(STATUS "${__PADDING}_discover_dependencies(): __FEATUREBASE_ID: ${__FEATUREBASE_ID} for __INSTANCE_ID: ${__INSTANCE_ID}")
#		_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __FEATUREBASE_DEFINED )
#		message(STATUS "${__PADDING}_discover_dependencies(): DEP_INSTANCES: ${__FEATUREBASE_DEFINED} for __INSTANCE_ID: ${__INSTANCE_ID}")
#	else()
#		set(__FEATUREBASE_DEFINED)
#	endif()
#	message(STATUS "${__PADDING}_discover_dependencies(): __INSTANCE_ID: ${__INSTANCE_ID} __FEATUREBASE_ID: ${__FEATUREBASE_ID}")
	_can_descend_recursively(${__INSTANCE_ID} DEPENDENCIES __CAN_DESCEND)
	if(NOT __CAN_DESCEND)
		_get_recurency_list(DEPENDENCIES __INSTANCE_LIST)
		set(__OUT)
		list(GET __INSTANCE_LIST 0 __FIRST)
		foreach(__ITEM IN LISTS __INSTANCE_LIST)
			if(NOT "${__OUT}" STREQUAL "")
				set(__OUT "${__OUT}, which requires ")
			endif()
			set(__OUT "${__OUT}${__ITEM}")
		endforeach()
		set(__OUT "${__OUT}, which requires ${__FIRST} again.")
#		nice_list_output(LIST "${__INSTANCE_LIST}" OUTVAR __OUTVAR) #We cannot use nice_instance_output at this stage, because nothing is saved yet.
		message(FATAL_ERROR "Cyclic dependency graph encountered. ${__OUT}")
	endif()

   set(__FO_NAME)
   _parse_all_file_options(${__FILE_OPTIONS__REF} __FO)
   if(__FO_NAME)
      set(__NAME "${__FO_NAME}")
   else()
      set(__NAME "${__TEMPLATE_NAME}")
   endif()
	_put_dependencies_into_stack("${__INSTANCE_ID}" "${__NAME}")
	if(NOT __FEATUREBASE_ID) # i.e. this instance still does not have its featurebase
		set(__LIST ${${__PARS}__LIST_MODIFIERS})
		list(APPEND __LIST ${${__PARS}__LIST_FEATURES})
		list(APPEND __LIST ${${__PARS}__LIST_LINKPARS} )

#		message(STATUS "${__PADDING}Discovering dependencies for ${__TEMPLATE_NAME} (${__INSTANCE_ID})...")
#		message(STATUS "${__PADDING}_discover_dependencies(): ${__ARGS}_HALO_SIZE: ${${__ARGS}_HALO_SIZE}")
		_read_functions_from_targets_file("${__TARGETS_CMAKE_PATH}")
#		message(WARNING "_discover_dependencies(): list of variables: ${__LIST}")
		_instantiate_variables(${__ARGS} ${__PARS} "${__LIST}")
		set(__PARENT_ARGS_PREFIX ${__ARGS}) #So the get_existing_target can access the default values of all the relevant variables, so they can infer if user had changed them
		_descend_dependencies_stack()
		
		get_filename_component(__TEMPLATE_DIR "${__TARGETS_CMAKE_PATH}" DIRECTORY)
		get_property(__OLD_CALEE_PATH GLOBAL PROPERTY __BURAK_CALLEE_PATH)
		set_property(GLOBAL PROPERTY __BURAK_CALLEE_PATH "${__TARGETS_CMAKE_PATH}")
#		message(STATUS "${__PADDING}_discover_dependencies(): ${__TEMPLATE_NAME} (${__INSTANCE_ID}): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH}")

		set(__OLD_CALEE_PATH "${__TARGETS_CMAKE_PATH}")
		
		set(CMAKE_CURRENT_SOURCE_DIR "${__TEMPLATE_DIR}")
		set(__PARENT_ALL_VARIABLES ${${__ARGS}__LIST}) #Used by all entry functions like build_target or get_existing_target that define our dependencies to blank all our variables before executing _their_ declare_dependencies()
		

#		message(STATUS "${__PADDING}_discover_dependencies(): __TEMPLATE_NAME ${__TEMPLATE_NAME} got __INSTANCE_ID: ${__INSTANCE_ID}. HALO_SIZE: ${HALO_SIZE}")
   	_set_property_to_db(FILEDB     ${__FILE_HASH} FILE_OPTIONS       "${${__FILE_OPTIONS__REF}__LIST}")
   	_set_property_to_db(FILEDB     ${__FILE_HASH} EXTERNAL_INFO      "${${__EXTERNAL_PROJECT_INFO__REF}__LIST}")

      
#		message(STATUS "${__PADDING}_discover_dependencies(): __FILE_HASH: ${__FILE_HASH} __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH}")
      _populate_implicit_variables_for_file(${__FILE_HASH})
		_get_prev_dependencies_from_stack(__DEPENDENCY_OF_CURRENTLY_PROCESSED_TARGET __NICE_NAME_OF_CURRENTLY_PROCESSED_TARGET)
#   	message(STATUS "${__PADDING}_discover_dependencies(): __DEPENDENCY_OF_CURRENTLY_PROCESSED_TARGET: ${__DEPENDENCY_OF_CURRENTLY_PROCESSED_TARGET}")
		declare_dependencies(${__TEMPLATE_NAME}) #May call get_target() which will call _discover_dependencies() recursively
		
		set_property(GLOBAL PROPERTY __BURAK_CALLEE_PATH "${__OLD_CALEE_PATH}")
		_clear_variables(__PARENT_ALL_VARIABLES)
		_get_dependencies_from_stack(__DEP_INSTANCE_IDS)
		_get_value_from_stack(NICE_NAME __DEP_NICE_NAMES)
#   	message(STATUS "${__PADDING}_discover_dependencies(): __DEP_INSTANCE_IDS: ${__DEP_INSTANCE_IDS}")
		
		_get_value_from_stack(NAME_HINT __TARGET_NAME_HINT)
#   	message(STATUS "${__PADDING}_discover_dependencies(): Storing non-virtual __INSTANCE_ID: ${__INSTANCE_ID} with __TARGET_NAME_HINT: ${__TARGET_NAME_HINT}")
      
#		message(STATUS "${__PADDING}_discover_dependencies(): Discovered following dependencies for ${__TEMPLATE_NAME} (${__INSTANCE_ID}): ${__DEP_INSTANCE_IDS}")
      if("${__DEP_NICE_NAMES}" STREQUAL "")
		   message(STATUS "${__PADDING}Discovered no dependencies for ${__TEMPLATE_NAME}")
		else()
		   nice_list_output(OUTVAR __NICE_LIST LIST ${__DEP_NICE_NAMES})
   		message(STATUS "${__PADDING}Discovered following dependencies for ${__TEMPLATE_NAME}: ${__NICE_LIST}")
		endif()
		_ascend_dependencies_stack()

	endif()
	_ascend_from_recurency(${__INSTANCE_ID} DEPENDENCIES)
	_get_target_behavior(__GET_TARGET_BEHAVIOR)
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
		set(__TARGET_REQUIRED 1)
	else()
		set(__TARGET_REQUIRED 0)
	endif()
#	_get_parent_dependency_from_stack(__PARENT_INSTANCE_ID)
#	message(STATUS "${__PADDING}_discover_dependencies(): Acquired parent instance id: ${__PARENT_INSTANCE_ID} for ${__INSTANCE_ID}")
#	message(STATUS "${__PADDING}_discover_dependencies(): ${__ARGS}_FUNNAME: ${${__ARGS}_FUNNAME} ${__PARS}__LIST_FEATURES: ${${__PARS}__LIST_FEATURES}")
#	message(STATUS "${__PADDING}_discover_dependencies(): Storing non-virtual __INSTANCE_ID: ${__INSTANCE_ID} with ${__ARGS}_HALO_SIZE = ${${__ARGS}_HALO_SIZE}")

	# Now we know our dependencies and we can finally and properly save our instance. 
	# (or just confirm what we know in case we were called by rediscover_dependencies)..
	
#	message(STATUS "${__PADDING}_discover_dependencies(): __INSTANCE_ID: ${__INSTANCE_ID} __FILE_OPTIONS__REF ${__FILE_OPTIONS__REF}__LIST ${${__FILE_OPTIONS__REF}__LIST}")
	_store_nonvirtual_instance_data(
		 ${__INSTANCE_ID} 
		 ${__ARGS} 
		 ${__PARS} 
		 ${__TEMPLATE_NAME} 
		"${__TARGETS_CMAKE_PATH}" 
		 ${__IS_TARGET_FIXED}  
		 ${__EXTERNAL_PROJECT_INFO__REF} #This one is already stored into storage, just before calling declare_dependencies(). We may remove this argument in future
		 ${__TARGET_REQUIRED} 
		"${__TARGET_NAME_HINT}"
		 ${__FILE_OPTIONS__REF} #This one is already stored into storage, just before calling declare_dependencies(). We may remove this argument in future
		"${__ALL_TEMPLATE_NAMES}" __FILE_HASH __FEATUREBASE_ID)
	
	#... and update the link with the children (i.e. our dependencies)
	
	foreach(__DEP_ID IN LISTS __DEP_INSTANCE_IDS)
		_link_instances_together("${__INSTANCE_ID}" ${__DEP_ID} 0)
	endforeach()
	
	if(NOT __FEATUREBASE_ID)
		_store_instance_dependencies(${__INSTANCE_ID} "${__DEP_INSTANCE_IDS}")
	endif()
endfunction()

# Instantiates target. The function is called during the target building phase. 
# Must be called directly or indirectly by the finalize() function.
# Behavior is different on SUPERBUILD and in the project build.
function(_instantiate_target __INSTANCE_ID)
	if(__BEETROOT_DUMP)
		_dump_instance(${__INSTANCE_ID})
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE) # TARGET_BUILT is one of the FEATUREBASE properties, that will always be set to non empty (but maybe to "0") for non-virtual targets
	if(__IS_PROMISE)
		message(FATAL_ERROR "Cannot build ${__INSTANCE_ID} because it was only declared using get_existing_target(), and never actually defined by get_target().")
	else()
#		message(STATUS "${__PADDING}_instantiate_target(): __INSTANCE_ID: ${__INSTANCE_ID} F_TEMPLATE_NAME: ${__TARGET_IS_NON_VIRTUAL}")
	endif()
#	message(STATUS "${__PADDING}_instantiate_target(): __INSTANCE_ID: ${__INSTANCE_ID}")
	_retrieve_instance_data(${__INSTANCE_ID} TARGET_BUILT __DEP_BUILT)
	if(__DEP_BUILT)
		return()
	endif()
	_get_target_behavior(__TARGET_BEHAVIOR)
	if(NOT "${__TARGET_BEHAVIOR}" STREQUAL "DEFINING_TARGETS")
		message(FATAL_ERROR "Burak internal error: _get_dependencies() called when not DEFINIG_TARGETS")
	endif()
	
	
	_retrieve_instance_data(${__INSTANCE_ID} TARGET_BUILT __IS_TARGET_BUILT)
	if(__IS_TARGET_BUILT)
		return() #Nothing to do in this run
	endif()

	_make_instance_name(${__INSTANCE_ID} __TARGET_NAME)
	set(__DEP_TARGETS)
	_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __DEP_IDS)

	_retrieve_instance_data(${__INSTANCE_ID} I_PARENTS __PARENT_INSTANCE_IDS) #This variable is needed here only

#	message(STATUS "${__PADDING}_instantiate_target(): instance: ${__INSTANCE_ID} target name: ${__TARGET_NAME} requires __DEP_IDS: ${__DEP_IDS} and is required by ${__PARENT_INSTANCE_IDS}")
	# First we instantiate children (dependencies) as __DEP_TARGETS list:
	if(__DEP_IDS)
		foreach(__DEP_ID IN LISTS __DEP_IDS)
			_instantiate_target(${__DEP_ID})
			if(NOT __NOT_SUPERBUILD) #On superbuild the only targets we care about are external projects that are not assumed installed
				_retrieve_instance_data(${__INSTANCE_ID} EXTERNAL_INFO __EXTERNAL_INFO__LIST)
				_retrieve_instance_data(${__INSTANCE_ID} ASSUME_INSTALLED __ASSUME_INSTALLED)
			endif()
			if((__EXTERNAL_INFO__LIST AND NOT __ASSUME_INSTALLED) OR __NOT_SUPERBUILD)
				_make_instance_name(${__DEP_ID} __DEP_TARGET_NAME)
				if(__DEP_TARGET_NAME )
					list(APPEND __DEP_TARGETS ${__DEP_TARGET_NAME})
				endif()
			endif()
		endforeach()
#		message(STATUS "${__PADDING}_instantiate_target(): Gathered the following dependencies for ${__TARGET_NAME}: ${__DEP_TARGETS}")
	endif()
	if(NOT __NOT_SUPERBUILD)
		string(REPLACE "::" "_" __TARGET_NAME ${__TARGET_NAME})
	endif()
	
	# Then we call generate_targets()
	_retrieve_instance_data(${__INSTANCE_ID} EXTERNAL_INFO __EXTERNAL_PROJECT_INFO__LIST)
#	message(STATUS "${__PADDING}_instantiate_target(): __EXTERNAL_PROJECT_INFO__LIST: ${__EXTERNAL_PROJECT_INFO__LIST}")
	if(__EXTERNAL_PROJECT_INFO__LIST)
		#Handling external project
      if(NOT __NOT_SUPERBUILD)
#	message(STATUS "${__PADDING}_instantiate_target(): calling _get_target_external with __INSTANCE_ID: ${__INSTANCE_ID}, because it depends on ${__PARENT_INSTANCE_IDS}")
   		_get_target_external(${__INSTANCE_ID} "${__DEP_TARGETS}")
   	else()
			_get_target_internal(${__INSTANCE_ID} __TARGET_FUNCTION_EXISTS)
   	endif()
	else()
		if(__NOT_SUPERBUILD) # We ignore internal dependencies on SUPERBUILD phase
#			message(STATUS "${__PADDING}_instantiate_target(): __INSTANCE_ID: ${__INSTANCE_ID} __DEP_IDS: ${__DEP_IDS}")
			_get_target_internal(${__INSTANCE_ID} __TARGET_FUNCTION_EXISTS)
		endif()
	endif()
	# Finally it is a time to let the children be linked with us - we iterate over children again
   if(__NOT_SUPERBUILD) # We ignore internal dependencies on SUPERBUILD phase
	   foreach(__DEP_INSTANCE_ID IN LISTS __DEP_IDS)
		   _link_to_target(${__INSTANCE_ID} ${__DEP_INSTANCE_ID} __APPLY_FUNCTION_EXISTS)
	   endforeach()
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} TARGET_BUILT 1)
endfunction()

#Function links __DEP_INSTANCE_ID to dependee __INSTANCE_ID, by calling apply_dependency_to_target from DEP_INSTANCE_ID to INSTANCE_ID
#It is always called if INSTANCE_ID is not external on every pair of instances that are immidiately dependant
function(_link_to_target __DEPENDEE_INSTANCE_ID __OUR_INSTANCE_ID __OUT_FUNCTION_EXISTS)
	_make_instance_name(${__OUR_INSTANCE_ID} __OUR_TARGET_NAME)
	_make_instance_name(${__DEPENDEE_INSTANCE_ID} __DEPENDEE_TARGET_NAME)
	
#	message(STATUS "${__PADDING}_link_to_target(): __OUR_INSTANCE_ID: ${__OUR_INSTANCE_ID} __OUR_TARGET_NAME: ${__OUR_TARGET_NAME}")

   #If current child is not a target, we had no chance to apply its children's link dependencies (only target can receive dependencies). We need to give them that opportunity now.
	if(NOT TARGET ${__OUR_TARGET_NAME})
		_retrieve_instance_data(${__OUR_INSTANCE_ID} DEP_INSTANCES __DEP_IDS)
		foreach(__DEP_DEP_ID IN LISTS __DEP_IDS)
#			message(STATUS "${__PADDING}_link_to_target(): ${__DEPENDEE_INSTANCE_ID} dep: ${__OUR_INSTANCE_ID} -> depdep ${__DEP_DEP_ID}")	
			_link_to_target(${__DEPENDEE_INSTANCE_ID} ${__DEP_DEP_ID} __CHILD_FUNCTION_EXISTS)
		endforeach()
	endif()

	if(TARGET ${__DEPENDEE_TARGET_NAME})
		_retrieve_instance_data(${__OUR_INSTANCE_ID} DONT_LINK_TO_DEPENDEE __DONT_LINK_TO_DEPENDEE)
		_retrieve_instance_data(${__OUR_INSTANCE_ID} LINK_TO_DEPENDEE __LINK_TO_DEPENDEE)
   	_retrieve_instance_data(${__OUR_INSTANCE_ID} EXTERNAL_INFO __HAS_EXTERNAL_PROJECT__LIST)
   	if("${__HAS_EXTERNAL_PROJECT__LIST}" STREQUAL "")
   	   set(__HAS_EXTERNAL_PROJECT 0)
   	   set(__INSTALL_DIR "")
   	else()
#   	   message(STATUS "${__PADDING}_link_to_target(): __HAS_EXTERNAL_PROJECT__LIST: ${__HAS_EXTERNAL_PROJECT__LIST}")
         _parse_all_external_info(__HAS_EXTERNAL_PROJECT "EP")
 #  	   message(STATUS "${__PADDING}_link_to_target(): __PARSED_NAME: ${__PARSED_NAME}")
   	   set(__HAS_EXTERNAL_PROJECT 1)
	      _workout_install_dir_for_external(${__OUR_INSTANCE_ID} "${EP_INSTALL_PATH}" __INSTALL_DIR "__1" "__2" "__3" "__4" "__5" "__6" "__7")
   	endif()
#	   message(STATUS "${__PADDING}_link_to_target(): __INSTALL_DIR: ${__INSTALL_DIR}")

		_invoke_apply_dependency_to_target(${__DEPENDEE_INSTANCE_ID} ${__OUR_INSTANCE_ID} "${__INSTALL_DIR}" __FUNCTION_EXISTS)
#		if(NOT __FUNCTION_EXISTS AND __HAS_EXTERNAL_PROJECT)
#			_retrieve_instance_data(${__OUR_INSTANCE_ID} PATH __CMAKE_TARGETS_PATH)
#			__PARENT_ALL_VARIABLES_get_nice_instance_name_with_deps(__OUR_INSTANCE_ID __NICE_INSTANCE_NAME)
#			message(FATAL_ERROR "Beetroot error: External project ${${__NICE_INSTANCE_NAME}} defined in ${__CMAKE_TARGETS_PATH} does not have function apply_dependency_to_target() defined. External projects must define that function.")
#		endif()
#	else()
#		message(FATAL_ERROR "Template that does not produce targets: ${__DEPENDEE_TARGET_NAME} currently cannot have any dependencies")
#		message(STATUS "${__PADDING}_link_to_target(): __DEPENDEE_TARGET_NAME: ${__DEPENDEE_TARGET_NAME} __FUNCTION_EXISTS: ${__FUNCTION_EXISTS} __DONT_LINK_TO_DEPENDEE: ${__DONT_LINK_TO_DEPENDEE} __LINK_TO_DEPENDEE: ${__LINK_TO_DEPENDEE}")
		if(TARGET "${__OUR_TARGET_NAME}" AND __FUNCTION_EXISTS AND NOT __DONT_LINK_TO_DEPENDEE AND NOT __LINK_TO_DEPENDEE)
			_retrieve_instance_data(${__OUR_INSTANCE_ID} PATH __CMAKE_TARGETS_PATH)
			_get_nice_instance_name_with_deps(__DEPENDEE_INSTANCE_ID __NICE_INSTANCE_NAME)
			message(FATAL_ERROR "Beetroot error: User defined `apply_dependency_to_target()` in ${__CMAKE_TARGETS_PATH} (which was applied in context of the dependee target ${__NICE_INSTANCE_NAME}) and did not specified neither LINK_TO_DEPENDEE nor DONT_LINK_TO_DEPENDEE template option. Please decide whether you wish Beetroot to call `target_link_libraries()` after executing this function by setting the appropriate flag in the FILE_OPTIONS variable.")
		endif()
		_retrieve_instance_data(${__OUR_INSTANCE_ID} NO_TARGETS __NO_TARGETS)
#		message(STATUS "${__PADDING}_link_to_target(): __DEPENDEE_TARGET_NAME: ${__DEPENDEE_TARGET_NAME} __OUR_TARGET_NAME: ${__OUR_TARGET_NAME} __FUNCTION_EXISTS: ${__FUNCTION_EXISTS} __LINK_TO_DEPENDEE: ${__LINK_TO_DEPENDEE}" )
		if(NOT __FUNCTION_EXISTS OR __LINK_TO_DEPENDEE)
			if(TARGET "${__OUR_TARGET_NAME}" AND __OUR_TARGET_NAME)
				get_target_property(__TYPE ${__DEPENDEE_TARGET_NAME} TYPE)
				get_target_property(__DEP_TYPE ${__OUR_TARGET_NAME} TYPE)
	##			_get_target_language("${__OUR_TARGET_NAME}" __LANG)
#				message(STATUS "${__PADDING}_link_to_target(): about to call target_link_libraries:\n __DEPENDEE_INSTANCE_ID: ${__DEPENDEE_INSTANCE_ID} Linking ${__DEPENDEE_TARGET_NAME} to ${__OUR_TARGET_NAME}. __DEP_TYPE: ${__DEP_TYPE} __TYPE: ${__TYPE}")
				if("${__TYPE}" STREQUAL "INTERFACE_LIBRARY" )
					target_link_libraries(${__DEPENDEE_TARGET_NAME} INTERFACE ${__OUR_TARGET_NAME}) 
					set(__X INTERFACE)
				elseif(NOT "${__TYPE}" STREQUAL "UTILITY" AND NOT "${__DEP_TYPE}" STREQUAL "UTILITY" AND NOT "${__DEP_TYPE}" STREQUAL "EXECUTABLE")
					target_link_libraries(${__DEPENDEE_TARGET_NAME} PUBLIC ${__OUR_TARGET_NAME})
					set(__X LINK)
				endif()
			else()
				if(NOT __NO_TARGETS AND NOT __FUNCTION_EXISTS)
					_retrieve_instance_data(${__OUR_INSTANCE_ID} I_TEMPLATE_NAME __DEP_TEMPLATE_NAME )
					_retrieve_instance_data(${__OUR_INSTANCE_ID} PATH __CMAKE_TARGETS_PATH)
					_get_nice_instance_name_with_deps(__OUR_INSTANCE_ID __NICE_INSTANCE_NAME)
					message(FATAL_ERROR "${__DEP_TEMPLATE_NAME} defined in ${__CMAKE_TARGETS_PATH} did not produce target ${__OUR_TARGET_NAME} (${__NICE_INSTANCE_NAME}) and it does not define apply_dependency_to_target(). You must either define targets by defining generate_targets(TARGET_NAME TEMPLATE_NAME), or adding \"NO_TARGETS\" to CMake variable FILE_OPTIONS.")
				endif()
			endif()
		endif()
	endif()
endfunction()

#This function does not work - SOURCES property is usually empty
function(_get_target_language __TARGET_NAME __OUT_LANGUAGE)
#	message(STATUS "${__PADDING}_get_target_language(): get_target_property(__SOURCES ${__TAGET_NAME} SOURCES)")
	get_target_property(__SOURCES ${__TARGET_NAME} SOURCES)
	set(__COMMON_LANG)
#	message(STATUS "${__PADDING}_get_target_language(): __SOURCES: ${__SOURCES}")
	foreach(__SOURCE IN LISTS __SOURCES)
		get_property(__LANG SOURCE ${__SOURCE} PROPERTY LANGUAGE)
#		message(STATUS "${__PADDING}_get_target_language(): __LANG: ${__LANG}")
		if(NOT __COMMON_LANG)
			set(__COMMON_LANG ${__LANG})
		else()
			if(NOT "${__COMMON_LANG}" STREQUAL "${__LANG}")
				message(FATAL_ERROR "More than one language in source code")
			endif()
		endif()
	endforeach()
	set(${__OUT_LANGUAGE} "${__COMMON_LANG}" PARENT_SCOPE)
endfunction()

macro(_increase_padding)
	if("${__PARENT_DISCOVERY_DEPTH}" STREQUAL "")
		set(__PARENT_DISCOVERY_DEPTH 1)
	else()
		math(EXPR __PARENT_DISCOVERY_DEPTH "${__PARENT_DISCOVERY_DEPTH}+1")
	endif()
	math(EXPR __PADDING_SIZE "${__PARENT_DISCOVERY_DEPTH}*3")
	string(SUBSTRING "                         " 1 "${__PADDING_SIZE}" __PADDING)
endmacro()
