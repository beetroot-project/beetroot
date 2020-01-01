#include "lib1.h"

int lib1() {
#if EXTRAS==1
   return 23;
#else
   return 29;
#endif
}
