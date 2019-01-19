set(LINK_PARAMETERS 
	GRIDTOOLS_USE_GPU	OPTION	""	0
	VERBOSE_MESSAGES	OPTION	""	0
	GRIDTOOLS_ICOSAHEDRAL_GRIDS	OPTION	""	0
	GRIDTOOLS_FLOAT_PRECISION	SCALAR	CHOICE(4:8)	4
	GRIDTOOLS_DYCORE_BLOCKING	OPTION	""	0
	GRIDTOOLS_OPENMP	OPTION	""	0
)

if(GRIDTOOLS_USE_GPU)
	set(CUDA_LANG "CUDA")
else()
	set(CUDA_LANG "")
endif()

set(ENUM_TEMPLATES GRIDTOOLS)

set(DEFINE_EXTERNAL_PROJECT 
	NAME Gridtools
	SOURCE_PATH "${SUPERBUILD_ROOT}/gridtools"
)

set(TEMPLATE_OPTIONS
	NO_TARGETS #If set it declares that no targets will be generated. Generates error if `generate_targets()` is defined by the user.
	LANGUAGES ${CUDA_LANG} CXX
)

function(generate_targets)
	message(STATUS "generate_targets() should throw an error here")
endfunction()

function(apply_dependency_to_target DEPENDEE_TARGET_NAME)
	message(STATUS "apply_dependency_to_target() for Gridtools...")
	set(GRIDTOOLS_INCLUDE_DIRS "${GRIDTOOLS_INSTALL_PATH}/include")
	if (NOT EXISTS "${GRIDTOOLS_INCLUDE_DIRS}/common/defs.hpp") 
		if (NOT EXISTS "${GRIDTOOLS_INCLUDE_DIRS}/gridtools/common/defs.hpp") 
			message(FATAL_ERROR "GridTools was not found in ${GRIDTOOLS_INCLUDE_DIRS}.")
		else()
			set(GRIDTOOLS_INCLUDE_DIRS "${GRIDTOOLS_INCLUDE_DIRS}/gridtools")
		endif()
	endif()
	target_include_diectories(${DEPENDEE_TARGET_NAME} SYSTEM PRIVATE ${GRIDTOOLS_INCLUDE_DIRS})
	if(NOT VERBOSE_MESSAGES)
		target_compile_definitions(${DEPENDEE_TARGET_NAME} PRIVATE -DSUPPRESS_MESSAGES)
	endif()
	if(NOT GRIDTOOLS_ICOSAHEDRAL_GRIDS)
		target_compile_definitions(${DEPENDEE_TARGET_NAME} PRIVATE -DSTRUCTURED_GRIDS)
	endif()
	if (GRIDTOOLS_FLOAT_PRECISION)
		target_compile_definitions(${DEPENDEE_TARGET_NAME} PRIVATE -DFLOAT_PRECISION=${GRIDTOOLS_FLOAT_PRECISION})
	endif()
	if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		# Certain stencils require 256+ instantiation depth which exceedes the default of Clang
		target_compile_options(${DEPENDEE_TARGET_NAME} PRIVATE -ftemplate-depth=512)
		target_compile_options(${DEPENDEE_TARGET_NAME} PUBLIC -mtune=native)
	endif()

	if(CMAKE_BUILD_TYPE MATCHES "Release")
		# Shared architecture flags

		if(NOT GRIDTOOLS_USE_GPU)
			message(WARNING "PRIVATE -march=native")
			target_compile_options(${DEPENDEE_TARGET_NAME} PRIVATE -march=native)
			# Compiler specific
			if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
				target_compile_options(${DEPENDEE_TARGET_NAME} PRIVATE -Wno-cpp)
				target_compile_options(${DEPENDEE_TARGET_NAME} PRIVATE -ftree-vectorize)
			elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
				target_compile_options(${DEPENDEE_TARGET_NAME} PRIVATE -ftree-vectorize)
			endif()
		endif()
	elseif(CMAKE_BUILD_TYPE MATCHES "Debug")
		target_compile_definitions(${DEPENDEE_TARGET_NAME} PRIVATE -DDEBUG)
		target_compile_options(${DEPENDEE_TARGET_NAME} PUBLIC -ftemplate-depth=2500)

	endif()

	if(GRIDTOOLS_DYCORE_BLOCKING)
		target_compile_definitions(${DEPENDEE_TARGET_NAME} PRIVATE -DDYCORE_USE_BLOCKING)
	endif()

	if(GRIDTOOLS_OPENMP)
		target_compile_options(${DEPENDEE_TARGET_NAME} PUBLIC ${OpenMP_CXX_FLAGS})
		target_compile_options(${DEPENDEE_TARGET_NAME} PUBLIC -fopenmp)
		target_compile_options(${DEPENDEE_TARGET_NAME} PUBLIC -ftemplate-depth=2500)
		target_compile_options(${DEPENDEE_TARGET_NAME} PUBLIC -ftemplate-backtrace-limit=1)
	endif()

	if(GRIDTOOLS_USE_GPU)
		get_target_property(GRIDTOOLS_TARGET_SOURCES ${DEPENDEE_TARGET_NAME} SOURCES)
		set_source_files_properties(
			${GRIDTOOLS_TARGET_SOURCES}
			PROPERTIES LANGUAGE CUDA
		)

		if("${CUDA_VERSION_STRING}" STREQUAL "7.0")
			# http://stackoverflow.com/questions/31940457/make-nvcc-output-traces-on-compile-error
			target_compile_definitions(${DEPENDEE_TARGET_NAME} PRIVATE -DBOOST_RESULT_OF_USE_TR1)
		endif()
		target_compile_definitions(${DEPENDEE_TARGET_NAME} PRIVATE _USE_GPU_)
		target_compile_definitions(${DEPENDEE_TARGET_NAME} PRIVATE DYCORE_USE_GPU)
		target_include_directories(${DEPENDEE_TARGET_NAME} SYSTEM PUBLIC ${CUDA_INCLUDE_DIRS})
		target_compile_options(${DEPENDEE_TARGET_NAME} PRIVATE "-arch=sm_30")

	endif()


	target_link_libraries(${DEPENDEE_TARGET_NAME} "-lpthread")
	get_cpp_version(TARGET ${DEPENDEE_TARGET_NAME})
	if("${CPP_VERSION}" STREQUAL "")
		message(FATAL_ERROR "Unspecified C++ standard version. Please add compiler option -std=c++11 or other to the target before configuring it with the gridtools.")
#			if (GRIDTOOLS_CPP14)
#				target_compile_options(${DEPENDEE_TARGET_NAME} PUBLIC "-std=c++14")
#			else()
#				target_compile_options(${DEPENDEE_TARGET_NAME} PUBLIC "-std=c++11")
#			endif()
	endif()
	message(STATUS "apply_dependency_to_target() ... finished!")
endfunction()
