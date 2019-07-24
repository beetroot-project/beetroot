set(ENUM_TEMPLATES HELLO_BOOST)

function(declare_dependencies TEMPLATE_NAME)
	build_target(Boost COMPONENT program_options)
endfunction()

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/program_options.cpp")
endfunction()

