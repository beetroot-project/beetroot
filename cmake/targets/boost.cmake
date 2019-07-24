set(ENUM_TEMPLATES BOOST)

set(TARGET_FEATURES
	MIN_VERSION SCALAR VERSION 1.68.0
)

set(TARGET_PARAMETERS
	COMPONENT SCALAR STRING ""
	REQUIRED OPTION BOOL OFF
)

set(LINK_PARAMETERS 
	FUSION_MAX_VECTOR_SIZE	SCALAR	"CHOICE(:20:40:60)" ""
	NO_PREPROCESSED_HEADERS OPTION BOOL OFF
)

set(TEMPLATE_OPTIONS
	NICE_NAME "Boost library"
	DONT_LINK_TO_DEPENDEE
	NO_TARGETS
)

#function(declare_dependencies TEMPLATE_NAME)
#  	build_target(BOOST_SINGLETON COMPONENTS ${COMPONENT} ) #Version is the same
#endfunction()

function(apply_dependency_to_target DEPENDEE_TARGET TARGET_NAME)
	if(REQUIRED)
		set(REQUIRED REQUIRED)
	else()
		set(REQUIRED )
	endif()
	find_package( Boost ${MIN_VERSION} COMPONENTS "${COMPONENT}" ${REQUIRED} )
	if(NOT Boost_FOUND)
		message(FATAL_ERROR "Cannot find boost library")
	endif()
	if(TARGET "Boost::${COMPONENT}")
#		message(WARNING "target_link_libraries(${DEPENDEE_TARGET} ${KEYWORD} \"Boost::${COMPONENT}\"")
		target_link_libraries(${DEPENDEE_TARGET} ${KEYWORD} "Boost::${COMPONENT}")
	else()
	   target_include_directories(${DEPENDEE_TARGET} ${KEYWORD} ${Boost_INCLUDE_DIRS} )
		target_link_libraries(${DEPENDEE_TARGET} ${KEYWORD} "${Boost_LIBRARIES}")
	endif()
	
	if(NO_PREPROCESSED_HEADERS)
		target_compile_definitions(${DEPENDEE_TARGET} ${KEYWORD} "BOOST_MPL_CFG_NO_PREPROCESSED_HEADERS=1")
	endif()
	if(NOT "${FUSION_MAX_VECTOR_SIZE}" STREQUAL "")
		target_compile_definitions(${DEPENDEE_TARGET} ${KEYWORD} "BOOST_MPL_LIMIT_VECTOR_SIZE=${FUSION_MAX_VECTOR_SIZE}")
	endif()
endfunction()

