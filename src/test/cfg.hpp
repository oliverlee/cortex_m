#pragma once

#include <boost/ut.hpp>
#include <cstdio>
#include <cstdint>

namespace stm32::test::cfg {

namespace ut = boost::ut;

class runner {
  std::uint8_t fails_{};

 public:
  template <class... Ts>
  auto on(ut::events::test<Ts...> test) {
    printf("Running \"%s\"...\n", test.name.data());
    test();
  }

  template <class... Ts>
  auto on(ut::events::skip<Ts...>) { }

  template <class TExpr>
  auto on(ut::events::assertion<TExpr> assertion) -> bool {
    if (static_cast<bool>(assertion.expr)) {
        printf(".\n");
        return true;
    }

    printf("%s:%d %sFAILED%s\n",
           assertion.location.file_name(),
           assertion.location.line(),
           ut::colors{}.fail.data(),
           ut::colors{}.none.data());

    ++fails_;
    return false;
  }

  auto on(ut::events::fatal_assertion) { }

  template <class TMsg>
  auto on(ut::events::log<TMsg>) { }

  [[nodiscard]] auto run() -> bool {
      return fails_ > 0;
  }
};

}  // namespace stm32::test::cfg

