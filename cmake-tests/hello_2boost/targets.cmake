set(DEFINE_MODIFIERS 
	PAR	SCALAR	STRING	"KLOC"
)

set(ENUM_TEMPLATES HELLO_2BOOST)

function(declare_dependencies TEMPLATE_NAME)
	build_target(Boost::program_options )
endfunction()

function(generate_targets TEMPLATE_NAME)
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/program_options.cpp")
	target_compile_definitions(${TARGET_NAME} PRIVATE "BOOST_PAR=${PAR}")
endfunction()

