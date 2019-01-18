set(TARGET_PARAMETERS 
	KTO	SCALAR	STRING	"from_targets_lib"
	FUNNAME SCALAR STRING "get_string"
)

set(ENUM_TEMPLATES LIBHELLO)

function(generate_targets TEMPLATE_NAME)
	message(STATUS "LibHello: inside generate_targets trying to define ${TARGET_NAME} in ${CMAKE_CURRENT_SOURCE_DIR}/include")
	add_library(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/src/libsource.cpp")
	target_include_directories(${TARGET_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
	target_compile_definitions(${LIBHELLO_TARGET_NAME} PRIVATE "KTO=${KTO}")
	target_compile_definitions(${LIBHELLO_TARGET_NAME} PRIVATE "FUNNAME=${FUNNAME}")
endfunction()

