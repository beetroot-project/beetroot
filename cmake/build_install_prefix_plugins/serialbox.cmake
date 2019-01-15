include(get_version_from_git_tag)
get_version_from_git_tag(PATH ${SUPERBUILD_ROOT}/serialbox OUT _VERSION)

set(SERIALBOX_VERSION_STRING "SB${_VERSION}")
