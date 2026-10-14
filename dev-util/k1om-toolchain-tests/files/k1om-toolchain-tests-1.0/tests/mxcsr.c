/* __builtin_ia32_{st,ld}mxcsr: the KNC vector unit has an MXCSR. */
#include <stdio.h>

int main(void)
{
	unsigned m = __builtin_ia32_stmxcsr();
	__builtin_ia32_ldmxcsr(m ^ 0x6000);	/* flip the rounding-control bits */
	unsigned m2 = __builtin_ia32_stmxcsr();
	__builtin_ia32_ldmxcsr(m);
	printf("mxcsr %08x %08x %08x\n", m, m2, __builtin_ia32_stmxcsr());
	return 0;
}
