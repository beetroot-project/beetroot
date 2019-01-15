// 'Hello World!' program 
 
#include <iostream>
#define STRINGIFY2(X) #X
#define STRINGIFY(X) STRINGIFY2(X)

#ifndef KTO
#define KTO World
#endif

int main()
{
  std::cout << "Hello " STRINGIFY(KTO) "!" << std::endl;
  return 0;
}
