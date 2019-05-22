set(ENUM_TEMPLATES FEATURE-STATICLIB)

set(TARGET_PARAMETERS 
	FUNNAME SCALAR STRING "get_string"
)

set(TARGET_FEATURES 
	USE_STH	OPTION	BOOL	0
	STH_COMPONENTS	VECTOR	STRING	"compdefault"
)

function(generate_targets TARGET_NAME TEMPLATE_NAME)
	message(STATUS "LibHello: inside generate_targets trying to define ${TARGET_NAME} in ${CMAKE_CURRENT_SOURCE_DIR}/include. STH_COMPONENTS: ${STH_COMPONENTS}")
	add_library(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/libsource.cpp")
	target_include_directories(${TARGET_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
	target_compile_definitions(${TARGET_NAME} PUBLIC "FUNNAME=${FUNNAME}")
	target_compile_definitions(${TARGET_NAME} PRIVATE "USE_STH=${USE_STH}")
	
	string(REPLACE ";" " and " NEW_COMPONENTS ${STH_COMPONENTS})
	target_compile_definitions(${TARGET_NAME} PRIVATE "OTHER=\"${NEW_COMPONENTS}\"")
endfunction()

