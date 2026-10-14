/* Floating-point calling convention and vector-register moves on k1om:
   FP args/returns live in zmm (as xmm), stores go through vpackstore,
   misaligned FP/DI moves go through a stack slot.  */
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <complex.h>

#define NI __attribute__((noinline, noclone))

NI float  addf(float a, float b) { return a + b; }
NI double addd(double a, double b) { return a + b; }
NI long double addld(long double a, long double b) { return a + b; }
NI __float128 addq(__float128 a, __float128 b) { return a * b + a; }

NI double many(double a, double b, double c, double d, double e, double f,
	       double g, double h, double i, double j, float k, int l, double m)
{
	return a + 2*b + 3*c + 4*d + 5*e + 6*f + 7*g + 8*h + 9*i + 10*j
	       + 11*k + 12*l + 13*m;
}

NI double mixed(int a, float b, long c, double d, char e, float f)
{
	return a * b + c * d + e + f;
}

NI double vsum(int n, ...)
{
	va_list ap;
	double s = 0;
	va_start(ap, n);
	for (int i = 0; i < n; i++)
		s += (i & 1) ? va_arg(ap, int) : va_arg(ap, double);
	va_end(ap);
	return s;
}

struct sd2 { double x, y; };
struct smix { double d; int i; float f; };
NI struct sd2 sd2_add(struct sd2 a, struct sd2 b) { a.x += b.x; a.y += b.y; return a; }
NI struct smix smix_f(struct smix m) { m.d *= 2; m.i += 1; m.f -= 0.5f; return m; }

NI float complex cmulf(float complex a, float complex b) { return a * b; }
NI double complex cmul(double complex a, double complex b) { return a * b; }

struct __attribute__((packed)) pk {
	char c;
	float f;
	double d;
	long l;
	char c2;
};

NI void pk_upd(struct pk *p, float f, double d)
{
	p->f += f;
	p->d *= d;
	p->l += (long)d;
}

struct al4 { int i; float f[3]; double d; } __attribute__((aligned(4)));

typedef double (*dfn)(double, double);
NI double apply(dfn f, double a, double b) { return f(a, b); }
NI double dmin(double a, double b) { return a < b ? a : b; }

static volatile double vd = 3.25;
static volatile float vf = -1.5f;

int main(void)
{
	char q[64];

	printf("addf %.9g\n", addf(1.25f, vf));
	printf("addd %.17g\n", addd(vd, 1e-3));
	printf("addld %.21Lg\n", addld(1.0L / 3, 2.0L));
	__float128 r = addq(1.5Q, 2.25Q);
	printf("addq %.17g\n", (double)r);
	printf("many %.17g\n", many(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11.5f, 12, 13.25));
	printf("mixed %.17g\n", mixed(3, 1.5f, 7, vd, 'A', vf));
	printf("vsum %.17g\n", vsum(9, 1.5, 2, 3.5, 4, 5.5, 6, 7.5, 8, 9.25));

	struct sd2 b = sd2_add((struct sd2){1e10, 2}, (struct sd2){vd, -0.5});
	printf("sd2 %.17g %.17g\n", b.x, b.y);
	struct smix m = smix_f((struct smix){1.25, 41, 2.0f});
	printf("smix %g %d %g\n", m.d, m.i, m.f);

	float complex cf = cmulf(1.0f + 2.0f * I, 3.0f - 1.0f * I);
	printf("cmulf %g %g\n", crealf(cf), cimagf(cf));
	double complex cd = cmul(vd + 1.0 * I, -2.0 + 0.5 * I);
	printf("cmul %.17g %.17g\n", creal(cd), cimag(cd));

	struct pk p;
	memset(&p, 0, sizeof p);
	p.f = 1.0f; p.d = 2.0; p.l = 3;
	pk_upd(&p, vf, vd);
	printf("pk %g %.17g %ld\n", p.f, p.d, p.l);

	struct al4 arr[3];
	for (int i = 0; i < 3; i++) {
		arr[i].i = i;
		for (int j = 0; j < 3; j++)
			arr[i].f[j] = i * 10 + j + 0.5f;
		arr[i].d = i * vd;
	}
	double s = 0;
	for (int i = 0; i < 3; i++)
		s += arr[i].d + arr[i].f[0] + arr[i].f[2];
	printf("al4 %.17g\n", s);

	printf("apply %.17g\n", apply(dmin, vd, -vd));
	snprintf(q, sizeof q, "%.3f|%e|%a", vd, (double)vf, 0.1);
	printf("fmt %s\n", q);
	return 0;
}
