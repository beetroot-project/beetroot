enable_language(CXX)
find_package(Boost)
if(NOT Boost_FOUND)
	message(FATAL_ERROR "BOOST NOT FOUND")
endif()
set(BOOST_VERSION_STRING "BOOST${Boost_LIB_VERSION}")
