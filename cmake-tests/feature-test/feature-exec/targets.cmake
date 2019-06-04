set(ENUM_TEMPLATES FEATURE-EXEC)

function(declare_dependencies TEMPLATE_NAME)
	get_existing_target(FEATURE-LIB1 USE_STH STH_COMPONENTS compexec FUNNAME getstring)
	get_existing_target(FEATURE-SHAREDLIB 
		SHOW_COMPONENTS
		USE_BAR 1
		LIB_LINKPAR
		)
endfunction()

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/consumer.cpp")
endfunction()

