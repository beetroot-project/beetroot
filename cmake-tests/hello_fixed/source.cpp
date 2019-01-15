// 'Hello World!' program 
 
#include <iostream>
//#include "libhello.h"
#define STRINGIFY2(X) #X
#define STRINGIFY(X) STRINGIFY2(X)

#ifndef BLA
#define BLA BLU
#endif

int main()
{
  std::cout << "Fixed World! BLA equals " STRINGIFY(BLA) "." << std::endl;
  return 0;
}
