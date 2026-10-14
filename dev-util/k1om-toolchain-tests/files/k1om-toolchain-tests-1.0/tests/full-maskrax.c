/* k1om gcc 16.2 -O2: segfaults. Building a float pair in a zmm register emits
   "movl $1, %eax; kmov %eax, %k2" without a clobber of %rax, while %rax still holds the
   pointer loaded by "movq (%rdi), %rax":
	movq	(%rdi), %rax
	vpbroadcastd	4(%rax), %zmm0
	movl	$1, %eax
	kmov	%eax, %k2
	vpbroadcastd	(%rax), %zmm0{%k2}	<- (%rax) == 1 -> #GP/SIGSEGV */
#include <stdio.h>
struct s2 { float f, g; };
__attribute__((noinline)) struct s2 load2(struct s2 **pp) { return **pp; }
int main(void)
{
	struct s2 v = { 1.5f, 2.5f }, *p = &v;
	struct s2 r = load2(&p);
	printf("%g %g\n", r.f, r.g);
	return !(r.f == 1.5f && r.g == 2.5f);
}
