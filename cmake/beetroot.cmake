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
	if(NOT SUPERBUILD_ROOT)
		set(__CMAKELISTS_FOUND 0) # 0 - never, 1 - found in last iteration, 2 - found in next-to-last iteration
		set(__CURRENT_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
		set(__SUPERBUILD_ROOT)
		foreach(DEPTH RANGE 15)
#			message(STATUS "entering ${__CURRENT_DIR}: ${__CURRENT_DIR} with __CMAKELISTS_FOUND: ${__CMAKELISTS_FOUND}")
			if("${__CURRENT_DIR}" STREQUAL "/")
				if("${__CMAKELISTS_FOUND}" STREQUAL "2" or "${__CMAKELISTS_FOUND}" STREQUAL "1")
					message(STATUS "Beetroot: Guessed superproject root to be ${__SUPERBUILD_ROOT}. If it is not correct, then set the path manually by setting SUPERBUILD_ROOT manually before including the beetroot library")
					set(SUPERBUILD_ROOT "${__SUPERBUILD_ROOT}")
				else()
					set(SUPERBUILD_ROOT )
					message(FATAL_ERROR "Could not find superproject root. Please set it manually.")
				endif()
				break()
			endif()
			if(EXISTS "${__CURRENT_DIR}/CMakeLists.txt")
				set(__CMAKELISTS_FOUND 1)
				set(__SUPERBUILD_ROOT ${__CURRENT_DIR})
			else()
				if("${__CMAKELISTS_FOUND}" STREQUAL "1")
					set(__CMAKELISTS_FOUND 2)
				else("${__CMAKELISTS_FOUND}" STREQUAL "2")
					message(STATUS "Beetroot: Guessed superproject root to be ${__SUPERBUILD_ROOT}. If it is not correct, then set the path manually by setting SUPERBUILD_ROOT manually before including the beetroot library")
					set(SUPERBUILD_ROOT "${__SUPERBUILD_ROOT}")
					break()
				endif()
			endif()
			get_filename_component(__CURRENT_DIR ${__CURRENT_DIR} DIRECTORY)
		endforeach()
	else()
		get_filename_component(SUPERBUILD_ROOT "${SUPERBUILD_ROOT}" ABSOLUTE)
		if(IS_DIRECTORY "${SUPERBUILD_ROOT}")
			message(STATUS "Beetroot: superproject root is set to be ${SUPERBUILD_ROOT}.")
		else()
			message(FATAL_ERROR "Beetroot error: Superbuild root directory ${SUPERBUILD_ROOT} does not exist")
		endif()
	endif()
	get_filename_component(SUPERBUILD_ROOT "${SUPERBUILD_ROOT}" ABSOLUTE)


	# build and install directory resolution
	if("${BEETROOT_EXTERNAL_INSTALL_DIR}" STREQUAL "")
		set(BEETROOT_EXTERNAL_INSTALL_DIR "install")
	else()
		message(STATUS "Beetroot: Assuming install dir for external projects to be ${BEETROOT_EXTERNAL_INSTALL_DIR} relative to the superbuild root")
	endif()
	get_filename_component(BEETROOT_EXTERNAL_INSTALL_DIR "${BEETROOT_EXTERNAL_INSTALL_DIR}" ABSOLUTE BASE_DIR ${SUPERBUILD_ROOT})
	if("${BEETROOT_BUILD_DIR}" STREQUAL "")
		set(BEETROOT_BUILD_DIR "build")
	else()
		message(STATUS "Beetroot: Assuming build and cache dir to be ${BEETROOT_EXTERNAL_INSTALL_DIR} relative to the superbuild root")
	endif()
	get_filename_component(BEETROOT_BUILD_DIR "${BEETROOT_BUILD_DIR}" ABSOLUTE BASE_DIR ${SUPERBUILD_ROOT})
	if("${BEETROOT_BUILD_DIR}" STREQUAL "${BEETROOT_EXTERNAL_INSTALL_DIR}")
		message(FATAL_ERROR "Beetroot: External install dir and build dir cannot be the same (${BEETROOT_BUILD_DIR})")
	endif()

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
	include(${__PREFIX}/beetroot_missing_languages.cmake)	
	include(${__PREFIX}/beetroot_debug.cmake)	
	include(${__PREFIX}/beetroot_dump.cmake)	

	_set_behavior_outside_defining_targets()
	if(NOT __NOT_SUPERBUILD)
		_set_property_to_db(GLOBAL ALL EXTERNAL_DEPENDENCIES "" FORCE)
	else()
#		message(STATUS "Beginning of the second phase")
	endif()
	set(__RANDOM ${__RANDOM})
	include(ExternalProject)

	__prepare_template_list()
	
   define_property(TARGET PROPERTY TEMPLATE_DIR 
      BRIEF_DOCS "Directory where the targets.cmake lives that defines this target"
      FULL_DOCS "Directory where the targets.cmake lives that defines this target")

	if(__NOT_SUPERBUILD)
		message("    DECLARING  DEPENDENCIES  IN  PROJECT BUILD")
	else()
		if("${SUPERBUILD}" STREQUAL "AUTO")
			message("    DECLARING  DEPENDENCIES  AND  DECIDING  WHETHER  TO  USE  SUPERBUILD")
		else()
			message("    DECLARING  DEPENDENCIES  IN  SUPERBUILD")
		endif()
	endif()
	set_property(GLOBAL PROPERTY __BURAK_LOADED 1) #To prevent loading this file again
endif()


