# Common header for superproject
# ---------------

cmake_minimum_required(VERSION 3.13)

include(../../cmake/beetroot.cmake)


project(hello)

set(WYBOR "BLU")

get_target(HELLO __OUT_INSTANCE_NAME)
#get_target(HELLO __OUT_INSTANCE_NAME LIBKTO from_arg_CMakeLists)
#get_target(HELLO __OUT_INSTANCE_NAME LIBKTO Mama)
#get_target(HELLO __OUT_INSTANCE_NAME LIBKTO Mama NONSIGINIFICANT boo)
#get_target(HELLO __OUT_INSTANCE_NAME LIBKTO Sofia NONSIGINIFICANT boo)


finalizer()
