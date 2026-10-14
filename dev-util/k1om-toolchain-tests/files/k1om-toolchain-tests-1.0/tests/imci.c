/* IMCI through inline asm (GCC has no KNC intrinsics): swizzled FMA,
   masked ops, gather, vpackstore, k-register logic, with compiler
   generated FP code around it.  */
#include <stdio.h>
#include <stdint.h>

typedef float v16sf __attribute__((vector_size(64), aligned(64)));

static float a[16] __attribute__((aligned(64)));
static float b[16] __attribute__((aligned(64)));
static float out[16] __attribute__((aligned(64)));
static int idx[16] __attribute__((aligned(64)));
static float tbl[64] __attribute__((aligned(64)));

int main(void)
{
	for (int i = 0; i < 16; i++) {
		a[i] = i * 0.5f;
		b[i] = 16 - i;
		idx[i] = (i * 7) & 63;
	}
	for (int i = 0; i < 64; i++)
		tbl[i] = i * i;

	/* out = a * b + a, then masked add of 100 on even lanes (k1=0x5555) */
	unsigned mask = 0x5555, kout;
	__asm__ volatile(
		"vmovaps %[a], %%zmm0\n\t"
		"vmovaps %[b], %%zmm1\n\t"
		"vmovaps %%zmm0, %%zmm2\n\t"
		"vfmadd213ps %%zmm0, %%zmm1, %%zmm2\n\t"
		"kmov %[m], %%k1\n\t"
		"vaddps %[h]%{1to16%}, %%zmm2, %%zmm2%{%%k1%}\n\t"
		"vcmpltps %%zmm1, %%zmm0, %%k2\n\t"
		"kand %%k1, %%k2\n\t"
		"kmov %%k2, %[ko]\n\t"
		"vmovaps %%zmm2, %[o]\n\t"
		: [o] "=m"(out), [ko] "=r"(kout)
		: [a] "m"(a), [b] "m"(b), [m] "r"(mask), [h] "m"((float){100.0f})
		: "zmm0", "zmm1", "zmm2", "k1", "k2");
	double s = 0;
	for (int i = 0; i < 16; i++)
		s += out[i];
	printf("imci fma %.9g k %x\n", s, kout);

	/* gather tbl[idx] */
	__asm__ volatile(
		"vmovaps %[i], %%zmm3\n\t"
		"kxnor %%k1, %%k1\n"
		"1:\n\t"
		"vgatherdps (%[t],%%zmm3,4), %%zmm4%{%%k1%}\n\t"
		"kortest %%k1, %%k1\n\t"
		"jnz 1b\n\t"
		"vpackstorelps %%zmm4, %[o]\n\t"
		"vpackstorehps %%zmm4, 64+%[o]\n\t"
		: [o] "=m"(out)
		: [i] "m"(idx), [t] "r"(tbl)
		: "zmm3", "zmm4", "k1", "memory");
	s = 0;
	for (int i = 0; i < 16; i++)
		s += out[i] * (i + 1);
	printf("imci gather %.9g\n", s);
	return 0;
}
