#include <tuple>

auto main() -> int
{
  const auto x = 0;
  const auto y = 3;

  for (;;) {
    volatile auto z = x + y;
    std::ignore = z;
  }
}
