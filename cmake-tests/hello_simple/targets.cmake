set(TARGET_PARAMETERS 
	KTO SCALAR STRING "Tata"
)

set(ENUM_TEMPLATES HELLO_SIMPLE)

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	if(NOT KTO)
		message(FATAL_ERROR "KTO is empty!")
	endif()
#	message(WARNING "Inside generate_targets trying to define ${HELLO_TARGET_NAME} with KTO=${KTO}")
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/source.cpp")
	target_compile_definitions(${TARGET_NAME} PRIVATE "KTO=${KTO}")
endfunction()

