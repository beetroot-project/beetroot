set(ENUM_TEMPLATES FEATURE-SHAREDLIB)

set(TARGET_PARAMETERS 
	MYPAR SCALAR INTEGER "1"
)

set(TARGET_FEATURES 
	SHOW_COMPONENTS	OPTION	BOOL	0
	LIB_COMPONENTS	VECTOR	STRING	""
	USE_BAR	SCALAR	BOOL	"0"
	USE_FOO	OPTION	BOOL	"0"
)

set(LINK_PARAMETERS
	LIB_LINKPAR	OPTION	BOOL	0
)

set(FILE_OPTIONS
	LINK_TO_DEPENDEE
)

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	add_library(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/lib_shared.cpp")
	target_include_directories(${TARGET_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
	target_compile_definitions(${TARGET_NAME} PUBLIC "MYPAR=${MYPAR}")
	if(USE_BAR)
		target_compile_definitions(${TARGET_NAME} PUBLIC "FUN_BAR")
	endif()
	if(USE_FOO)
		target_compile_definitions(${TARGET_NAME} PUBLIC "FUN_FOO")
	endif()
	if(SHOW_COMPONENTS)
		target_compile_definitions(${TARGET_NAME} PUBLIC "SHOW_COMPONENTS")
	endif()
	if(C1 IN_LIST LIB_COMPONENTS)
		target_compile_definitions(${TARGET_NAME} PRIVATE "COMP_1")
	endif()
	if(C2 IN_LIST LIB_COMPONENTS)
		target_compile_definitions(${TARGET_NAME} PRIVATE "COMP_2")
	endif()
	if(C3 IN_LIST LIB_COMPONENTS)
		target_compile_definitions(${TARGET_NAME} PRIVATE "COMP_3")
	endif()
	if(C4 IN_LIST LIB_COMPONENTS)
		target_compile_definitions(${TARGET_NAME} PRIVATE "COMP_4")
	endif()
endfunction()

function(apply_dependency_to_target DEPENDEE_TARGET_NAME OUR_TARGET_NAME)
	target_compile_definitions(${DEPENDEE_TARGET_NAME} PRIVATE "LINKPAR")
endfunction()
