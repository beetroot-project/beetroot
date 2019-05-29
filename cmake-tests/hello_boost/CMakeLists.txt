# Common header for superproject
# ---------------

cmake_minimum_required(VERSION 3.13)

include(../../cmake/beetroot.cmake)

project(hello)

set(WYBOR "BLU")

build_target(HELLO_BOOST)


# Folder-specific configuration. Don't use relative paths and  CMAKE_CURRENT_SOURCE_DIR - use prefix paths with ${CMAKE_CURRENT_LIST_FILE}/ instead. 
#Also make sure the file can be parsed multiple times without errors.
# ---------------

#make_current_target(TARGET_NAME)

#set(MY_VAR1 "VALUE" CACHE STRING "Description")
#set(MY_VAR2 "VALUE")

#get_property(VAR1 CACHE MY_VAR1 PROPERTY TYPE SET)
#get_property(VAR2 CACHE MY_VAR2 PROPERTY TYPE SET)

#message(STATUS "VAR1: ${VAR1}")
#message(STATUS "VAR2: ${VAR2}")


#set(CP__LIST PAR_A PAR_C PAR_B)
#set(ARG__LIST PAR_MT_A PAR_MT_C PAR_MT_B)
#set(ARG_MT_PAR_A "ARG_A")
#set(ARG_MT_PAR_B "ARG_B")
#set(ARG_MT_PAR_C "ARG_C")
#calculate_hash(
#	TARGET MT
#	PARS CP
#	PREFIXED_VARS ARG
#	OUT MY_HASH
#)
#message(FATAL_ERROR "MY_HASH: ${MY_HASH}")

finalizer()
