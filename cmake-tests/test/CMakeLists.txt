# Common header for superproject
# ---------------

cmake_minimum_required(VERSION 3.13)

include(../../cmake/beetroot.cmake)

PROJECT(TEST C)
ENABLE_TESTING(TEST_ON_BUILD)
set(WYBOR "BLU")

build_target(SELF_TEST)

#ADD_TEST(NAME tescik COMMAND project/main)


finalizer()

