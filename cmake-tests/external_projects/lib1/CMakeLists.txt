# Common header for superproject
# ---------------

cmake_minimum_required(VERSION 3.13)

include(../../../cmake/beetroot.cmake)

project(lib1)
#set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/install" CACHE PATH "CMake install prefix" FORCE)
build_target(_EXTERNAL_LIB1)


finalizer()
