# Common header for superproject
# ---------------

cmake_minimum_required(VERSION 3.13)

include(../../cmake/beetroot.cmake)

project(hello)

build_target(FEATURE-LIB1 FUNNAME "alt_getstring" STH_COMPONENTS CMakeLists) #without this line, feature-exec should fail
build_target(FEATURE-LIB1 FUNNAME "getstring" STH_COMPONENTS CMakeLists) #without this line, feature-exec should fail
#build_target(FEATURE-STATICLIB FUNNAME "YY") #without this line, feature-exec should fail
build_target(FEATURE-EXEC)

#get_existing_target(FEATURE-LIB1 STH_COMPONENTS CMakeLists)
build_target(FEATURE_SHAREDLIB 		
	LIB_COMPONENTS C1 C3
	MYPAR 13
)


finalizer()
