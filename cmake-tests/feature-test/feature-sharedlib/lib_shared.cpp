#include "lib_shared.h"

#ifdef FUN_FOO
int foo() {
	return MYPAR;
}
#endif


#ifdef FUN_BAR
int bar() {
	return MYPAR;
}
#endif

int comp_sum() {
	return 
#ifdef COMP_1
	1 +
#endif
#ifdef COMP_2
	20 + 
#endif
#ifdef COMP_3
	300 +
#endif
#ifdef COMP_4
	4000 +
#endif
0;
}

