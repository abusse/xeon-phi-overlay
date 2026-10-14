#include <stdio.h>
#include <dlfcn.h>

extern double dso_fn(double, float, int);
extern double dso_scale;

int main(void)
{
	printf("dso %.17g\n", dso_fn(2.0, 0.5f, 10));
	dso_scale = 0.5;
	printf("dso %.17g\n", dso_fn(2.0, 0.5f, 10));
	void *h = dlopen("libknctest.so", RTLD_NOW);
	double (*fn)(double, float, int) = h ? (double (*)(double, float, int))dlsym(h, "dso_fn") : 0;
	printf("dlsym %d %.17g\n", fn == dso_fn, fn ? fn(1.0, 1.0f, 3) : -1.0);
	return 0;
}
