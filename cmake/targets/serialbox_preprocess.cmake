set(ENUM_TEMPLATES PPSER)

set(LINK_PARAMETERS 
)

set(TARGET_PARAMETERS 
	TARGET_DIR	SCALAR	STRING "ppser"
	SOURCE	SCALAR	STRING "" 
)

set(TEMPLATE_OPTIONS NO_TARGETS)

function(declare_dependencies TEMPLATE_NAME)
	build_target(Serialbox::SerialboxFortranStatic)
	build_target(Python::Interpreter PYTHON_FAMILY 2.x)
endfunction()

#function(generate_targets TEMPLATE_NAME)
#	set(SERIALBOX2PP_PPSER_LOCATION "${Serialbox_SerialboxFortranStatic_INSTALL_DIR}/python/pp_ser/pp_ser.py")
#	
##	message(FATAL_ERROR "SERIALBOX2PP_PPSER_LOCATION: ${SERIALBOX2PP_PPSER_LOCATION}")
#	if("${SOURCE}" STREQUAL "")
#		message(FATAL_ERROR "SOURCE cannot be empty")
#	endif()
#	find_package(Python2 COMPONENTS Interpreter REQUIRED)
#	set(Python_EXECUTABLE "${Python2_EXECUTABLE}")
#	
#	if(IS_ABSOLUTE "${SOURCE}")
#		file(RELATIVE_PATH TMP_REL_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}" "${SOURCE}")
#	endif()
#	get_filename_component(REL_TARGET_DIR "${TMP_REL_SOURCE}" DIRECTORY)
#	get_filename_component(REL_TARGET_FILENAME "${TMP_REL_SOURCE}" NAME)
#	set(TARGET_DIR "${CMAKE_CURRENT_BINARY_DIR}/${REL_TARGET_DIR}")
#	
#	add_custom_command(OUTPUT "${TARGET_DIR}/${REL_TARGET_FILENAME}"
#		COMMAND mkdir -p ${TARGET_DIR} && ${Python_EXECUTABLE} ${SERIALBOX2PP_PPSER_LOCATION} -d ${TARGET_DIR} ${SOURCE}
#		DEPENDS ${SOURCE}
#		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
#		COMMENT "Preprocessing file ${TMP_REL_SOURCE} for Serialbox..."
#		VERBATIM
#	)
#	add_custom_target(${PPSER_TARGET_NAME}
#		COMMAND mkdir -p ${TARGET_DIR} && ${Python_EXECUTABLE} ${SERIALBOX2PP_PPSER_LOCATION} -d ${TARGET_DIR} ${SOURCE}
#		BYPRODUCTS "${TARGET_DIR}/${REL_TARGET_FILENAME}"
#		DEPENDS ${SOURCE}
#		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
#		COMMENT "Preprocessing file ${TMP_REL_SOURCE} for Serialbox..."
#		VERBATIM
#	)
#endfunction()

function(apply_dependency_to_target DEPENDEE_TARGET_NAME OUR_TARGET_NAME)
	set(SERIALBOX2PP_PPSER_LOCATION "${Serialbox_SerialboxFortranStatic_INSTALL_DIR}/python/pp_ser/pp_ser.py")
	
#	message(FATAL_ERROR "SERIALBOX2PP_PPSER_LOCATION: ${SERIALBOX2PP_PPSER_LOCATION}")
	if("${SOURCE}" STREQUAL "")
		message(FATAL_ERROR "SOURCE cannot be empty")
	endif()
	find_package(Python2 COMPONENTS Interpreter REQUIRED)
	set(Python_EXECUTABLE "${Python2_EXECUTABLE}")
	
	get_target_property(DEPENDEE_SOURCE_DIR ${DEPENDEE_TARGET_NAME} SOURCE_DIR)
	get_target_property(DEPENDEE_BINARY_DIR ${DEPENDEE_TARGET_NAME} BINARY_DIR)
	
	if(IS_ABSOLUTE "${SOURCE}")
		file(RELATIVE_PATH TMP_REL_SOURCE "${DEPENDEE_SOURCE_DIR}" "${SOURCE}")
	else()
		set(TMP_REL_SOURCE "${SOURCE}")
	endif()
	
	get_filename_component(REL_TARGET_DIR "${TMP_REL_SOURCE}" DIRECTORY)
	get_filename_component(REL_TARGET_FILENAME "${TMP_REL_SOURCE}" NAME)
	set(TARGET_DIR "${DEPENDEE_BINARY_DIR}/${TARGET_DIR}/${REL_TARGET_DIR}")
	message(STATUS "PPSER: mkdir -p ${TARGET_DIR} && ${Python_EXECUTABLE} ${SERIALBOX2PP_PPSER_LOCATION} -d ${TARGET_DIR} ${SOURCE}")
	add_custom_command(OUTPUT "${TARGET_DIR}/${REL_TARGET_FILENAME}"
		COMMAND mkdir -p ${TARGET_DIR} && ${Python_EXECUTABLE} ${SERIALBOX2PP_PPSER_LOCATION} -d ${TARGET_DIR} ${SOURCE}
		DEPENDS ${SOURCE}
		WORKING_DIRECTORY ${DEPENDEE_BINARY_DIR}
		COMMENT "Preprocessing file ${TMP_REL_SOURCE} for Serialbox..."
		VERBATIM
	)


	message(STATUS "target_sources(${DEPENDEE_TARGET_NAME} ${KEYWORD} ${TARGET_DIR}/${REL_TARGET_FILENAME})")
	target_sources(${DEPENDEE_TARGET_NAME} ${KEYWORD} ${TARGET_DIR}/${REL_TARGET_FILENAME})
endfunction()

