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

project(hello)

set(WYBOR "BLU")

build_target(HELLO_SIMPLE)
build_target(HELLO )
build_target(HELLO LIBKTO from_arg_CMakeLists)
build_target(HELLO LIBKTO Mama)
build_target(HELLO LIBKTO Mama NONSIGINIFICANT boo)
build_target(HELLO LIBKTO Sofia NONSIGINIFICANT boo)
build_target(fiksik)
##build_target(fiksik NONSIGINIFICANT X LIBKTO Mik )  #generates error
build_target(HELLO_BOOST)
build_target(HELLO_2BOOST)
build_target(HELLO_2BOOST PAR KUC)
build_target(HEADER_CONSUMER)

build_target(BOOTSTRAPPED_HELLO_SIMPLE)

build_target(SERIALBOX_C_TEST)
build_target(SERIALBOX_C_TEST2 SERIALBOX_USE_NETCDF 0 SERIALBOX_ENABLE_FORTRAN 1 SERIALBOX_EXAMPLES 1 ) #Works only with SERIALBOX_C_TEST
build_target(SERIALBOX_C_TEST2) 

build_target(FEATURE-STATICLIB FUNNAME "YY") #without this line, feature-exec should fail
build_target(FEATURE-EXEC)
get_target(SELF_TEST_TEST TEST_NAME)

set(IMPLICIT_GLOBAL "OK CMakeLists")
build_target(IMPLICIT_VARS)
build_target(EXPORT_VAR 
	IMPLICIT_EXPORTED "OK CMakeLists")


finalizer()
