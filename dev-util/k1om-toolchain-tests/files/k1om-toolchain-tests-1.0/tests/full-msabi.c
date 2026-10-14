/* ms_abi functions on KNC: the prologue saves xmm6-15 (masked vpackstore)
   and the epilogue restores them; the low 128 bits of zmm6 must survive a
   call to an ms_abi function whose callee wipes zmm6.  */
#include <stdio.h>

__attribute__((noinline)) static void wipe(void)
{
	__asm__ volatile ("vpxord %%zmm6, %%zmm6, %%zmm6" ::: "xmm6");
}

__attribute__((ms_abi, noinline)) static void inner(void)
{
	wipe();
}

__attribute__((noinline)) static double sv(double x, int i) { return x * 2 + i; }

__attribute__((ms_abi, noinline)) static double ms(double a, int i, double b, float c)
{
	return sv(a, i) + b + c;
}

int main(void)
{
	static int in[16] __attribute__((aligned(64))) = { 1, 2, 3, 4, 5, 6, 7, 8 };
	static int out[16] __attribute__((aligned(64)));

	__asm__ volatile ("vmovdqa32 %0, %%zmm6" : : "m" (in) : "xmm6");
	inner();
	__asm__ volatile ("vmovdqa32 %%zmm6, %0" : "=m" (out));
	printf("%d %d %d %d %g\n", out[0], out[1], out[2], out[3], ms(1.5, 3, 2.0, 0.25f));
	return 0;
}
