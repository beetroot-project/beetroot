set(ENUM_TARGETS _external_lib1
)

set(BUILD_PARAMETERS 
	LIB1ARG SCALAR INTEGER "1"
)

set(BUILD_FEATURES 
   EXTRA_FUN   OPTION BOOL 0
)

set(DEFINE_EXTERNAL_PROJECT 
#	NAME "External lib1"
	SOURCE_PATH "${SUPERBUILD_ROOT}/cmake-tests/external_projects/lib1"
)

function(build_version_string OUT_STRING)
   set(${OUT_STRING} "1.0" PARENT_SCOPE)
endfunction()

set(FILE_OPTIONS DONT_LINK_TO_DEPENDEE)

function(apply_dependency_to_target DEPENDEE WE INSTALL_PATH)
   include("${INSTALL_PATH}/cmake/_EXTERNAL_LIB1-targets.cmake")
   target_link_libraries(${DEPENDEE} PRIVATE ${WE})
endfunction()
