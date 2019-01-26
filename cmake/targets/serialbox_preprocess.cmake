set(LINK_PARAMETERS 
)

set(TARGET_PARAMETERS 
	TARGET_DIR	SCALAR	STRING "${CMAKE_CURRENT_BINARY_DIR}/ppser"
	SOURCE	SCALAR	STRING "" 
)

set(ENUM_TEMPLATES PPSER)

set(PROJECT_OPTIONS SHARED_FOLDER ON)

function(declare_dependencies TEMPLATE_NAME)
	build_target(Serialbox::SerialboxFortranStatic)
	build_target(Python::Interpreter PYTHON_FAMILY 2.x)
endfunction()

function(generate_targets TEMPLATE_NAME)
	
	
	message(FATAL_ERROR "LOCATION: ${LOCATION}")
	if("${SOURCE}" STREQUAL "")
		message(FATAL_ERROR "SOURCE cannot be empty")
	endif()
	find_package(Python2 COMPONENTS Interpreter REQUIRED)
	set(Python_EXECUTABLE "${Python2_EXECUTABLE}")
	
	file(RELATIVE_PATH TMP_REL_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}" "${SOURCE}")
	get_filename_component(REL_TARGET_DIR "${TMP_REL_SOURCE}" DIRECTORY)
	get_filename_component(REL_TARGET_FILENAME "${TMP_REL_SOURCE}" NAME)
	set(TARGET_DIR "${CMAKE_CURRENT_BINARY_DIR}/${REL_TARGET_DIR}")
	
	add_custom_target(${PPSER_TARGET_NAME}
		COMMAND mkdir -p ${TARGET_DIR} && ${Python_EXECUTABLE} ${SERIALBOX2PP_PPSER_LOCATION} -d ${TARGET_DIR} ${SOURCE}
		BYPRODUCTS "${TARGET_DIR}/${REL_TARGET_FILENAME}"
		DEPENDS ${SOURCE}
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		COMMENT "Preprocessing file ${TMP_REL_SOURCE} for Serialbox 2..."
		VERBATIM
	)
endfunction()

function(apply_to_target __INSTANCE_NAME __DEP_INSTANCE_NAME)
	target_sources(${__INSTANCE_NAME} PRIVATE ${__DEP_INSTANCE_NAME})
endfunction()

