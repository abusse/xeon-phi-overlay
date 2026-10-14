/* 16-byte copies through __int128 from and to misaligned addresses: KNC
   can move a vector register only at aligned addresses, so these must
   go through general registers.  */
#include <stdio.h>
#include <string.h>

static unsigned char buf[48];

__attribute__((noinline)) static void cp(unsigned char *d, const unsigned char *s)
{
	__int128 t;
	memcpy(&t, s, 16);
	memcpy(d, &t, 16);
}

int main(void)
{
	unsigned char out[16] __attribute__((aligned(16)));
	unsigned int h = 0;
	for (int i = 0; i < 48; i++)
		buf[i] = i;
	cp(out, buf + 3);
	cp(buf + 21, out);
	for (int i = 0; i < 48; i++)
		h = h * 31 + buf[i];
	printf("%u %d %d\n", h, out[0], out[15]);
	return 0;
}
