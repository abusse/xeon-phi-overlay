/* Exercise the kernel exception-table fixup: user pointers that must EFAULT. */
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/utsname.h>

int main(void)
{
	int fd = open("/proc/self/status", O_RDONLY), bad = 0;
	long r;
	struct utsname u;

	r = read(fd, (void *)0x10, 64);
	if (!(r < 0 && errno == EFAULT)) { printf("read: r=%ld errno=%d\n", r, errno); bad++; }
	r = write(fd, (void *)0x10, 64);
	if (!(r < 0 && (errno == EFAULT || errno == EBADF))) { printf("write: r=%ld errno=%d\n", r, errno); bad++; }
	r = uname((struct utsname *)0x10);
	if (!(r < 0 && errno == EFAULT)) { printf("uname: r=%ld errno=%d\n", r, errno); bad++; }
	r = uname(&u);
	if (r) bad++;
	printf("EFAULT test %s (%s)\n", bad ? "FAILED" : "ok", u.release);
	return bad;
}
