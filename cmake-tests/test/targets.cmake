set(ENUM_TEMPLATES SELF_TEST) #TODO

set(TARGET_PARAMETERS 
)

set(TEMPLATE_OPTIONS
	LANGUAGES C
)

#function(declare_dependencies TARGET_NAME)
#endfunction()

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	file(WRITE ${CMAKE_BINARY_DIR}/main.c "int main(void){return 0;}\n")
	add_executable(${TARGET_NAME} main.c)
endfunction()

