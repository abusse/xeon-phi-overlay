/* x87 scalar math, compares incl. NaN, conversions, libm; branchy code
   where other x86 targets would use cmov/fcmov.  */
#include <stdio.h>
#include <math.h>
#include <float.h>
#include <stdint.h>
#include <fenv.h>

#define NI __attribute__((noinline, noclone))

NI int cmpd(double a, double b)
{
	return (a < b) | (a <= b) << 1 | (a == b) << 2 | (a != b) << 3
	       | (a > b) << 4 | (a >= b) << 5 | isunordered(a, b) << 6
	       | isless(a, b) << 7 | isgreater(a, b) << 8;
}

NI int cmpf(float a, float b)
{
	return (a < b) | (a <= b) << 1 | (a == b) << 2 | (a != b) << 3
	       | (a > b) << 4 | (a >= b) << 5 | isunordered(a, b) << 6;
}

NI double selmax(double a, double b) { return a > b ? a : b; }
NI float clampf(float x, float lo, float hi) { return x < lo ? lo : x > hi ? hi : x; }
NI long selint(double a, long x, long y) { return a > 0 ? x : y; }

NI double poly(const double *c, int n, double x)
{
	double r = 0;
	for (int i = n - 1; i >= 0; i--)
		r = r * x + c[i];
	return r;
}

int main(void)
{
	volatile double nan = NAN, inf = INFINITY, one = 1.0, zero = 0.0;
	volatile float fnan = NAN, fone = 1.0f;
	double vals[] = { -2.5, -0.0, 0.0, 1e-310, 1.0, 3.5, 1e300 };

	for (int i = 0; i < 7; i++)
		for (int j = 0; j < 7; j++)
			printf("%x%c", cmpd(vals[i], vals[j]), j == 6 ? '\n' : ' ');
	printf("nan %x %x %x %x\n", cmpd(nan, one), cmpd(one, nan), cmpd(nan, nan),
	       cmpf(fnan, fone));
	printf("inf %x %x\n", cmpd(inf, 1e308), cmpd(-inf, -1e308));

	printf("sel %g %g %g %g\n", selmax(1, 2), selmax(-0.0, 0.0), selmax(nan, 1), selmax(1, nan));
	printf("clamp %g %g %g %g\n", clampf(-5, -1, 1), clampf(0.25f, -1, 1),
	       clampf(9, -1, 1), clampf(fnan, -1, 1));
	printf("selint %ld %ld %ld\n", selint(1, 10, 20), selint(-1, 10, 20), selint(nan, 10, 20));

	double c[] = { 1, -0.5, 1.0 / 24, -1.0 / 720, 1.0 / 40320 };
	printf("poly %.17g\n", poly(c, 5, 0.7));

	printf("libm %.17g %.17g %.17g %.17g\n", sin(one), sqrt(2.0 * one), pow(one + 1, 0.5),
	       exp(-one));
	printf("libmf %.9g %.9g %.9g\n", sinf(fone), sqrtf(2.0f * fone), logf(10.0f * fone));
	printf("round %g %g %g %g %ld %ld\n", floor(-2.5), ceil(-2.5), rint(2.5), round(2.5),
	       lrint(-3.5), lround(-3.5));

	double big = 9.2e18;
	volatile long l = -123456789012345L;
	volatile unsigned long ul = 18446744073709551615UL;
	printf("conv %ld %lu %.17g %.17g %d %u\n", (long)big, (unsigned long)(big * 1.5),
	       (double)l, (double)ul, (int)-2.9, (unsigned)3.9e9);
	printf("convf %.9g %.9g %lld\n", (float)l, (float)ul, (long long)(float)1e18);

	printf("ld %.21Lg %.21Lg\n", (long double)one / 3, sqrtl(2.0L));
	printf("eps %g %g %Lg\n", DBL_EPSILON, FLT_EPSILON, LDBL_EPSILON);
	printf("fenv %d\n", fegetround() == FE_TONEAREST);
	printf("div0 %g %g\n", one / zero, -one / zero);
	return 0;
}
