set(ENUM_TEMPLATES HELLO)

set(TARGET_PARAMETERS 
	BLA	SCALAR	STRING	"${WYBOR}-EK"
	WYBOR SCALAR "CHOICE(BLA:BLU:BLI)" "BLI"
	LIBKTO SCALAR STRING "from_targets"
#	OPCJA	OPTION	"" 0
#	PRECISION	SCALAR	INTEGER 4
#	PATH	SCALAR	PATH "Taka sobie ścieżka"
#	COMPONENTS	VECTOR	STRING	"filesystem;log"
#	ARCH	SCALAR	CHOICE(GPU;CPU) CPU
#	KILKA_Z_WIELU	VECTOR	CHOICE(RAZ;DWA;TRZY;CZTERY) "DWA;CZTERY"
)
set(LINK_PARAMETERS 
	NONSIGINIFICANT	SCALAR	STRING	"foo"
)

set(TEMPLATE_OPTIONS
)

function(declare_dependencies TEMPLATE_NAME)
	build_target(LIBHELLO KTO ${LIBKTO})
endfunction()

function(generate_targets TEMPLATE_NAME)
	if(NOT "${LIB_MYVAR}" STREQUAL "Variable_from_lib")
		message(FATAL_ERROR "Could not pass exported variable from the dependency LIBHELLO")
	else()
		message(STATUS "Properly passed exported variable from the dependency LIBHELLO")
	endif()
	message(STATUS "Inside generate_targets trying to define ${HELLO_TARGET_NAME} with BLA=${BLA}")
	add_executable(${HELLO_TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/source.cpp")
	target_compile_definitions(${HELLO_TARGET_NAME} PRIVATE "BLA=${BLA}")
endfunction()

