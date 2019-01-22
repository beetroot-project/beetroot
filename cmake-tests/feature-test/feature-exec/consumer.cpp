// 'Hello World!' program 
 
#include <iostream>
#include "feature-static.h"
#define STRINGIFY2(X) #X
#define STRINGIFY(X) STRINGIFY2(X)

#ifndef BLA
#define BLA BLU
#endif

int main()
{
  std::cout << "Hello "<< FUNNAME()<<"! BLA equals " STRINGIFY(BLA) "." << std::endl;
  return 0;
}
