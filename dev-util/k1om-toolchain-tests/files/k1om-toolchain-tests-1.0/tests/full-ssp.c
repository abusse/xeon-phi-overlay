/* Default -fstack-protector-strong: canary set up in TLS, overflow aborts. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <sys/wait.h>

__attribute__((noinline)) static void smash(const char *s)
{
	char buf[8];
	strcpy(buf, s);
	printf("not reached %s\n", buf);
}

int main(void)
{
	unsigned long canary;
	int p[2], st;
	char msg[4096];
	ssize_t n, len = 0;

	__asm__ ("mov %%fs:0x28, %0" : "=r" (canary));
	printf("canary %s\n", canary ? "set" : "ZERO");
	fflush(stdout);
	if (pipe(p))
		return 1;
	if (fork() == 0) {
		setenv("LIBC_FATAL_STDERR_", "1", 1);
		dup2(p[1], 2);
		close(p[0]);
		smash(getpid() ? "0123456789abcdefghijklmnopqrstuvwxyz0123456789" : "");
		_exit(0);
	}
	close(p[1]);
	while ((n = read(p[0], msg + len, sizeof msg - 1 - len)) > 0)
		len += n;
	msg[len] = 0;
	wait(&st);
	/* glibc 2.21 walks the smashed stack for a backtrace before abort()
	   and usually dies of SIGSEGV there (Intel's compiler alike).  */
	if (WIFSIGNALED(st) && (WTERMSIG(st) == SIGABRT || WTERMSIG(st) == SIGSEGV))
		printf("child killed\n");
	else
		printf("child NOT KILLED: %s %d\n", WIFSIGNALED(st) ? "signal" : "exit", WIFSIGNALED(st) ? WTERMSIG(st) : WEXITSTATUS(st));
	if (getenv("SSPDUMP"))
		fputs(msg, stdout);
	/* With _FORTIFY_SOURCE (Gentoo's default at -O2) __strcpy_chk
	   catches the overflow before the stack protector does.  */
	printf("message %s\n", strstr(msg, "stack smashing detected")
	       || strstr(msg, "buffer overflow detected") ? "overflow detected" : "MISSING");
	return 0;
}
