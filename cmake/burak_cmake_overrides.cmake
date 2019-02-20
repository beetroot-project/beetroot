
macro(enable_testing)
	if(NOT "${ARGV0}" STREQUAL "")
		if("${ARGV0}" STREQUAL "TEST_ON_BUILD")
			set(__SUPERBUILD_TEST_ON_BUILD 1)
		else()
			message(FATAL_ERROR "Beetroot error: unknown argument to enable_testing(). The only argument allowed is a flag TEST_ON_BUILD")
		endif()
	else()
		set(__SUPERBUILD_TEST_ON_BUILD 0)
	endif()
	if(__NOT_SUPERBUILD)
		_enable_testing()
	else()
		message(STATUS "NO TESTING IN SUPERBUILD")
		set(__SUPERBUILD_TRIGGER_TESTS 1)
#		_enable_testing()
		#noop
	endif()
endmacro()

#We hijack the project() command to make sure, that during the superbuild phase no actual compiling will take place.
macro(project) 
	if(__NOT_SUPERBUILD)
		_project(${ARGN})
	else()
		message("No languages in project ${ARGV0}")
		_project(${ARGV0} NONE)
	endif()
endmacro()


