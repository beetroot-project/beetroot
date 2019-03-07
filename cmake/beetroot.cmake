# get_target(<TEMPLATE_NAME> [PATH <Ścieżka do targets.cmake>] <Args...>)
#
# High level function responsible for 
# 1. finding a target defining function by its template name (or path), 
# 2. get all its arguments by properly combining default values with already existing variables and arguments Args...
# 3. if target defined by that arguments exists already, return its name, otherwise...
# 3. ...instatiate its dependencies (which may be internal and external) by calling declare_dependencies(), 
# 4. define the target by calling generate_targets() and
# 5. return the actual target name.
#

if("${SUPERBUILD}" STREQUAL "")
	set(SUPERBUILD "AUTO")
else()
#	message("#### SUPERBUILD: ${SUPERBUILD}")
endif()

get_property(__BURAK_LOADED GLOBAL PROPERTY __BURAK_LOADED)
if(NOT __BURAK_LOADED)
	get_filename_component(__PREFIX "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
	set(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY 1) #We disable use of CMake package registry. See https://cmake.org/cmake/help/v3.2/variable/CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY.html . With this variable set, the only version of the packages will be the version we actually intend to use.

	include(${__PREFIX}/beetroot_misc.cmake)
	include(${__PREFIX}/beetroot_variables_misc.cmake)
	include(${__PREFIX}/beetroot_data_def.cmake)
	include(${__PREFIX}/beetroot_storage.cmake)
	include(${__PREFIX}/beetroot_get_target.cmake)
	include(${__PREFIX}/beetroot_finalize.cmake)
	include(${__PREFIX}/beetroot_reading_targets.cmake)
	include(${__PREFIX}/beetroot_parse_variables.cmake)
	include(${__PREFIX}/beetroot_global_storage.cmake)
	include(${__PREFIX}/beetroot_global_storage_misc.cmake)
	include(${__PREFIX}/beetroot_dependency_processing.cmake)
	include(${__PREFIX}/beetroot_ids.cmake)
	include(${__PREFIX}/beetroot_messages.cmake)
	include(${__PREFIX}/beetroot_cmake_overrides.cmake)
	include(${__PREFIX}/beetroot_external_target.cmake)
	include(${__PREFIX}/build_install_prefix.cmake)
	include(${__PREFIX}/set_operations.cmake)
	include(${__PREFIX}/prepare_arguments_to_pass.cmake)
	include(${__PREFIX}/missing_dependency.cmake)

	if(NOT SUPERBUILD_ROOT)
		message(FATAL_ERROR "First set the SUPERBUILD_ROOT, then include the beetroot!")
	endif()
	get_filename_component(SUPERBUILD_ROOT "${SUPERBUILD_ROOT}" REALPATH)

	_set_behavior_outside_defining_targets()
	if(NOT __NOT_SUPERBUILD)
		_set_property_to_db(GLOBAL ALL EXTERNAL_DEPENDENCIES "" FORCE)
	else()
#		message(STATUS "Beginning of the second phase")
	endif()
	set(__RANDOM ${__RANDOM})
	include(ExternalProject)

	__prepare_template_list()
	set_property(GLOBAL PROPERTY __BURAK_LOADED 1) #To prevent loading this file again
endif()

