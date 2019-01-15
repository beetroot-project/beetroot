// 'Hello World!' program 

#include "libhello.h"

#define STRINGIFY2(X) #X
#define STRINGIFY(X) STRINGIFY2(X)

#ifndef KTO
#define KTO World
#endif

#ifndef FUNNAME
#define FUNNAME get_string
#endif

std::string FUNNAME() {
	return(STRINGIFY(KTO));
}
 

