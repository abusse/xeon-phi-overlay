/* libquadmath; with -DHOSTREF the same values via binary128 long double. */
#include <stdio.h>
#include <stdlib.h>
#ifdef HOSTREF
#include <math.h>
typedef long double q;
#define SQRT sqrtl
#define EXP expl
#define SIN sinl
#define LOG logl
#define FMA fmal
#define STRTO(s) strtold(s, 0)
static void pr(const char *n, q v) { printf("%s %.33Le\n", n, v); }
#else
#include <quadmath.h>
typedef __float128 q;
#define SQRT sqrtq
#define EXP expq
#define SIN sinq
#define LOG logq
#define FMA fmaq
#define STRTO(s) strtoflt128(s, 0)
static void pr(const char *n, q v)
{
	char b[64];
	quadmath_snprintf(b, sizeof b, "%.33Qe", v);
	printf("%s %s\n", n, b);
}
#endif

int main(int argc, char **argv)
{
	volatile q two = 2 + (argc > 99), one = 1, third;
	(void)argv;
	third = one / 3;
	pr("sqrt2", SQRT(two));
	pr("e", EXP(one));
	pr("sin1", SIN(one));
	pr("ln2", LOG(two));
	pr("third", third);
	pr("fma", FMA(third, 3, -one));
	pr("strto", STRTO("3.14159265358979323846264338327950288"));
	return 0;
}
