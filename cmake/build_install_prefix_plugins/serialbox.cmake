get_filename_component(__PREFIX "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
get_filename_component(__PREFIX "${__PREFIX}" DIRECTORY)
include(${__PREFIX}/get_version_from_git_tag.cmake)
get_version_from_git_tag(PATH ${SUPERBUILD_ROOT}/serialbox2 OUT _VERSION)

set(SERIALBOX_VERSION_STRING "SB${_VERSION}")
