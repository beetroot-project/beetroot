# Common header for superproject
# ---------------

cmake_minimum_required(VERSION 3.13)

include(../../../cmake/beetroot.cmake)

project(hello)

build_target(CS_1) #without this line, feature-exec should fail


finalizer()
