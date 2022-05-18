#include <cstdio>

#include "arm/semihosting.hpp"

int main() {
    arm::semihosting::init();

    printf("hello world!\n");

    //return 0;

    arm::semihosting::exit(0);
}
