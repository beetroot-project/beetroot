# Common header for superproject
# ---------------

cmake_minimum_required(VERSION 3.13)

include(../cmake/beetroot.cmake)


project(hello)

set(WYBOR "BLU")

build_target(HELLO_SIMPLE)
build_target(HELLO )
build_target(HELLO LIBKTO from_arg_CMakeLists)
build_target(HELLO LIBKTO Mama)
build_target(HELLO LIBKTO Mama NONSIGINIFICANT boo)
build_target(HELLO LIBKTO Sofia NONSIGINIFICANT boo)
build_target(fiksik)
##build_target(fiksik NONSIGINIFICANT X LIBKTO Mik )  #generates error
#build_target(HELLO_BOOST)
#build_target(HELLO_2BOOST)
#build_target(HELLO_2BOOST PAR KUC)
build_target(HEADER_CONSUMER)

build_target(BOOTSTRAPPED_HELLO_SIMPLE)

#build_target(SERIALBOX_C_TEST)
#build_target(SERIALBOX_C_TEST2 SERIALBOX_USE_NETCDF 0 SERIALBOX_ENABLE_FORTRAN 1 SERIALBOX_EXAMPLES 1 ) #Works only with SERIALBOX_C_TEST
#build_target(SERIALBOX_C_TEST2) 


build_target(FEATURE-LIB1 FUNNAME "alt_getstring" STH_COMPONENTS CMakeLists) #without this line, feature-exec should fail
build_target(FEATURE-LIB1 FUNNAME "getstring" STH_COMPONENTS CMakeLists) #without this line, feature-exec should fail
#build_target(FEATURE-STATICLIB FUNNAME "YY") #without this line, feature-exec should fail
build_target(FEATURE-EXEC)
#get_existing_target(FEATURE-LIB1 STH_COMPONENTS CMakeLists)
build_target(FEATURE_SHAREDLIB 		
	LIB_COMPONENTS C1 C3
	MYPAR 13
)



build_target(SELF_TEST)

set(IMPLICIT_GLOBAL "OK CMakeLists")
build_target(IMPLICIT_VARS)
build_target(EXPORT_VAR 
	IMPLICIT_EXPORTED "OK CMakeLists")


finalizer()
