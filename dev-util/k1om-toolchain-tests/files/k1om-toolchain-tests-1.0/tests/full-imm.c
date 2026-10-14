/* <immintrin.h>/<x86intrin.h> compile for KNC, and code after them has no cmov. */
#include <stdio.h>
#include <immintrin.h>
#include <x86intrin.h>

__attribute__((noinline)) static long pick(long a, long b, int c)
{
	return c ? a : b;
}

int main(int argc, char **argv)
{
	(void)argv;
	printf("imm ok %ld\n", pick(7, 9, argc));
	return 0;
}
