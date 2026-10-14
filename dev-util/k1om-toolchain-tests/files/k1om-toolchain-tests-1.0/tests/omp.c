/* libgomp: parallel reduction with doubles, dynamic schedule, tasks. */
#include <stdio.h>
#include <omp.h>

static long fib(int n)
{
	long a, b;
	if (n < 2)
		return n;
#pragma omp task shared(a) if (n > 15)
	a = fib(n - 1);
#pragma omp task shared(b) if (n > 15)
	b = fib(n - 2);
#pragma omp taskwait
	return a + b;
}

int main(void)
{
	double s = 0;
	long cnt = 0;
#pragma omp parallel for reduction(+ : s, cnt) schedule(dynamic, 64)
	for (int i = 1; i <= 1000000; i++) {
		s += 1.0 / ((double)i * i);
		cnt++;
	}
	long f;
#pragma omp parallel
#pragma omp single
	f = fib(25);
	printf("omp %.12f %ld fib %ld threads>1 %d\n", s, cnt, f, omp_get_max_threads() > 1);
	return 0;
}
