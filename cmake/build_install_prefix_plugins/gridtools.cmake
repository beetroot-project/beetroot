include(get_version_from_git_tag)
get_version_from_git_tag(PATH ${SUPERBUILD_ROOT}/gridtools OUT _VERSION)

set(GRIDTOOLS_VERSION_STRING "GT${_VERSION}")
