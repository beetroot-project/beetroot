set(ENUM_TEMPLATES _EXTERNAL_LIB1)

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
	target_include_directories(${TARGET_NAME} PUBLIC $<INSTALL_INTERFACE:include> 
	   $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
	)
	target_compile_definitions(${TARGET_NAME} PRIVATE "LIB1=${LIB1ARG}")
	target_compile_definitions(${TARGET_NAME} PRIVATE "EXTRAS=${EXTRA_FUN}")
	install(TARGETS ${TARGET_NAME} EXPORT ${TEMPLATE_NAME}-targets DESTINATION "${CMAKE_INSTALL_PREFIX}/lib")
	install(FILES include/lib1.h DESTINATION "${CMAKE_INSTALL_PREFIX}/include")
	install(EXPORT ${TEMPLATE_NAME}-targets DESTINATION "${CMAKE_INSTALL_PREFIX}/cmake")
	message("INSTALL: ${CMAKE_INSTALL_PREFIX}/include")
	#todo install
endfunction()

