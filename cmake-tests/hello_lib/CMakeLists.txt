# Common header for superproject
# ---------------

cmake_minimum_required(VERSION 3.13)

include(../../cmake/beetroot.cmake)


project(hello)

set(WYBOR "BLU")

build_target(HELLO )
#build_target(HELLO LIBKTO from_arg_CMakeLists)
#build_target(HELLO LIBKTO Mama)
#build_target(HELLO LIBKTO Mama NONSIGINIFICANT boo)
#build_target(HELLO LIBKTO Sofia NONSIGINIFICANT boo)


finalizer()
