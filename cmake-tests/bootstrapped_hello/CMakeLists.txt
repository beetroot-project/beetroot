cmake_minimum_required(VERSION 3.13)
include(../../cmake/beetroot_bootstrap.cmake)

project(bootstrapped_hello_simple)

 build_target(BOOTSTRAPPED_HELLO_SIMPLE)
set(WHO "Venus")
build_target(BOOTSTRAPPED_HELLO_SIMPLE)
build_target(BOOTSTRAPPED_HELLO_SIMPLE WHO Mars)

finalize()

