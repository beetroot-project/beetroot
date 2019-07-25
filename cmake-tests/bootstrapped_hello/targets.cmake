set(ENUM_TEMPLATES BOOTSTRAPPED_HELLO_SIMPLE)

set(BUILD_PARAMETERS 
  WHO SCALAR STRING "Beetroot"
)

function(generate_targets TARGET_NAME TEMPLATE_NAME)
  add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/source.cpp")
  target_compile_definitions(${TARGET_NAME} PRIVATE "WHO=${WHO}")
endfunction()

