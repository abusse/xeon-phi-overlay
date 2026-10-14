/* Integer codegen on a core without CMOV/CX16/SSE: bit builtins (ffs
   uses cmov elsewhere), __int128, atomics and fences, TLS, threads,
   setjmp, alloca/VLA.  */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <setjmp.h>
#include <pthread.h>
#include <strings.h>

#define NI __attribute__((noinline, noclone))

NI int ffs32(int x) { return __builtin_ffs(x); }
NI int ffs64(long x) { return __builtin_ffsl(x); }
NI int bits(unsigned long x)
{
	return __builtin_popcountl(x) + (x ? __builtin_ctzl(x) * 100 + __builtin_clzl(x) * 10000 : 0);
}
NI long smax(long a, long b) { return a > b ? a : b; }
NI unsigned umin(unsigned a, unsigned b) { return a < b ? a : b; }
NI long sabs(long a) { return a < 0 ? -a : a; }

NI unsigned __int128 mul128(unsigned __int128 a, unsigned __int128 b) { return a * b; }
NI __int128 div128(__int128 a, __int128 b) { return a / b; }

static long counter;
static __thread int tls_val = 7;
static int shared_add;

static void *worker(void *arg)
{
	long id = (long)arg;
	tls_val += (int)id;
	for (int i = 0; i < 100000; i++) {
		__atomic_fetch_add(&counter, 1, __ATOMIC_SEQ_CST);
		__sync_fetch_and_add(&shared_add, 2);
	}
	long exp = __atomic_load_n(&counter, __ATOMIC_ACQUIRE);
	while (!__atomic_compare_exchange_n(&counter, &exp, exp + 1000, 0,
					    __ATOMIC_SEQ_CST, __ATOMIC_RELAXED))
		;
	__atomic_thread_fence(__ATOMIC_SEQ_CST);
	return (void *)(long)tls_val;
}

static jmp_buf jb;
NI void jumper(int n) { if (n > 3) longjmp(jb, n); jumper(n + 1); }

NI long vla(int n)
{
	long a[n];
	char *b = __builtin_alloca(n * 3);
	for (int i = 0; i < n; i++)
		a[i] = i * i;
	memset(b, 1, n * 3);
	long s = 0;
	for (int i = 0; i < n; i++)
		s += a[i] + b[i * 3];
	return s;
}

int main(void)
{
	int v32[] = { 0, 1, 6, 0x80000000, -1, 0x100 };
	for (int i = 0; i < 6; i++)
		printf("%d ", ffs32(v32[i]));
	printf("| %d %d %d | %d %d\n", ffs64(0), ffs64(1L << 40), ffs64(-1L), ffs(0x30), ffsll(1LL << 50));
	printf("bits %d %d %d\n", bits(0), bits(1), bits(0xf0f0f0f000UL));
	printf("sel %ld %u %ld %ld\n", smax(-5, 3), umin(7, 0xffffffffu), sabs(-42), sabs(9));

	unsigned __int128 m = mul128((unsigned __int128)0xfedcba9876543210UL << 8, 0x123456789UL);
	printf("i128 %016lx%016lx\n", (unsigned long)(m >> 64), (unsigned long)m);
	__int128 d = div128(-((__int128)1 << 100), 12345);
	printf("div128 %ld %lx\n", (long)(d >> 64), (unsigned long)d);

	pthread_t t[8];
	long rs = 0;
	for (long i = 0; i < 8; i++)
		pthread_create(&t[i], NULL, worker, (void *)i);
	for (int i = 0; i < 8; i++) {
		void *r;
		pthread_join(t[i], &r);
		rs += (long)r;
	}
	printf("atomics %ld %d tls %ld main-tls %d\n", counter, shared_add, rs, tls_val);

	int j = setjmp(jb);
	if (!j)
		jumper(0);
	printf("longjmp %d\n", j);
	printf("vla %ld\n", vla(37));
	return 0;
}
