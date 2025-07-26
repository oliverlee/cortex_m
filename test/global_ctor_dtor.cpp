#include <cstdio>

// NOLINTBEGIN(cppcoreguidelines-pro-type-vararg)

struct chatty
{
    ~chatty()
    {
        ::printf("~chatty()\n");
    }
    chatty()
    {
        ::printf("chatty()\n");
    }
};

const auto global = chatty{};

auto main() -> int
{
  ::printf("in main\n");
}

// NOLINTEND(cppcoreguidelines-pro-type-vararg)
