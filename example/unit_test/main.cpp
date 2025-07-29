#if defined(NDEBUG)
#undef NDEBUG
#include <cassert>
#define NDEBUG
#else
#include <cassert>
#endif

auto main() -> int
{
  const auto x = 42;
  assert(42 == x);
}
