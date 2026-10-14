/* complex __float128 by value (pushed on the stack) through a call. */
#include <stdio.h>

typedef _Complex float __attribute__((mode(TC))) c128;

__attribute__((noinline)) static c128 twice(c128 z)
{
	return z + z;
}

__attribute__((noinline)) static c128 g(c128 x, c128 y)
{
	return twice(y * x);
}

int main(void)
{
	c128 x = 1.5 + 2.0i, y = 3.0 - 0.5i;
	c128 r = g(x, y);
	printf("%g %g\n", (double)__real__ r, (double)__imag__ r);
	return 0;
}
