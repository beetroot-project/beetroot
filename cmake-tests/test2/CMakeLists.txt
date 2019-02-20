CMAKE_MINIMUM_REQUIRED(VERSION 2.8 FATAL_ERROR)
project(myTest C)
enable_testing()

function(fun)
   file(WRITE ${CMAKE_BINARY_DIR}/main.c "int main(void){return 0;}\n")
   add_executable(main main.c)
   add_test(NAME main COMMAND main)
endfunction()

function(just_call)
	fun()
endfunction()


just_call()
