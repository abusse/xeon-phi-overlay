// libstdc++ / EH / threads on k1om, C++14 where the compiler has it.
#include <iostream>
#include <iomanip>
#include <sstream>
#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include <numeric>
#include <memory>
#include <stdexcept>
#include <thread>
#include <mutex>
#include <atomic>
#include <functional>
#include <cmath>

struct Err : std::runtime_error {
	double v;
	Err(double v) : std::runtime_error("err"), v(v) {}
};

__attribute__((noinline)) double thrower(int depth, double x)
{
	std::vector<double> guard(depth + 1, x);
	if (depth == 0)
		throw Err(x * 2);
	return thrower(depth - 1, x + 1) + guard.back();
}

struct Shape {
	virtual ~Shape() {}
	virtual double area() const = 0;
};
struct Circle : Shape {
	double r;
	Circle(double r) : r(r) {}
	double area() const override { return M_PI * r * r; }
};
struct Rect : Shape {
	float w, h;
	Rect(float w, float h) : w(w), h(h) {}
	double area() const override { return w * h; }
};

int main()
{
	std::cout << std::setprecision(17);

	try {
		thrower(5, 1.25);
	} catch (const Err &e) {
		std::cout << "caught " << e.what() << " " << e.v << "\n";
	}
	try {
		std::vector<int> v(3);
		v.at(10) = 1;
	} catch (const std::out_of_range &) {
		std::cout << "out_of_range ok\n";
	}

	std::vector<std::unique_ptr<Shape>> shapes;
	for (int i = 1; i <= 5; i++) {
		shapes.push_back(std::make_unique<Circle>(i * 0.5));
		shapes.push_back(std::make_unique<Rect>(i, i + 0.25f));
	}
	double total = std::accumulate(shapes.begin(), shapes.end(), 0.0,
				       [](double s, const auto &p) { return s + p->area(); });
	std::cout << "areas " << total << "\n";

	std::map<std::string, double> m;
	for (int i = 0; i < 20; i++)
		m["k" + std::to_string(i % 7)] += std::sqrt(i);
	std::ostringstream os;
	for (auto &kv : m)
		os << kv.first << "=" << std::fixed << std::setprecision(4) << kv.second << ";";
	std::cout << "map " << os.str() << "\n";

	std::vector<double> d(1000);
	std::iota(d.begin(), d.end(), -500.5);
	std::sort(d.begin(), d.end(), [](double a, double b) { return std::fabs(a) < std::fabs(b); });
	std::cout << "sort " << d.front() << " " << d[1] << " " << d.back() << "\n";

	std::string s = "The quick brown fox";
	std::transform(s.begin(), s.end(), s.begin(), ::toupper);
	std::cout << "str " << s << " " << s.find("FOX") << "\n";

	std::atomic<long> acc{0};
	std::mutex mu;
	double fsum = 0;
	std::vector<std::thread> th;
	for (int t = 0; t < 8; t++)
		th.emplace_back([&, t] {
			double local = 0;
			for (int i = 0; i < 10000; i++) {
				acc.fetch_add(i, std::memory_order_relaxed);
				local += 1.0 / (1 + i + t);
			}
			std::lock_guard<std::mutex> g(mu);
			fsum += local;
		});
	for (auto &x : th)
		x.join();
	std::cout << "threads " << acc.load() << " " << std::setprecision(6) << fsum << "\n";

	std::function<double(double)> f = [](double x) { return x * x - 2; };
	double lo = 0, hi = 2;
	for (int i = 0; i < 60; i++) {
		double mid = (lo + hi) / 2;
		(f(mid) > 0 ? hi : lo) = mid;
	}
	std::cout << std::setprecision(15) << "bisect " << lo << "\n";
	std::cout << "stod " << std::stod("2.5e-3") * 4 << " " << std::stof("1.5") << "\n";
	return 0;
}
