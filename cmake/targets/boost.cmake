set(DEFINE_PARAMETERS 
	FUSION_MAX_VECTOR_SIZE	SCALAR	"CHOICE(20:40:60)" 20
)

set(DEFINE_MODIFIERS 
	VERSION SCALAR "STRING" "1.68"
	COMPONENTS VECTOR STRING "filesystem:system:log:date_time:thread:chrono:atomic:program_options"
)

set(ENUM_TARGETS Boost::boost Boost::filesystem Boost::system Boost::log Boost::date_time Boost::thread Boost::chrono Boost::atomic Boost::program_options)

set(DEFINE_EXTERNAL_PROJECT 
	ASSUME_INSTALLED
	NAME Boost
	COMPONENTS "${COMPONENTS}"
)

function(generate_targets TEMPLATE_NAME) #If DEFINE_EXTERNAL_PROJECT is undefined, the Beetroot will use the following definition
	message(FATAL_ERROR "find_package(Boost  COMPONENTS ${COMPONENTS} REQUIRED)")
#	find_package(Boost ${VERSION} COMPONENTS ${COMPONENTS} REQUIRED)
	find_package(Boost  COMPONENTS ${COMPONENTS} REQUIRED)
endfunction()

function(apply_to_target TARGET_NAME)
	target_compile_definitions(${TARGET_NAME} PRIVATE "BOOST_MPL_CFG_NO_PREPROCESSED_HEADERS=1")
	target_compile_definitions(${TARGET_NAME} PRIVATE "BOOST_MPL_LIMIT_VECTOR_SIZE=${FUSION_MAX_VECTOR_SIZE}")
endfunction()
