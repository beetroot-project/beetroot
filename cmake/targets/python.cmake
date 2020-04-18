set(ENUM_TARGETS Python::Interpreter)

if("${PYTHON_FAMILY}" STREQUAL "2.x")
	set(P_NAME "Python 2.x interpreter")
	set(APT python2)
	set(SPACK python@2.7.15)
else()
	set(P_NAME "Python 3.x interpreter")
	set(APT python3)
	set(SPACK python@3.7.0)
endif()

set(BUILD_PARAMETERS 
	PYTHON_FAMILY	SCALAR	"CHOICE(2.x:3.x)" "3.x"
)

set(FILE_OPTIONS
	NICE_NAME "${P_NAME}"
)

set(DEFINE_EXTERNAL_PROJECT 
	ASSUME_INSTALLED
	NAME Python
	APT_PACKAGES "${APT}"
	SPACK_PACKAGES "${SPACK}"
)

function(build_version_string OUT_STRING)
   find_package(Python COMPONENTS Interpreter)
   set(${OUT_STRING} "${Python_VERSION}" PARENT_SCOPE)
endfunction()
