set(ENUM_TEMPLATES FEATURE-EXEC)

function(declare_dependencies TEMPLATE_NAME)
	get_existing_target(FEATURE-STATICLIB USE_STH STH_COMPONENTS compexec)
endfunction()

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/consumer.cpp")
endfunction()

