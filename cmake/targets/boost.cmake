set(BUILD_PARAMETERS 
	COMPONENTS VECTOR STRING "filesystem:system:log:date_time:thread:chrono:atomic:program_options"
	VERSION SCALAR STRING "1.68"
)

set(LINK_PARAMETERS 
	FUSION_MAX_VECTOR_SIZE	SCALAR	"CHOICE(20:40:60)" 20
)

set(ENUM_TARGETS Boost::boost Boost::filesystem Boost::system Boost::log Boost::date_time Boost::thread Boost::chrono Boost::atomic Boost::program_options)

set(FILE_OPTIONS
	NICE_NAME "Boost libraries version ${BOOST_VERSION}"
)

set(DEFINE_EXTERNAL_PROJECT 
	LINK_TO_DEPENDEE
	ASSUME_INSTALLED
	NAME Boost
	COMPONENTS "filesystem;system;log;date_time;thread;chrono;atomic;program_options"
#	APT_PACKAGES libboost-all-dev
	APT_PACKAGES "libboost-filesystem-dev;libboost-system-dev;libboost-log-dev;libboost-date_time-dev;libboost-thread-dev;libboost-chrono-dev;libboost-atomic-dev;libboost-program_options-dev"
	SPACK_PACKAGES boost
)

function(apply_dependency_to_target DEPENDEE_TARGET_NAME TARGET_NAME)
	target_compile_definitions(${DEPENDEE_TARGET_NAME} ${KEYWORD} "BOOST_MPL_CFG_NO_PREPROCESSED_HEADERS=1")
	target_compile_definitions(${DEPENDEE_TARGET_NAME} ${KEYWORD} "BOOST_MPL_LIMIT_VECTOR_SIZE=${FUSION_MAX_VECTOR_SIZE}")
endfunction()

