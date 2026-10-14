/* libitm: transactions from several threads keep an invariant. */
#include <stdio.h>
#include <pthread.h>

static long a, b, bad;

static void *worker(void *arg)
{
	(void)arg;
	for (int i = 0; i < 200000; i++) {
		__transaction_atomic {
			a++;
			b--;
		}
		__transaction_atomic {
			if (a + b != 0)
				bad++;
		}
	}
	return 0;
}

int main(void)
{
	pthread_t t[8];
	for (int i = 0; i < 8; i++)
		pthread_create(&t[i], 0, worker, 0);
	for (int i = 0; i < 8; i++)
		pthread_join(t[i], 0);
	printf("a=%ld b=%ld bad=%ld\n", a, b, bad);
	return 0;
}
