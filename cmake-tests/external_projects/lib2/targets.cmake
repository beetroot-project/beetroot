set(ENUM_TEMPLATES EXTERNAL_LIB2)

set(BUILD_PARAMETERS 
	LIB1ARG SCALAR INTEGER "1"
)

set(BUILD_FEATURES 
   EXTRA_FUN   OPTION BOOL 0
)

function(declare_dependencies TEMPLATE_NAME)

endfunction()

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	add_library(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/src/lib1.cpp")
	target_include_directories(${TARGET_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
	target_compile_definitions(${TARGET_NAME} PRIVATE "LIB1=${LIB1ARG}")
	target_compile_definitions(${TARGET_NAME} PRIVATE "EXTRAS=${EXTRA_FUN}")
	install(TARGETS ${TARGET_NAME} DESTINATION "lib")
	install(FILES include/lib2.h DESTINATION "include")
endfunction()

