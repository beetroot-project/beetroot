set(ENUM_TEMPLATES SELF_TEST) #TODO

set(TARGET_PARAMETERS 
)

set(TEMPLATE_OPTIONS
)

#function(declare_dependencies TARGET_NAME)
#endfunction()

function(generate_targets TEMPLATE_NAME)
	file(WRITE ${CMAKE_BINARY_DIR}/main.c "int main(void){return 0;}\n")
	add_executable(${TARGET_NAME} main.c)
	add_test(NAME ${TARGET_NAME} COMMAND ${TARGET_NAME})
endfunction()

#663582226 - sms do 14:00 z inf. czy zgłosił się kurier
