/* glibc's f32fmaf128 pattern (math-narrow.h): x must survive the fma
   result passing through the TImode reload to the vector register.  */
#include <stdio.h>
#include <fenv.h>

typedef __float128 F;
union u128
{
	F d;
	struct
	{
		unsigned int mantissa3:32;
		unsigned int mantissa2:32;
		unsigned int mantissa1:32;
		unsigned int mantissa0:16;
		unsigned int exponent:15;
		unsigned int negative:1;
	} ieee;
};

__attribute__((noinline)) static F fma_q(F a, F b, F c) { return a * b + c; }
__attribute__((noinline)) static void hold(fenv_t *e) { feholdexcept(e); fesetround(FE_TOWARDZERO); }
__attribute__((noinline)) static int upd(fenv_t *e)
{
	int r = fetestexcept(FE_INEXACT);
	feupdateenv(e);
	return r;
}

__attribute__((noinline)) static float f32fma(F x, F y, F z)
{
	F tmp;
	float ret;
	tmp = ({ fenv_t env; union u128 u; hold(&env);
		u.d = fma_q(({ F __x = x; __asm("" : "+m"(__x)); __x; }), y, z);
		{ F __y = u.d; __asm volatile("" : : "m"(__y)); }
		u.ieee.mantissa3 |= upd(&env) != 0;
		u.d; });
	if (tmp == 0)
		ret = (float)(({ F __x = x; __asm("" : "+m"(__x)); __x; }) * y + z);
	else
		ret = (float)tmp;
	return ret;
}

int main(void)
{
	printf("%g %g %g %g\n", f32fma(-0.0Q, -0.0Q, -0.0Q), f32fma(0.0Q, -0.0Q, -0.0Q),
	       f32fma(2, 3, 1), f32fma(-1, 0.0Q, 0.0Q));
	return 0;
}
