// 'Hello World!' program 
 
#include <iostream>
#include "feature-static.h"
#include "lib_shared.h"
#include "lib_header.h"
#define STRINGIFY2(X) #X
#define STRINGIFY(X) STRINGIFY2(X)

#ifndef BLA
#define BLA BLU
#endif

int main()
{
  std::cout << "Hello "<< FUNNAME()<<"! BLA equals " STRINGIFY(BLA) "." << std::endl;
  
  int vbar=bar();
  int vheader_fun=header_fun();
  int vcomp_sum=comp_sum();
  
  std::cout << "bar() = "<< vbar <<"; header_fun() = " << vheader_fun << "; comp_sum() = " << vcomp_sum << std::endl;
  return 0;
}
