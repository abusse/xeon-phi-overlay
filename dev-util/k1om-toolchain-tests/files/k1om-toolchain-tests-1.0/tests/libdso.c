/* -fPIC code with FP args/returns, TLS and a global, for dso.c. */
double dso_scale = 1.5;
__thread double dso_tls = 0.25;

double dso_fn(double x, float y, int n)
{
	dso_tls += x;
	for (int i = 0; i < n; i++)
		x = x * dso_scale + y;
	return x + dso_tls;
}
