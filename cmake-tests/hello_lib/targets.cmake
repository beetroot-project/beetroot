set(ENUM_TEMPLATES LIBHELLO)

set(BUILD_PARAMETERS 
	KTO	SCALAR	STRING	"from_targets_lib"
	FUNNAME SCALAR STRING "get_string"
)

set(LINK_PARAMETERS 
	LIB_MYVAR	SCALAR	STRING	"Variable_from_lib"
)

set(FILE_OPTIONS
	EXPORTED_VARIABLES LIB_MYVAR
)

function(generate_targets TARGET_NAME TEMPLATE_NAME)
#	message(STATUS "LibHello: inside generate_targets trying to define ${TARGET_NAME} in ${CMAKE_CURRENT_SOURCE_DIR}/include")
	add_library(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/src/libsource.cpp")
#	message(WARNING "LIBHELLO: add_library(${TARGET_NAME} \"${CMAKE_CURRENT_SOURCE_DIR}/src/libsource.cpp\")")
	target_include_directories(${TARGET_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
	target_compile_definitions(${TARGET_NAME} PRIVATE "KTO=${KTO}")
	target_compile_definitions(${TARGET_NAME} PRIVATE "FUNNAME=${FUNNAME}")
endfunction()

