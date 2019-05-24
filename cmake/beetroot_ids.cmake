
# Calculates hash of the ARGS prefix. 
# The hash is independent from the order in which ARGS is layed out, because it first sorts it.
# It also appends __EXTRA_STRING to the hashed string, so it can encode some extra information as well (e.g. template name)
function(_calculate_hash __PREFIX __VAR_LIST __EXTRA_STRING __OUT_HASH __OUT_HASH_SOURCE)
	set(__STRING_SO_FAR "${__EXTRA_STRING}")
#	message(STATUS "_calculate_hash(): __EXTRA_STRING=${__EXTRA_STRING} __LIST_MODIFIERS=${${__PREFIX}__LIST_MODIFIERS}")
	if(__VAR_LIST)
		list(SORT __VAR_LIST COMPARE STRING CASE INSENSITIVE ORDER ASCENDING)
		foreach(__ARG IN LISTS __VAR_LIST)
			set(__STRING_SO_FAR "${__STRING_SO_FAR};${${__PREFIX}_${__ARG}}")
#			message(STATUS "_calculate_hash(): __ARG: ${__ARG}, ${__PREFIX}_${__ARG}: \"${${__PREFIX}_${__ARG}}\"")
		endforeach()
		set(${__OUT_HASH_SOURCE} "${__STRING_SO_FAR}" PARENT_SCOPE)
		string(MD5 __HASH "${__STRING_SO_FAR}")
		set(${__OUT_HASH} "${__HASH}" PARENT_SCOPE)
#		message(STATUS "_calculate_hash(): Calculated hash: ${__HASH} from variables ${__VAR_LIST} based on string \"${__STRING_SO_FAR}\"")
	else()
		set(${__OUT_HASH} "${__EXTRA_STRING}" PARENT_SCOPE)
		set(${__OUT_HASH_SOURCE} "${__EXTRA_STRING}" PARENT_SCOPE)
	endif()
endfunction()


function(_make_path_hash __TARGETS_CMAKE_PATH __OUT_HASH)
	if(NOT __TARGETS_CMAKE_PATH)
		message(FATAL_ERROR "Internal Beetroot error: __TARGETS_CMAKE_PATH should not be empty")
	endif()
	get_filename_component(__NORM_PATH "${__TARGETS_CMAKE_PATH}" REALPATH)
	string(MD5 __TMP ${__NORM_PATH})
	string(SUBSTRING ${__TMP} 1 6 __TMP)
	if("${__TMP}" STREQUAL "")
		meesage(FATAL_ERROR "path hash cannot come up empty")
	endif()
	set(${__OUT_HASH} ${__TMP} PARENT_SCOPE)
#	message(WARNING "_make_path_hash(): ${__TMP} <- ${__TARGETS_CMAKE_PATH}")
endfunction()

function(_make_featurebase_hash_2 __SERIALIZED_MODIFIERS __SERIALIZED_FEATURES __TEMPLATE_NAME __PATH __SINGLETON_TARGETS __OUT_HASH __OUT_HASH_SOURCE)
	if(__SINGLETON_TARGETS)
		get_filename_component(__NORM_PATH "${__PATH}" REALPATH)
		set(__TMP "${__NORM_PATH}")
	else()
		set(__TMP "${__TEMPLATE_NAME}")
	endif()
#	set(__TMP "${__TMP}|${__SERIALIZED_MODIFIERS}|${__SERIALIZED_FEATURES}")
	set(__TMP "${__TMP}|${__SERIALIZED_MODIFIERS}|")
	set(${__OUT_HASH_SOURCE} "${__TMP}" PARENT_SCOPE)
	string(MD5 __HASH "${__TMP}")
	string(SUBSTRING ${__HASH} 1 8 __OUT)
#	message(STATUS "_make_featurebase_hash_2(): __TMP (ID|MODIFIERS|FEATURES): ${__TMP} got featurebase id ${__OUT}")
	if("${__TMP}" STREQUAL "")
		meesage(FATAL_ERROR "featurebase hash cannot come up empty")
	endif()
#	message(WARNING "######################## OK")
	set(${__OUT_HASH} "${__OUT}" PARENT_SCOPE)
endfunction()

function(_make_featurebase_hash_1 __MODS __MODS_LIST __FEATS __FEATS__LIST __TEMPLATE_NAME __PATH __SINGLETON_TARGETS __OUT_HASH __OUT_HASH_SOURCE)
	_serialize_variables(${__MODS} __MODS__LIST __SERIALIZED_MODIFIERS)
	_serialize_variables(${__FEATS} __FEATS__LIST __SERIALIZED_FEATURES)
#	_make_featurebase_hash_2("${__SERIALIZED_MODIFIERS}" "${__SERIALIZED_FEATURES}" ${__TEMPLATE_NAME} "${__PATH}" ${__SINGLETON_TARGETS} __OUT) We remove features from featurebase hash
	_make_featurebase_hash_2("${__SERIALIZED_MODIFIERS}" "" ${__TEMPLATE_NAME} "${__PATH}" ${__SINGLETON_TARGETS} __HASH __HASH_SOURCE)
	set(${__OUT_HASH} "${__HASH}" PARENT_SCOPE)
	set(${__OUT_HASH_SOURCE} "${__HASH_SOURCE}" PARENT_SCOPE)
endfunction()

function(_make_instance_id __TEMPLATE_NAME_TO_FIX __ARGS __SALT __OUT __OUT_SOURCE)
	string(REPLACE "-" "_" __TEMPLATE_NAME "${__TEMPLATE_NAME_TO_FIX}")
	get_property(__TEMPLATE_NAMES GLOBAL PROPERTY __TEMPLATE_NAMES_${__TEMPLATE_NAME})
	if("${__SALT}" STREQUAL "")
		set(__SALT "ID")
	endif()
	_calculate_hash(${__ARGS} "${${__ARGS}__LIST}" "${__SALT}" __HASH __HASH_SOURCE)
	if("${__HASH}" STREQUAL "")
		set(${__OUT} "${__TEMPLATE_NAME}")
	else()
		set(${__OUT} "${__TEMPLATE_NAME}_${__HASH}")
	endif()
	
	_serialize_variables(${__ARGS} ${__ARGS}__LIST __TMP_SER)
	set(${__OUT} "${${__OUT}}" PARENT_SCOPE)
	set(${__OUT_SOURCE} "${__HASH_SOURCE}" PARENT_SCOPE)
#	message(STATUS "_make_instance_id(): ${__TEMPLATE_NAME} with args ${__TMP_SER} got hash ${${__OUT}} based on source ${__HASH_SOURCE}")
	_set_property_to_db(INSTANCEDB ${${__OUT}} I_HASH_SOURCE "${__HASH_SOURCE}")
endfunction()

function(_make_instance_name __INSTANCE_ID __OUT)
#	message(STATUS "_make_instance_name(): called for __INSTANCE_ID: ${__INSTANCE_ID}")
	_get_target_behavior(__TARGET_BEHAVIOR)
	if("${__TARGET_BEHAVIOR}" STREQUAL "GATHERING_DEPENDENCIES")
		message(FATAL_ERROR "Internal Beetroot error. Function _make_instance_name should never be called during gathering dependencies phase")
	endif()
	if("${__INSTANCE_ID}" STREQUAL "")
		message(FATAL_ERROR "Internal Beetroot error. __INSTANCE_ID cannot be empty")
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	if(__IS_PROMISE)
		message(FATAL_ERROR "Internal Beetroot error. Attempt to name target for a promise ${__INSTANCE_ID}")
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} TARGET_NAME __TARGET_NAME)

	if(NOT "${__TARGET_NAME}" STREQUAL "")
		set(${__OUT} "${__TARGET_NAME}" PARENT_SCOPE)
#		message(STATUS "_make_instance_name(): short-circuit exit with __TARGET_NAME: ${__TARGET_NAME} for __INSTANCE_ID: ${__INSTANCE_ID}")
		return()
	endif()
	
	_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __HASH)
	_retrieve_instance_data(${__INSTANCE_ID} TEMPLATE_FEATUREBASES __TEMPLATE_HASHES)
	_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
	list(LENGTH __TEMPLATE_HASHES __NUMBER_OF_TARGETS)
	if("${__NUMBER_OF_TARGETS}" STREQUAL "")
		set(__NUMBER_OF_TARGETS 0)
	endif()
	if("${__NUMBER_OF_TARGETS}" STREQUAL "0")
		message(FATAL_ERROR "Internal beetroot error: cannot have empty TEMPLATE_FEATUREBASES for ${__TEMPLATE_NAME} (${__INSTANCE_ID})")
	endif()

#	message(STATUS "_make_instance_name(): __NUMBER_OF_TARGETS in ${__TEMPLATE_NAME}: ${__NUMBER_OF_TARGETS}")
	string(TOLOWER ${__TEMPLATE_NAME} __TEMPLATE_NAME_SMALL)
	string(REPLACE "::" "__" __TEMPLATE_NAME_VAR "${__TEMPLATE_NAME}")
	string(REPLACE "-" "_" __TEMPLATE_NAME "${__TEMPLATE_NAME}")
	if( "${__HASH}" IN_LIST __TEMPLATE_HASHES)
		if( ${__NUMBER_OF_TARGETS} GREATER 1)
			list(FIND __TEMPLATE_HASHES "${__HASH}" __LENGTH_P1 )
			math(EXPR __LENGTH_P1 "${__LENGTH_P1} + 1")
		else()
			set(__LENGTH_P1)
		endif()
		set(__TARGET_NAME "${__TEMPLATE_NAME_SMALL}${__LENGTH_P1}")
	else()
		if( ${__NUMBER_OF_TARGETS} GREATER 1)
			list(LENGTH __TEMPLATE_HASHES __LENGTH)
			math(EXPR __LENGTH_P1 "${__LENGTH} + 1")
			set(__TARGET_NAME "${__TEMPLATE_NAME_SMALL}${__LENGTH_P1}")
		else()
			set(__TARGET_NAME "${__TEMPLATE_NAME_SMALL}")
		endif()
	endif()
#	message(STATUS "_make_instance_name(): ${__TEMPLATE_NAME} with hash ${__HASH} got its instance name ${__TARGET_NAME}")
	set(${__OUT} "${__TARGET_NAME}" PARENT_SCOPE)
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} TARGET_NAME "${__TARGET_NAME}")
endfunction()

#Calculates hash of the external project based on its name, features and modifiers
function(_make_external_project_id __INSTANCE_ID __EXTERNAL_ID_OUT __HASH_SOURCE_OUT)
	_retrieve_instance_args(${__INSTANCE_ID} I_FEATURES __ARGS)
	set(__TMP_LIST ${__ARGS__LIST})
	_retrieve_instance_args(${__INSTANCE_ID} MODIFIERS __ARGS)
	list(APPEND __ARGS__LIST ${__TMP_LIST} )
	_calculate_hash(__ARGS "${__ARGS__LIST}" "${__EXTERNAL_NAME}" __EXTERNAL_ID __EXTERNAL_ID_SOURCE)
	message(STATUS "_make_external_project_id(): __ARGS__LIST: ${__ARGS__LIST} __EXTERNAL_ID_SOURCE: ${__EXTERNAL_ID_SOURCE} __EXTERNAL_ID: ${__EXTERNAL_ID}")
	string(SUBSTRING "${__EXTERNAL_ID}" 1 5 __EXTERNAL_ID)
	set(${__EXTERNAL_ID_OUT} ${__EXTERNAL_ID} PARENT_SCOPE)
	set(${__HASH_SOURCE_OUT} "${__EXTERNAL_ID_SOURCE}" PARENT_SCOPE)
endfunction()
