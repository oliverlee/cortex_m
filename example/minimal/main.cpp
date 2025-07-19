#include <tuple>

auto main() -> int
{
  auto x = 0;
  auto y = 3;

  for (;;) {
    auto z = x + y;
    std::ignore = z;
  }
}
