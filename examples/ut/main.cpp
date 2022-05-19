#include <boost/ut.hpp>
#include "test/cfg.hpp"

namespace ut = boost::ut;

template <>
auto ut::cfg<ut::override> = stm32::test::cfg::runner{};

int main() {
 using namespace ut;

  "equal"_test = [] {
    expect(1_i == 1);
    expect(1_i == 2);
  };

  return ut::cfg<>.run();
}
