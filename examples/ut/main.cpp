#include <cstdio>
#include <boost/ut.hpp>

namespace ut = boost::ut;

namespace cfg {
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
}  // namespace cfg

template <>
auto ut::cfg<ut::override> = cfg::runner{};

int main() {
 using namespace ut;

  "equal"_test = [] {
    expect(1_i == 1);
    expect(1_i == 2);
  };

  return ut::cfg<>.run();
}
