// 'Hello World!' program 

#include "feature-static.h"
#include "lib_shared.h"
#include<string>

#define STRINGIFY2(X) #X
#define STRINGIFY(X) STRINGIFY2(X)


std::string FUNNAME() {
	std::string out = "default";
	if(USE_STH)
		out+=", STH";
	
	return(out + " with features " + STRINGIFY(OTHER) + ". Foo() = " + std::to_string(foo()));
}
 

