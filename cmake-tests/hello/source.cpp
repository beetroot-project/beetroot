// 'Hello World!' program 
 
#include <iostream>
#include "libhello.h"
#define STRINGIFY2(X) #X
#define STRINGIFY(X) STRINGIFY2(X)

#ifndef BLA
#define BLA BLU
#endif

#ifndef NESTED_LIBPAR
#define NESTED_LIBPAR 0
#endif

#ifndef LIBPAR
#define LIBPAR 0
#endif

int main()
{
  int nested_libpar = NESTED_LIBPAR;
  int libpar = LIBPAR;
  
  std::cout << "Hello "<< get_string()<<"! BLA equals " STRINGIFY(BLA) "." << std::endl;
  std::cout << "LIBPAR = "<< libpar <<", NESTED_LIBPAR = "<< nested_libpar << std::endl;
  return 0;
}
