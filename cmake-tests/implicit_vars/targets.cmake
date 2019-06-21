set(ENUM_TEMPLATES IMPLICIT_VARS)

include_features_of(JUST_VAR_LIB)

set(TARGET_PARAMETERS 
)

set(LINK_PARAMETERS 
	LINKPAR1 SCALAR INTEGER 0
)

set(TEMPLATE_OPTIONS
	NO_TARGETS
)

function(declare_dependencies TEMPLATE_NAME)
	set(IMPLICIT_LOCAL    "OK from implicit_vars")
	set(IMPLICIT_IMPORTED "OK from implicit_vars")
#	set(IMPLICIT_EXPORTED "OK from implicit_vars")
	message(STATUS "IMPLICIT_VARS: calling IMPLICIT_VARS_SUBTARGET...")
	build_target(IMPLICIT_VARS_SUBTARGET)
endfunction()

