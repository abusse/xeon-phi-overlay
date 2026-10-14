/* Misaligned __float128 (packed struct members at every offset): Intel
   MPSS 5.1.1 loads them with vbroadcasti32x4, which needs 16-byte
   alignment -> #GP.  Also __int128 for comparison.  */
#include <stdio.h>
#include <string.h>

struct __attribute__((packed)) pkq {
	char c;
	double d;
	char c2;
	__float128 q;
	__int128 i;
};

#define NI __attribute__((noinline, noclone))

NI void upd(struct pkq *p, double d) { p->q += d; p->i += (__int128)d; }
NI __float128 get(const struct pkq *p) { return p->q; }
NI void put(struct pkq *p, __float128 v) { p->q = v; }
NI __float128 sum(__float128 a, __float128 b) { return a + b; }

int main(void)
{
	static char buf[128] __attribute__((aligned(64)));
	int bad = 0;
	for (int off = 0; off < 16; off++) {
		struct pkq *p = (struct pkq *)(buf + off);
		memset(buf, 0, sizeof buf);
		put(p, 4);
		p->i = 1000;
		upd(p, 2.5);
		__float128 v = sum(get(p), p->q);
		struct pkq copy = *p;
		copy.q *= 2;
		printf("pkq +%-2d %.17g %.17g %ld\n", off, (double)v, (double)copy.q, (long)p->i);
		if ((double)v != 13.0 || (double)copy.q != 13.0 || p->i != 1002)
			bad++;
	}
	printf("pkq bad %d\n", bad);
	return bad != 0;
}
