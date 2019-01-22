// 'Hello World!' program 

#include "feature-static.h"

#define STRINGIFY2(X) #X
#define STRINGIFY(X) STRINGIFY2(X)


std::string FUNNAME() {
	string out = "default";
	if(USE_STH){
		out+="STH"
	}
	
	return(out + " with features " + STRINGIFY(OTHER) + "!");
}
 

