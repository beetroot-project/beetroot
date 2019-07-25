set(ENUM_TEMPLATES FEATURE-LIB1)

set(BUILD_PARAMETERS 
	FUNNAME SCALAR STRING "FUN_DEFAULT"
)

set(BUILD_FEATURES 
	USE_STH	OPTION	BOOL	0
	STH_COMPONENTS	VECTOR	STRING	"compdefault"
)

function(declare_dependencies TEMPLATE_NAME)
#	set(MYPAR 12)
	get_existing_target(FEATURE-SHAREDLIB 
		USE_FOO
		MYPAR 13
	)
endfunction()

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	message(STATUS "LibHello: inside generate_targets trying to define ${TARGET_NAME} in ${CMAKE_CURRENT_SOURCE_DIR}/include. STH_COMPONENTS: ${STH_COMPONENTS}")
	add_library(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/libsource.cpp")
	target_include_directories(${TARGET_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
	target_compile_definitions(${TARGET_NAME} PUBLIC "FUNNAME=${FUNNAME}")
	target_compile_definitions(${TARGET_NAME} PRIVATE "USE_STH=${USE_STH}")
	
	string(REPLACE ";" " and " NEW_COMPONENTS ${STH_COMPONENTS})
	target_compile_definitions(${TARGET_NAME} PRIVATE "OTHER=\"${NEW_COMPONENTS}\"")
endfunction()

