#     Global variables:
#
# Instance is a result of a single call to get_target() function. When finalaze() is called, each instance will be mapped to a single featureset and built. 
# Additionally, instance is a container for all its link parameters, and a container for the requested features.
#
# __INSTANCEDB_<INSTANCE_ID>_I_FEATURES       - Serialized list of feature names with their values that are passed to that instance. 
#                                               Does not apply if the target is singleton
# __INSTANCEDB_<INSTANCE_ID>_LINKPARS         - Serialized list of link parameters that are passed to that instance. 
# __INSTANCEDB_<INSTANCE_ID>_I_PARENTS        - List of instances that require this instance as their dependency
# __INSTANCEDB_<INSTANCE_ID>_IS_PROMISE       - Boolean. True means that this instance is incapable of spawning a target alone. It only holds features, but the system must
#                                               find the single featureset this instance can use (and perhaps expand with its own features)
# __INSTANCEDB_<INSTANCE_ID>_FEATUREBASE      - Pointer to the featureset that complements list of modifiers and is responsible for producing the target. 
#                                               For promises this one is initially empty.
# __INSTANCEDB_<INSTANCE_ID>_I_TEMPLATE_NAME  - Name of the template. Makes only sense when SINGLETON_TARGETS and there is more than one target, because it this case the
#                                               target's name (here: TEMPLATE_NAME) will not be remembered by FEATURESET. 
# __INSTANCEDB_<INSTANCE_ID>_TARGET_NAME      - Assigned name(s) of the target. Applies only for those featuresets that produce targets. 
#                                               Instances get target name only in second phase (DEFINING_TARGETS). 
#                                               If TARGET_FIXED target names are not generated, but taken from TEMPLATE_NAME.
# __INSTANCEDB_<INSTANCE_ID>_I_HASH_SOURCE    - String used to get an INSTANCE_ID (by hashing)
# __INSTANCEDB_<INSTANCE_ID>_IMP_VARS__LIST   - List of all imported variables from all dependencies. 
# __INSTANCEDB_<INSTANCE_ID>_IMP_VARS_${NAME} - Names of dependency for the imported variable.

#
# Featurebase is a common part of all targets that are mutually compatible with each other, but differ in their feature set.
# There is one-to-one mapping between featurebase and distinct built target (which might be the actual target, or the whole set of targets in case of singleton targets).
# Featurebase_ID is a hash of all modifiers + salt of either template name (for non-singleton targets) or path to the targets.cmake (for singleton targets).
# The purpose of feature resolution is to make sure all requested features by each instance are covered by the associated featurebase.
# __FEATUREBASEDB_<FEATURESET_ID>_F_INSTANCES          - List of all instances that are poiting to this featurebase. 
#                                                        Before instantiating all targets algorithm will iterate
#                                                        over all instances to find a common superset of features, if one exists (if it doesn't it will return an error)
# __FEATUREBASEDB_<FEATURESET_ID>_COMPAT_INSTANCES -     List of all instances that already have list of features 
#                                                        fully compatible with that of FEATUREBASE. 
#                                                        At the beginning the list is empty.
# __FEATUREBASEDB_<FEATURESET_ID>_DEP_INSTANCES        - List of all the dependencies id of the featureset.
# __FEATUREBASEDB_<FEATURESET_ID>_FEATURES             - Serialized list of features that are incorporated in this featureset.
# __FEATUREBASEDB_<FEATURESET_ID>_MODIFIERS            - Serialized values of all the modifiers' values
# __FEATUREBASEDB_<FEATURESET_ID>_F_TEMPLATE_NAME      - Name of the template. Makes sense only for non-singleton targets.
# __FEATUREBASEDB_<FEATURESET_ID>_F_PATH               - Path to the file that describes the template.
#                                                        For singleton targets this path is used to build FEATURESET_ID.
# __FEATUREBASEDB_<FEATURESET_ID>_TARGET_BUILT         - Boolean indicating that this particular FEATUREBASE has been defined in CMake, 
#                                                        and perhaps (if no NO_TARGETS) targets already exist. Empty for featurebase promises.
# __FEATUREBASEDB_<FEATURESET_ID>_F_HASH_SOURCE        - String used to get an FEATURESET_ID (by hashing)
# __FEATUREBASEDB_<FEATURESET_ID>_COMPATIBLE_INSTANCES - List of all instances that are guaranteed to have the same features as this featureset.
#                                                        At the beginning this list is empty, and it grows during the phase of
#                                                        resolving features (finalizer)

#
# __FILEDB_<PATH_HASH>_PATH                - Path to the file that defines this template
# __FILEDB_<PATH_HASH>_SINGLETON_TARGETS   - Boolean. TRUE means that all parameters to individual targets concern whole file (i.e. all the other targets). It implies TARGET_FIXED.
# __FILEDB_<PATH_HASH>_TARGET_FIXED        - Boolean. True means that there is only on target name for this template.
# __FILEDB_<PATH_HASH>_NO_TARGETS          - Boolean. TRUE means that this file does not produce targets: user must define apply_to_target() and must not define generate_targets().
# __FILEDB_<PATH_HASH>_G_INSTANCES         - List of all instance ids that are built using this file. 
# __FILEDB_<PATH_HASH>_G_FEATUREBASES      - List of all featurebases that are built using this file. If SINGLETON_TARGETS it will be exactly one FEATUREBASE.
# __FILEDB_<PATH_HASH>_PARS                - Serialized list of all parameters' definitions. 
# __FILEDB_<PATH_HASH>_DEFAULTS            - Serialized list of all parameters' actual default values.
# __FILEDB_<PATH_HASH>_EXTERNAL_INFO       - Serialized external project info
# __FILEDB_<PATH_HASH>_TARGETS_REQUIRED    - True means that we require this instance to generate a CMake target
# __FILEDB_<PATH_HASH>_LANGUAGES           - List of the languages required
# __FILEDB_<PATH_HASH>_ASSUME_INSTALLED    - Option relevant only if file describes external project. If true, it will be assumed that the project is already built
#                                            and no attempt will be made to build it.
# __FILEDB_<PATH_HASH>_NICE_NAME           - Nicely formatted name of the template. 
# __FILEDB_<PATH_HASH>_EXPORTED_VARS       - List of variables that will be embedded to the dependee of this template
# __FILEDB_<PATH_HASH>_INSTALL_DIR         - Installation directory. Makes sense only for external projects.
# __FILEDB_<PATH_HASH>_SOURCE_DIR          - Source directory. Does not makes sense if external project and ASSUME_INSTALLED
# 
# __BURAK_ALL_INSTANCES - list of all instance ID that are required by the top level
# __BURAK_ALL_LANGUAGES - list of all languages required by the built instances
# __BURAK_ALL_FEATUREBASES - list of all featurebases that still need to be processed to make sure they agree with the instances' features.

# __TEMPLATEDB_<TEMPLATE_NAME>_TEMPLATE_FEATUREBASES - List of all distinct featurebase IDs for that template name. 
# __TEMPLATEDB_<TEMPLATE_NAME>_VIRTUAL_INSTANCES - List of all virtual (i.e. created using get_existing_target()) for that template
#
macro(_get_db_columns __COLS)
	set(${__COLS}_I_FEATURES           INSTANCEDB )
	set(${__COLS}_LINKPARS             INSTANCEDB )
	set(${__COLS}_I_PARENTS            INSTANCEDB )
	set(${__COLS}_IS_PROMISE           INSTANCEDB )
	set(${__COLS}_FEATUREBASE          INSTANCEDB )
	set(${__COLS}_I_TEMPLATE_NAME      INSTANCEDB )
	set(${__COLS}_TARGET_NAME          INSTANCEDB )
	set(${__COLS}_I_HASH_SOURCE        INSTANCEDB )
	set(${__COLS}_IMP_VARS__LIST       INSTANCEDB )
	
	set(${__COLS}_F_INSTANCES          FEATUREBASEDB )
	set(${__COLS}_COMPAT_INSTANCES     FEATUREBASEDB )
	set(${__COLS}_DEP_INSTANCES        FEATUREBASEDB )
	set(${__COLS}_F_FEATURES           FEATUREBASEDB )
	set(${__COLS}_MODIFIERS            FEATUREBASEDB )
	set(${__COLS}_F_TEMPLATE_NAME      FEATUREBASEDB )
	set(${__COLS}_F_PATH               FEATUREBASEDB )
	set(${__COLS}_TARGET_BUILT         FEATUREBASEDB )
	set(${__COLS}_F_HASH_SOURCE        FEATUREBASEDB )
	set(${__COLS}_COMPATIBLE_INSTANCES FEATUREBASEDB )
	
	
	set(${__COLS}_PATH                 FILEDB )
	set(${__COLS}_SINGLETON_TARGETS    FILEDB )
	set(${__COLS}_TARGET_FIXED         FILEDB )
	set(${__COLS}_NO_TARGETS           FILEDB )
	set(${__COLS}_G_INSTANCES          FILEDB )
	set(${__COLS}_G_FEATUREBASES       FILEDB )
	set(${__COLS}_PARS                 FILEDB )
	set(${__COLS}_DEFAULTS             FILEDB )
	set(${__COLS}_EXTERNAL_INFO        FILEDB )
	set(${__COLS}_TARGETS_REQUIRED     FILEDB )
	set(${__COLS}_LANGUAGES            FILEDB )
	set(${__COLS}_ASSUME_INSTALLED     FILEDB )
	set(${__COLS}_NICE_NAME            FILEDB )
	set(${__COLS}_EXPORTED_VARS        FILEDB )
	set(${__COLS}_INSTALL_DIR          FILEDB )
	set(${__COLS}_SOURCE_DIR           FILEDB )
	
	
	set(${__COLS}_TEMPLATE_FEATUREBASES  TEMPLATEDB )
	set(${__COLS}_VIRTUAL_INSTANCES      TEMPLATEDB )
endmacro()

function(_make_path_hash __TARGETS_CMAKE_PATH __OUT_HASH)
	if(NOT __TARGETS_CMAKE_PATH)
		message(FATAL_ERROR "Internal Beetroot error: __TARGETS_CMAKE_PATH should not be empty")
	endif()
	string(MD5 __TMP ${__TARGETS_CMAKE_PATH})
	string(SUBSTRING ${__TMP} 1 6 __TMP)
	if("${__TMP}" STREQUAL "")
		meesage(FATAL_ERROR "path hash cannot come up empty")
	endif()
	set(${__OUT_HASH} ${__TMP} PARENT_SCOPE)
endfunction()

function(_make_featurebase_hash_2 __SERIALIZED_MODIFIERS __SERIALIZED_FEATURES __TEMPLATE_NAME __PATH __SINGLETON_TARGETS __OUT_HASH __OUT_HASH_SOURCE)
	if(__SINGLETON_TARGETS)
		set(__TMP "${__PATH}")
	else()
		set(__TMP "${__TEMPLATE_NAME}")
	endif()
	set(__TMP "${__TMP}|${__SERIALIZED_MODIFIERS}|${__SERIALIZED_FEATURES}")
	set(${__OUT_HASH_SOURCE} "${__TMP}" PARENT_SCOPE)
	string(MD5 __HASH "${__TMP}")
	string(SUBSTRING ${__HASH} 1 8 __OUT)
#	message(STATUS "_make_featurebase_hash_2(): __TMP (ID|MODIFIERS|FEATURES): ${__TMP} got hash ${__OUT}")
	if("${__TMP}" STREQUAL "")
		meesage(FATAL_ERROR "featurebase hash cannot come up empty")
	endif()
	set(${__OUT_HASH} "${__OUT}" PARENT_SCOPE)
endfunction()

function(_make_featurebase_hash_1 __MODS __MODS_LIST __FEATS __FEATS__LIST __TEMPLATE_NAME __PATH __SINGLETON_TARGETS __OUT_HASH __OUT_HASH_SOURCE)
	_serialize_variables(${__MODS} "${__MODS__LIST}" __SERIALIZED_MODIFIERS)
	_serialize_variables(${__FEATS} "${__FEATS__LIST}" __SERIALIZED_FEATURES)
#	_make_featurebase_hash_2("${__SERIALIZED_MODIFIERS}" "${__SERIALIZED_FEATURES}" ${__TEMPLATE_NAME} "${__PATH}" ${__SINGLETON_TARGETS} __OUT) We remove features from featurebase hash
	_make_featurebase_hash_2("${__SERIALIZED_MODIFIERS}" "" ${__TEMPLATE_NAME} "${__PATH}" ${__SINGLETON_TARGETS} __HASH __HASH_SOURCE)
	set(${__OUT_HASH} "${__HASH}" PARENT_SCOPE)
	set(${__OUT_HASH_SOURCE} "${__HASH_SOURCE}" PARENT_SCOPE)
endfunction()

function(_store_instance_data __INSTANCE_ID __PARENT_INSTANCE_ID __ARGS __PARS __TEMPLATE_NAME __TARGETS_CMAKE_PATH __IS_TARGET_FIXED __EXTERNAL_PROJECT_INFO __TARGET_REQUIRED __TEMPLATE_OPTIONS)
	_parse_file_options(${__INSTANCE_ID} "${__TARGETS_CMAKE_PATH}" ${__IS_TARGET_FIXED} "${__TEMPLATE_OPTIONS}" __SINGLETON_TARGETS __NO_TARGETS __LANGUAGES __NICE_NAME __EXPORTED_VARS)
	if(__EXPORTED_VARS)
		foreach(__EVAR IN LISTS __EXPORTED_VARS)
			if(NOT "${__EVAR}" IN_LIST ${__PARS}__LIST)
				message(FATAL_ERROR "Cannot export a variable ${__EVAR} that is not defined as a parameter/feature (${__EXPORTED_VARS})")
			endif()
		endforeach()
	endif()
#	message(STATUS "_store_instance_data(): __LANGUAGES: ${__LANGUAGES}")
	_serialize_variables(${__ARGS} "${${__PARS}__LIST_FEATURES}" __SERIALIZED_FEATURES)
	_serialize_variables(${__ARGS} "${${__PARS}__LIST_MODIFIERS}" __SERIALIZED_MODIFIERS)
	_serialize_variables(${__ARGS} "${${__PARS}__LIST_LINKPARS}" __SERIALIZED_LINKPARS)
#	message(STATUS "_store_instance_data(): __SERIALIZED_FEATURES: ${__SERIALIZED_FEATURES}")
#	message(STATUS "_store_instance_data(): __SERIALIZED_MODIFIERS: ${__SERIALIZED_MODIFIERS}")
#	message(STATUS "_store_instance_data(): __SERIALIZED_LINKPARS: ${__SERIALIZED_LINKPARS}")
	_serialize_parameters(${__PARS} __SERIALIZED_PARAMETERS)
	_make_featurebase_hash_2("${__SERIALIZED_MODIFIERS}" "${__SERIALIZED_FEATURES}" ${__TEMPLATE_NAME} "${__TARGETS_CMAKE_PATH}" ${__IS_TARGET_FIXED} __FEATUREBASE_ID __FEATUREBASE_HASH_SOURCE)
#	message(STATUS "_store_instance_data(): __INSTANCE_ID ${__INSTANCE_ID} got __FEATUREBASE_ID: ${__FEATUREBASE_ID}")
	_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH)

#	message(FATAL_ERROR "__ARGS_LIST_MODIFIERS: ${__ARGS_LIST_MODIFIERS}")
#	if("${__INSTANCE_ID}" STREQUAL "SerialboxStatic_18768807d4b4034c1c5d4dd0f5ba6964")
#		message(FATAL_ERROR "__EXTERNAL_PROJECT_INFO: ${__EXTERNAL_PROJECT_INFO}")
 #	endif()
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_FEATURES            "${__SERIALIZED_FEATURES}")
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} LINKPARS              "${__SERIALIZED_LINKPARS}")
	_add_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_PARENTS             "${__PARENT_INSTANCE_ID}")
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} IS_PROMISE            "0")
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} FEATUREBASE            ${__FEATUREBASE_ID})
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __TMP)
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_TEMPLATE_NAME        ${__TEMPLATE_NAME})
	if(__IS_TARGET_FIXED)
#		message(STATUS "_store_instance_data(): Storing fixed target name for ${__INSTANCE_ID}: ${__TEMPLATE_NAME}")
		_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} TARGET_NAME  ${__TEMPLATE_NAME})
	endif()
	
#	message(STATUS "_store_instance_data(): __INSTANCE_ID: ${__INSTANCE_ID} __FEATUREBASE_ID: ${__FEATUREBASE_ID} __PATH_HASH: ${__PATH_HASH}")
	unset(__FOUND_TMP)
	_retrieve_instance_data(${__INSTANCE_ID} F_INSTANCES __FOUND_TMP)
	if(NOT "${__FOUND_TMP}" STREQUAL "")
#		message(STATUS "_store_instance_data(): Featurebase ${__FEATUREBASE_ID} already defined for instances ${__FOUND_TMP}. Adding another instance: ${__INSTANCE_ID} ")
	else()
		_add_property_to_db(BURAK ALL FEATUREBASES ${__FEATUREBASE_ID})
	endif()
	_add_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_INSTANCES           ${__INSTANCE_ID})
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_FEATURES           "${__SERIALIZED_FEATURES}")
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} MODIFIERS            "${__SERIALIZED_MODIFIERS}")
	if(NOT __IS_TARGET_FIXED)
		_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_TEMPLATE_NAME       ${__TEMPLATE_NAME})
	endif()
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_PATH               "${__TARGETS_CMAKE_PATH}")
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} TARGET_BUILT          0)
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_HASH_SOURCE         "${__FEATUREBASE_HASH_SOURCE}")

	_add_property_to_db(TEMPLATEDB ${__TEMPLATE_NAME} TEMPLATE_FEATUREBASES        ${__FEATUREBASE_ID})

	if(__EXTERNAL_PROJECT_INFO)
		_parse_external_info("${__EXTERNAL_INFO}" "${__TARGETS_CMAKE_PATH}" ASSUME_INSTALLED __ASSUME_INSTALLED)
	else()
		set(__ASSUME_INSTALLED)
	endif()
	_set_property_to_db(FILEDB     ${__PATH_HASH} PATH                 "${__TARGETS_CMAKE_PATH}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} SINGLETON_TARGETS    "${__SINGLETON_TARGETS}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} TARGET_FIXED         "${__IS_TARGET_FIXED}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} NO_TARGETS           "${__NO_TARGETS}")
	_add_property_to_db(FILEDB     ${__PATH_HASH} G_INSTANCES           ${__INSTANCE_ID})
	_add_property_to_db(FILEDB     ${__PATH_HASH} G_FEATUREBASES        ${__FEATUREBASE_ID})
	_set_property_to_db(FILEDB     ${__PATH_HASH} PARS                 "${__SERIALIZED_PARAMETERS}")
	if(__SERIALIZED_PARAMETERS)
		_retrieve_instance_data(${__INSTANCE_ID} DEFAULTS __SERIALIZED_DEFAULTS)
		if(NOT __SERIALIZED_DEFAULTS)
			#We reset all the variables, so we can learn about the defaults
			foreach(__VAR IN LISTS ${__PARS}__LIST)
				set(${__VAR})
			endforeach()
			_get_variables("${__TARGETS_CMAKE_PATH}" "defaults" "" 0 __DEFAULTS __TMP_PARS __TMP_TEMPLATE_NAMES __TMP_EXTERNAL_PROJECT_INFO __TMP_IS_TARGET_FIXED __TMP_GLOBAL_OPTIONS)
			_serialize_variables(__DEFAULTS "${__DEFAULTS__LIST}" __SERIALIZED_DEFAULTS)
#			message(STATUS "_store_instance_data(): __SERIALIZED_DEFAULTS: ${__SERIALIZED_DEFAULTS}")
		endif()
		_set_property_to_db(FILEDB     ${__PATH_HASH} DEFAULTS             "${__SERIALIZED_DEFAULTS}")
	endif()
	_set_property_to_db(FILEDB     ${__PATH_HASH} EXTERNAL_INFO        "${__EXTERNAL_PROJECT_INFO}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} TARGETS_REQUIRED      ${__TARGET_REQUIRED})
	_set_property_to_db(FILEDB     ${__PATH_HASH} LANGUAGES            "${__LANGUAGES}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} ASSUME_INSTALLED     "${__ASSUME_INSTALLED}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} NICE_NAME            "${__NICE_NAME}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} EXPORTED_VARS        "${__EXPORTED_VARS}")

	_get_stack_depth(__STACK_DEPTH)
	if("${__STACK_DEPTH}" STREQUAL "0")
#		message(STATUS "_store_instance_data(): ADDING GLOBAL INSTANCE: ${__INSTANCE_ID}")
		_add_property_to_db(BURAK ALL INSTANCES "${__INSTANCE_ID}")
	endif()
	
#	_append_instance_modifiers_hash(${__INSTANCE_ID} ${__TEMPLATE_NAME} ${__ARGS} "${__ARGS_LIST_MODIFIERS}")
endfunction()

function(_store_instance_dependencies __INSTANCE_ID __DEP_LIST)
#	message(STATUS "_store_instance_data(): __INSTANCE_ID: ${__INSTANCE_ID} __DEP_LIST: ${__DEP_LIST}")
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __FEATUREBASE_ID)
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} DEP_INSTANCES        "${__DEP_LIST}")
endfunction()

#Stores just enough information to store template id, features and target parameters (modifiers). Essentially enough to set a link to the existing FILEDB and FEATUREBASEDB.
#It excludes dependencies. 
function(_store_instance_link_data __INSTANCE_ID __PARENT_INSTANCE_ID __ARGS __PARS __TEMPLATE_NAME __TARGETS_CMAKE_PATH __IS_TARGET_FIXED __EXTERNAL_PROJECT_INFO __TARGET_REQUIRED __TEMPLATE_OPTIONS)

	_parse_file_options(${__INSTANCE_ID} "${__TARGETS_CMAKE_PATH}" ${__IS_TARGET_FIXED} "${__TEMPLATE_OPTIONS}" __SINGLETON_TARGETS __NO_TARGETS __LANGUAGES __NICE_NAME __EXPORTED_VARS)
	_serialize_variables(${__ARGS} "${${__PARS}__LIST_FEATURES}" __SERIALIZED_FEATURES)
	_serialize_variables(${__ARGS} "${${__PARS}__LIST_MODIFIERS}" __SERIALIZED_MODIFIERS)
	_serialize_variables(${__ARGS} "${${__PARS}__LIST_LINKPARS}" __SERIALIZED_LINKPARS)
#	message(STATUS "_store_instance_data(): __SERIALIZED_FEATURES: ${__SERIALIZED_FEATURES}")
#	message(STATUS "_store_instance_data(): __SERIALIZED_MODIFIERS: ${__SERIALIZED_MODIFIERS}")
#	message(STATUS "_store_instance_data(): __SERIALIZED_LINKPARS: ${__SERIALIZED_LINKPARS}")
	_serialize_parameters(${__PARS} __SERIALIZED_PARAMETERS)
	_make_featurebase_hash_2("${__SERIALIZED_MODIFIERS}" "${__SERIALIZED_FEATURES}" ${__TEMPLATE_NAME} "${__TARGETS_CMAKE_PATH}" ${__SINGLETON_TARGETS} __FEATUREBASE_ID __FEATUREBASE_HASH_SOURCE)
	_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH)

#	message(FATAL_ERROR "__ARGS_LIST_MODIFIERS: ${__ARGS_LIST_MODIFIERS}")
#	if("${__INSTANCE_ID}" STREQUAL "SerialboxStatic_18768807d4b4034c1c5d4dd0f5ba6964")
#		message(FATAL_ERROR "__EXTERNAL_PROJECT_INFO: ${__EXTERNAL_PROJECT_INFO}")
 #	endif()
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_FEATURES            "${__SERIALIZED_FEATURES}")
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} LINKPARS              "${__SERIALIZED_LINKPARS}")
	_add_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_PARENTS             "${__PARENT_INSTANCE_ID}")
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} IS_PROMISE            "0")
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} FEATUREBASE            ${__FEATUREBASE_ID})
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __TMP)
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_TEMPLATE_NAME        ${__TEMPLATE_NAME})
	if(__IS_TARGET_FIXED)
#		message(STATUS "_store_instance_data(): Storing fixed target name for ${__INSTANCE_ID}: ${__TEMPLATE_NAME}")
		_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} TARGET_NAME  ${__TEMPLATE_NAME})
	endif()
	
#	message(STATUS "_store_instance_data(): __INSTANCE_ID: ${__INSTANCE_ID} __FEATUREBASE_ID: ${__FEATUREBASE_ID} __PATH_HASH: ${__PATH_HASH}")
	unset(__FOUND_TMP)
	_retrieve_instance_data(${__INSTANCE_ID} F_INSTANCES __FOUND_TMP)
	if(NOT "${__FOUND_TMP}" STREQUAL "")
#		message(STATUS "_store_instance_data(): Featurebase ${__FEATUREBASE_ID} already defined for instances ${__FOUND_TMP}. Adding another instance: ${__INSTANCE_ID} ")
	else()
		_add_property_to_db(BURAK ALL FEATUREBASES ${__FEATUREBASE_ID})
	endif()
	_add_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_INSTANCES           ${__INSTANCE_ID})
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_PATH               "${__TARGETS_CMAKE_PATH}")
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_HASH_SOURCE        "${__FEATUREBASE_HASH_SOURCE}")

	_add_property_to_db(FILEDB     ${__PATH_HASH} G_INSTANCES           ${__INSTANCE_ID})

	_get_stack_depth(__STACK_DEPTH)

	if("${__STACK_DEPTH}" STREQUAL "0")
#		message(STATUS "_store_instance_data(): ADDING GLOBAL INSTANCE: ${__INSTANCE_ID}")
		_add_property_to_db(BURAK ALL INSTANCES "${__INSTANCE_ID}")
	endif()

	_add_property_to_db(TEMPLATEDB ${__TEMPLATE_NAME} VIRTUAL_INSTANCES        ${__INSTANCE_ID})

endfunction()

function(_store_target_modification_data __INSTANCE_ID __PARENT_INSTANCE_ID __FEATURES __FEATURES_LIST __TEMPLATE_NAME)
	_serialize_variables(${__FEATURES} "${__FEATURES__LIST}" __SERIALIZED_VARIABLES)
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} VARS               "${__SERIALIZED_VARIABLES}")
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} TEMPLATE           "${__TEMPLATE_NAME}")
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} IS_MODIFICATION    "1")
	_add_property_to_db(INSTANCEDB ${__INSTANCE_ID} PARENTS            "${__PARENT_INSTANCE_ID}")
	_add_property_to_db(BURAK ALL MODIFICATIONS "${__INSTANCE_ID}")
endfunction()

function(_add_property_to_db __DB_NAME __KEY __PROPERTY_NAME __ITEM )
	get_property(__ITEMS GLOBAL PROPERTY __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME})
	if(NOT ${__ITEM} IN_LIST __ITEMS)
		set_property(GLOBAL APPEND PROPERTY __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME} "${__ITEM}")
	endif()
endfunction()

function(_remove_property_from_db __DB_NAME __KEY __PROPERTY_NAME __ITEM )
	get_property(__ITEMS GLOBAL PROPERTY __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME})
	if(${__ITEM} IN_LIST __ITEMS)
		list(REMOVE_ITEM __ITEMS "${__ITEM}")
		set_property(GLOBAL PROPERTY __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME} "${__ITEMS}")
	else()
		message(FATAL_ERROR "Item ${__ITEM} does not exist in the __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME}")
	endif()
endfunction()

function(_set_property_to_db __DB_NAME __KEY __PROPERTY_NAME __PROPERTY_VALUE )
	get_property(__TMP GLOBAL PROPERTY __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME})
	if(__TMP)
		if(NOT "${__TMP}" STREQUAL "${__PROPERTY_VALUE}")
			message(FATAL_ERROR "Internal beetroot error. Trying to re-write __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME} with a new value \"${__PROPERTY_VALUE}\" that is different from the old value \"${__TMP}\".")
		endif()
	else()
#		message(STATUS "_set_property_to_db(): Setting __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME} to ${__PROPERTY_VALUE}")
		set_property(GLOBAL PROPERTY __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME} "${__PROPERTY_VALUE}")
	endif()
endfunction()

function(_retrieve_instance_data __INSTANCE_ID __PROPERTY __OUT)
	_get_db_columns(__COLS)
#	if("${__PROPERTY}" STREQUAL "INSTALL_DIR")
#		message(STATUS "_retrieve_instance_data(): trying to get property ${__PROPERTY} using __INSTANCE_ID ${__INSTANCE_ID}...")
#	endif()
	if(NOT __COLS_${__PROPERTY})
		message(FATAL_ERROR "Internal Beetroot error: Cannot find the property ${__PROPERTY}")
	endif()
	if("${__COLS_${__PROPERTY}}" STREQUAL "INSTANCEDB")
		set(__KEY "${__INSTANCE_ID}")
	elseif("${__COLS_${__PROPERTY}}" STREQUAL "FEATUREBASEDB")
		_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __KEY)
#		message(STATUS "_retrieve_instance_data(): __INSTANCE_ID: ${__INSTANCE_ID} get FEATUREBASE: ${__KEY}")
	elseif("${__COLS_${__PROPERTY}}" STREQUAL "TEMPLATEDB")
		_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __KEY)
	elseif("${__COLS_${__PROPERTY}}" STREQUAL "FILEDB")
		_retrieve_instance_data(${__INSTANCE_ID} F_PATH __PATH)
		_make_path_hash("${__PATH}" __KEY)
	else()
		message(FATAL_ERROR "Internal Beetroot error: Cannot find the database ${__COLS_${__PROPERTY}} indicated by variable __COLS_${__PROPERTY}")
	endif()
	if("${__KEY}" STREQUAL "")
		message(FATAL_ERROR "Internal beetroot error: missing key ${__KEY} for db ${__COLS_${__PROPERTY}}")
	endif()
#	if("${__PROPERTY}" STREQUAL "INSTALL_DIR")
#		message(STATUS "_retrieve_instance_data(): trying to get property ${__PROPERTY} using KEY ${__KEY}...")
#	endif()
	get_property(__TMP GLOBAL PROPERTY __${__COLS_${__PROPERTY}}_${__KEY}_${__PROPERTY})
	if("${__TMP}" STREQUAL "")
#		message(WARNING "__${__COLS_${__PROPERTY}}_${__KEY}_${__PROPERTY} is not defined")
	endif()
#	message(STATUS "_retrieve_instance_data(): __${__COLS_${__PROPERTY}}_${__KEY}_${__PROPERTY} is ${__TMP}")
	set(${__OUT} "${__TMP}" PARENT_SCOPE)
endfunction()

function(_retrieve_featurebase_data __FEATUREBASE_ID __PROPERTY __OUT)
	_get_db_columns(__COLS)
	if(NOT __COLS_${__PROPERTY})
		message(FATAL_ERROR "Internal Beetroot error: Cannot find the property ${__PROPERTY}")
	endif()
	if("${__COLS_${__PROPERTY}}" STREQUAL "INSTANCEDB")
		message(FATAL_ERROR "Internal error: Cannot retrieve instance column using template name")
	elseif("${__COLS_${__PROPERTY}}" STREQUAL "FEATUREBASEDB")
		set(__KEY "${__FEATUREBASE_ID}")
	elseif("${__COLS_${__PROPERTY}}" STREQUAL "TEMPLATEDB")
		_retrieve_instance_data(${__INSTANCE_ID} F_TEMPLATE_NAME __KEY)
	elseif("${__COLS_${__PROPERTY}}" STREQUAL "FILEDB")
		_retrieve_template_data(${__FEATUREBASE_ID} PATH __PATH)
		_make_path_hash("${__PATH}" __KEY)
	else()
		message(FATAL_ERROR "Internal Beetroot error: Cannot find the database ${__COLS_${__PROPERTY}} indicated by variable __COLS_${__PROPERTY}")
	endif()
	get_property(__TMP GLOBAL PROPERTY __${__COLS_${__PROPERTY}}_${__KEY}_${__PROPERTY})
	set(${__OUT} "${__TMP}" PARENT_SCOPE)
endfunction()

function(_retrieve_file_data __PATH_HASH __PROPERTY __OUT)
	_get_db_columns(__COLS)
	if(NOT __COLS_${__PROPERTY})
		message(FATAL_ERROR "Internal Beetroot error: Cannot find the property ${__PROPERTY}")
	endif()
	if("${__COLS_${__PROPERTY}}" STREQUAL "INSTANCEDB")
		message(FATAL_ERROR "Internal error: Cannot retrieve instance column using file path")
	elseif("${__COLS_${__PROPERTY}}" STREQUAL "FEATUREBASEDB" OR "${__COLS_${__PROPERTY}}" STREQUAL "TEMPLATEDB")
		_retrieve_file_data("${__TARGETS_CMAKE_PATH}" IS_SINGLETON __IS_SINGLETON)
		if(__IS_SINGLETON)
			_retrieve_file_data("${__PATH_HASH}" G_FEATUREBASES __FEATUREBASE_ID)
			_retrieve_featurebase_data(${__FEATUREBASE_ID} ${__PROPERTY} __OUT_INNER)
			set(${__OUT} "${__OUT_INNER}" PARENT_SCOPE)
			return()
		else()
			message(FATAL_ERROR "Internal error: Cannot retrieve featurebase column using file path unless file is IS_SINGLETON")
		endif()
	elseif("${__COLS_${__PROPERTY}}" STREQUAL "FILEDB")
		get_property(__TMP GLOBAL PROPERTY __${__COLS_${__PROPERTY}}_${__PATH_HASH}_${__PROPERTY})
		set(${__OUT} "${__TMP}" PARENT_SCOPE)
	else()
		message(FATAL_ERROR "Internal Beetroot error: Cannot find the database ${__COLS_${__PROPERTY}} indicated by variable __COLS_${__PROPERTY}")
	endif()
endfunction()

macro(_retrieve_file_args __PATH_HASH __PROPERTY __OUT)
	_retrieve_file_data("${__PATH_HASH}" ${__PROPERTY} __TMP_SER_VARS)
	_unserialize_variables("${__TMP_SER_VARS}" ${__OUT})
endmacro()

macro(_retrieve_featurebase_args __FEATUREBASE_ID __PROPERTY __OUT)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} ${__PROPERTY} __TMP_SER_VARS)
	_unserialize_variables("${__TMP_SER_VARS}" ${__OUT})
endmacro()

macro(_retrieve_instance_args __INSTANCE_ID __PROPERTY __OUT)
	_retrieve_instance_data(${__INSTANCE_ID} ${__PROPERTY} __TMP_SER_VARS)
#	message(STATUS "_retrieve_instance_args(): __TMP_SER_VARS: ${__TMP_SER_VARS}")
	_unserialize_variables("${__TMP_SER_VARS}" ${__OUT})
endmacro()

macro(_retrieve_instance_pars __INSTANCE_ID __OUT)
	_retrieve_instance_data(${__INSTANCE_ID} PARS __TMP_SER_PARS)
	_unserialize_parameters("${__TMP_SER_PARS}" ${__OUT})
endmacro()

#macro(_retrieve_all_instance_data __INSTANCE_ID 
# __OUT_ARGS __OUT_DEP_LIST __OUT_TEMPLATE_NAME __OUT_TARGETS_CMAKE_PATH __OUT_IS_TARGET_FIXED __OUT_EXTERNAL_PROJECT_INFO __OUT_TARGET_REQUIRED )
#	_retrieve_instance_args(${__INSTANCE_ID} ${__OUT_ARGS})
#	_retrieve_instance_data(${__INSTANCE_ID} DEPS 			${__OUT_DEP_LIST})
#	_retrieve_instance_data(${__INSTANCE_ID} TEMPLATE 		${__OUT_TEMPLATE_NAME})
#	_retrieve_instance_data(${__INSTANCE_ID} PATH 			${__OUT_TARGETS_CMAKE_PATH})
#	_retrieve_instance_data(${__INSTANCE_ID} TARGET_FIXED 	${__OUT_IS_TARGET_FIXED})
#	_retrieve_instance_data(${__INSTANCE_ID} EXTERNAL_INFO 	${__OUT_EXTERNAL_PROJECT_INFO})
#	_retrieve_instance_data(${__INSTANCE_ID} REQUIRED 		${__OUT_TARGET_REQUIRED})
#	_retrieve_instance_data(${__INSTANCE_ID} OPTIONS 		${__OUT_TEMPLATE_OPTIONS})
#endmacro()

macro(_get_all_instance_ids __OUT_INSTANCE_ID_LIST) 
	get_property("${__OUT_INSTANCE_ID_LIST}" GLOBAL PROPERTY __BURAK_ALL_INSTANCES)
endmacro()

macro(_get_all_instance_modifications __OUT_INSTANCE_ID_LIST)
	get_property("${__OUT_INSTANCE_ID_LIST}" GLOBAL PROPERTY __BURAK_ALL_MODIFICATIONS)
endmacro()

#function(_get_number_of_instance_modifier_hashes __TEMPLATE_NAME __OUT_INSTANCE_COUNT)
#	_retrieve_instance_data(${__INSTANCE_ID} TEMPLATE_FEATUREBASES __HASHES)
#	list(LENGTH __HASHES __COUNT)
#	set(${__OUT_INSTANCE_COUNT} "${__COUNT}" PARENT_SCOPE)
#endfunction()

