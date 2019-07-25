set(ENUM_TEMPLATES HELLO_2BOOST)

set(BUILD_PARAMETERS 
	PAR	SCALAR	STRING	"KLOC"
)

function(declare_dependencies TEMPLATE_NAME)
	build_target(BOOST COMPONENT program_options)
endfunction()

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/program_options.cpp")
	target_compile_definitions(${TARGET_NAME} PRIVATE "BOOST_PAR=${PAR}")
endfunction()

