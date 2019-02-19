# Common header for superproject
# ---------------

cmake_minimum_required(VERSION 3.13)

if(NOT SUPERBUILD_ROOT)
	set(CURRENT_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
	foreach(DEPTH RANGE 15)
		if("${CURRENT_DIR}" STREQUAL "/")
			set(SUPERBUILD_ROOT )
			message(STATUS "Found superproject root at ${SUPERBUILD_ROOT}")
			break()
		endif()
		if(EXISTS "${CURRENT_DIR}/cmake/root.cmake")
			set(SUPERBUILD_ROOT "${CURRENT_DIR}")
			break()
		endif()
		get_filename_component(CURRENT_DIR ${CURRENT_DIR} DIRECTORY)
	endforeach()
	if ("${SUPERBUILD_ROOT}" STREQUAL "")
		message(FATAL_ERROR "Cannot find a superproject structures on top of the current directory.")
	endif()
	set (CMAKE_MODULE_PATH "${SUPERBUILD_ROOT}/cmake")
	include(root)
endif()

project(implicit_vars)
set(__BEETROOT_CLEAN_ALL_VARIABLES 1)
set(IMPLICIT_GLOBAL "OK CMakeLists")

message(STATUS "Calling build_target(IMPLICIT_VARS)")
build_target(IMPLICIT_VARS)
message(STATUS "Calling build_target(EXPORT_VAR...)")
build_target(EXPORT_VAR 
	IMPLICIT_EXPORTED "OK CMakeLists")
message(STATUS "End of CMakeLists")

#IMPLICIT_EXPORTED
#IMPLICIT_LOCAL
#IMPLICIT_IMPORTED
#IMPLICIT_LINK
#IMPLICIT_EXPORTED_DEFAULT
#IMPLICIT_GLOBAL

#IMPLICIT_GLOBAL: ${IMPLICIT_GLOBAL} IMPLICIT_LOCAL: ${IMPLICIT_LOCAL} IMPLICIT_IMPORTED: ${IMPLICIT_IMPORTED} IMPLICIT_EXPORTED: ${IMPLICIT_EXPORTED} IMPLICIT_EXPORTED_DEFAULT: ${IMPLICIT_EXPORTED_DEFAULT} IMPLICIT_LINK: ${IMPLICIT_LINK}

finalizer()
