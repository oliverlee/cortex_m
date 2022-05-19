#include "arm/semihosting.hpp"

extern "C" {

extern int main();

void start() {
    arm::semihosting::init();
    arm::semihosting::exit(main());
}

}

