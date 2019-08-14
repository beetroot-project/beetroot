set(ENUM_TEMPLATES HINTED_TARGET)

set(BUILD_PARAMETERS 
	PREFIX	SCALAR	STRING	"BLA"
	SUFFIX SCALAR INTEGER 1
	PAR   SCALAR   INTEGER 0
)

function(declare_dependencies TEMPLATE_NAME)
   string(TOLOWER "${PREFIX}${TEMPLATE_NAME}${SUFFIX}" NAMEHINT)
   suggest_target_name("${NAMEHINT}")
endfunction()

function(generate_targets TARGET_NAME TEMPLATE_NAME)
   message(STATUS "ADD_EXECUTABLE: ${TARGET_NAME}")
	add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/source.cpp")
endfunction()

