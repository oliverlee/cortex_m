#include "arm/semihosting.hpp"
#include <cstdio>

extern "C" {

extern int main();

void start() {
    arm::semihosting::init();
    arm::semihosting::exit(main());
}

}

