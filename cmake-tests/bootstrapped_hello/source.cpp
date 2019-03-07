// 'Hello World!' program 
#include <iostream>
#define STRINGIFY2(X) #X
#define STRINGIFY(X) STRINGIFY2(X)
#ifndef WHO
#define WHO World
#endif

int main() {
  std::cout << "Hello " STRINGIFY(WHO) "!" << std::endl;
  return 0;
}

