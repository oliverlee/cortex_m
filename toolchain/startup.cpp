#include <tuple>

extern "C" {

extern int main();

[[noreturn]] void _start()
{
    std::ignore = main();

    while (true) {}
}

[[noreturn]] void _exit(int) { while (true) {} }
[[noreturn]] void _kill(int, int) { while (true) {} }
[[noreturn]] void _getpid(void) { while (true) {} }

}
