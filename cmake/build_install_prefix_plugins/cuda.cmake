execute_process(COMMAND nvcc --version 
	RESULT_VARIABLE HOW_IS_CUDA 
	ERROR_VARIABLE CUDA_ERR
	OUTPUT_VARIABLE TMP
	)
#message(FATAL_ERROR "HOW_IS_CUDA: ${HOW_IS_CUDA} CUDA_ERR: ${CUDA_ERR}")
if("${HOW_IS_CUDA}" STREQUAL "0")
	enable_language(CUDA)
	set(CUDA_VERSION_STRING "CUDA${CMAKE_CUDA_COMPILER_VERSION}")
else()
	set(CUDA_VERSION_STRING "noCUDA")
endif()
#include(CheckLanguage)
#check_language(CUDA)

