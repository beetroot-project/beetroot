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
#get_target(fiksik __OUT_INSTANCE_NAME)
##get_target(fiksik __OUT_INSTANCE_NAME NONSIGINIFICANT X LIBKTO Mik )  #generates error
#build_target(HELLO_BOOST)
#build_target(HELLO_2BOOST)
#build_target(HELLO_2BOOST PAR KUC)
#build_target(SERIALBOX_C_TEST)


finalizer()
