/* soft-fp __float128 with traps masked: exact tiny results must not raise underflow. */
#include <stdio.h>
#include <fenv.h>
static void t(const char *n, __float128 a, __float128 b, int op)
{
	volatile __float128 x = a, y = b, r;
	feclearexcept(FE_ALL_EXCEPT);
	r = op == 0 ? x * y : op == 1 ? x / y : x + y;
	(void)r;
	printf("%-12s uf=%d inex=%d\n", n, !!fetestexcept(FE_UNDERFLOW), !!fetestexcept(FE_INEXACT));
}
int main(void)
{
	__float128 m = 0x1p-16382Q;	/* FLT128_MIN; __FLT128_MIN__ needs GCC 7 */
	t("exact-mul", m, 0.5Q, 0);
	t("exact-div", m, 4.0Q, 1);
	t("exact-add", m, -m * 0.75Q, 2);
	t("inexact-mul", m, 1.0Q / 3, 0);
	volatile __float128 q = 0x1p-1074Q;
	volatile double d;
	feclearexcept(FE_ALL_EXCEPT);
	d = (double)q;
	(void)d;
	printf("%-12s uf=%d inex=%d\n", "narrow-exact", !!fetestexcept(FE_UNDERFLOW), !!fetestexcept(FE_INEXACT));
	return 0;
}
