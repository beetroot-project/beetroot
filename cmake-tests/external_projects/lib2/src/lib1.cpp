#include "lib1.h"

int lib1() {
   return 23;
}

#if EXTRAS==1
int extrafun() {
   return 10;
}
#endif
