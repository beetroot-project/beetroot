set(ENUM_TEMPLATES LIB1_CLIENT)

function(declare_dependencies TEMPLATE_NAME)
   build_target(_external_lib1 EXTRA_FUN)
endfunction()

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/src/lib1_client.cpp")
endfunction()

