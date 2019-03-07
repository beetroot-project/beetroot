# Bootstrap loader for the Beetroot. 
# ----------------------------------
#
# It does two things: 
# 1. Tries to locate project root
# 2. Loads the main beetroot file

if("${SUPERBUILD_ROOT}" STREQUAL "")
	set(CURRENT_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
	foreach(DEPTH RANGE 15)
		if("${CURRENT_DIR}" STREQUAL "/")
			set(SUPERBUILD_ROOT )
			message(FATAL_ERROR "Beetroot could not find superproject root!")
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
endif()

get_filename_component(__PREFIX "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
include(${__PREFIX}/beetroot.cmake)

