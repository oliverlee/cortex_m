// startup for Cortex-m3
//
// Designed to be used with the `cortex-m3.ld` linker script.
//
// This file is heavily based on the example startup file from
// rust-embedded/cortex-m
// https://github.com/rust-embedded/cortex-m/blob/6d566b220b9fe1c8e67f7a6808bf105e3f01dc03/cortex-m-rt/src/lib.rs
//
// No support for:
// - Dynamic memory allocation (no heap)
// - C++ exceptions (no unwinding tables)

#include <algorithm>
#include <array>
#include <cstdint>
#include <ranges>
#include <tuple>

// NOLINTBEGIN(bugprone-reserved-identifier,cppcoreguidelines-pro-bounds-array-to-pointer-decay)

static constexpr auto __dso_handle = static_cast<void*>(nullptr);

namespace {
using init_fini_function_type = auto (*)() -> void;
}

// NOLINTBEGIN(modernize-avoid-c-arrays)
extern const std::uint8_t _stack_start[];
extern const std::uint8_t _sidata[];

// NOLINTBEGIN(cppcoreguidelines-avoid-non-const-global-variables)
extern std::uint8_t _sdata[], _edata[];
extern std::uint8_t _sbss[], _ebss[];
// NOLINTEND(cppcoreguidelines-avoid-non-const-global-variables)

extern const init_fini_function_type __preinit_array_start[];
extern const init_fini_function_type __preinit_array_end[];
extern const init_fini_function_type __init_array_start[];
extern const init_fini_function_type __init_array_end[];
extern const init_fini_function_type __fini_array_start[];
extern const init_fini_function_type __fini_array_end[];
// NOLINTEND(modernize-avoid-c-arrays)

extern "C" {
auto main() -> int;
[[gnu::weak]]
auto system_init() -> void;
[[gnu::weak]]
auto __pre_init() -> void;
[[gnu::weak]]
auto initialise_monitor_handles() -> void;
}

namespace {

auto init_data() -> void
{
  std::copy(_sidata, _sidata + (_edata - _sdata), _sdata);
}

auto init_bss() -> void
{
  std::fill(_sbss, _ebss, std::uint8_t{});
}

auto constructors() -> void
{
  using std::ranges::subrange;

  for (auto ctor : subrange{__preinit_array_start, __preinit_array_end}) {
    ctor();
  }

  for (auto ctor : subrange{__init_array_start, __init_array_end}) {
    ctor();
  }
}

auto destructors() -> void
{
  using std::ranges::subrange;
  using std::views::reverse;

  for (auto dtor : subrange{__fini_array_start, __fini_array_end} | reverse) {
    dtor();
  }
}

auto halt() -> void
{
  while (true) {
    asm("bkpt #0");
  }
}

[[noreturn]]
auto _exit(int ec) -> void
{
  destructors();

  if (initialise_monitor_handles) {
    // https://github.com/ARM-software/abi-aa/blob/main/semihosting/semihosting.rst#sys-exit-extended-0x20
    static constexpr auto SYS_EXIT_EXTENDED = std::int32_t{0x20U};
    static constexpr auto ADP_Stopped_ApplicationExit = std::int32_t{0x20026};

    // NOLINTNEXTLINE(modernize-avoid-c-arrays)
    const std::int32_t argblock[2] = {
        ADP_Stopped_ApplicationExit,  //
        static_cast<std::int32_t>(ec)
    };

    // https://gcc.gnu.org/onlinedocs/gcc/Local-Register-Variables.html
    register auto r0 asm("r0") = SYS_EXIT_EXTENDED;
    register auto r1 asm("r1") = static_cast<const void*>(argblock);

    // https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html
    asm volatile(
        "bkpt #0xAB"
        :                   // no outputs
        : "r"(r0), "r"(r1)  // inputs in r0 and r1
        : "memory"          // may read from argblock
    );
  } else {
    std::ignore = ec;
    halt();
  }

  __builtin_unreachable();
}

template <std::size_t N, auto value>
constexpr auto repeat = [] {
  std::array<decltype(value), N> arr{};
  arr.fill(value);
  return arr;
}();

using vector_table_entry_t = auto (*)() -> void;

struct vector_table_t
{
  const void* initial_stack_pointer;              // Initial stack pointer value
  vector_table_entry_t reset;                     // Reset handler
  vector_table_entry_t nmi;                       // NMI handler
  vector_table_entry_t hard_fault;                // Hard fault handler
  vector_table_entry_t memory_management;         // Memory management fault
  vector_table_entry_t bus_fault;                 // Bus fault
  vector_table_entry_t usage_fault;               // Usage fault
  std::array<vector_table_entry_t, 4> reserved1;  // Reserved entries
  vector_table_entry_t svc;                       // Supervisor call
  vector_table_entry_t debug_monitor;             // Debug monitor
  vector_table_entry_t reserved2;                 // Reserved
  vector_table_entry_t pendsv;                    // Pendable service call
  vector_table_entry_t systick;                   // System tick timer
  std::array<vector_table_entry_t, 240> irq;      // External interrupts
};

}  // namespace

extern "C" [[noreturn]]
auto _start() -> void
{
  if (__pre_init) {
    __pre_init();
  }

  init_data();
  init_bss();

  if (initialise_monitor_handles) {
    initialise_monitor_handles();
  }

  constructors();

  if (system_init) {
    system_init();
  }

  const auto result = main();
  _exit(result);
}

struct exception_frame
{
  std::uint32_t r0;   // General purpose register 0
  std::uint32_t r1;   // General purpose register 1
  std::uint32_t r2;   // General purpose register 2
  std::uint32_t r3;   // General purpose register 3
  std::uint32_t r12;  // General purpose register 12
  std::uint32_t lr;   // Link Register
  std::uint32_t pc;   // Program Counter
  std::uint32_t psr;  // Program Status Register
};

extern "C" {
auto reset_handler() -> void;

// Non-maskable interrupt - critical system error
// Should handle immediately, cannot be disabled
[[gnu::weak]]
auto nmi_handler() -> void
{
  halt();  // Typically fatal
}

auto hardfault_trampoline() -> void;
auto _hardfault_handler(exception_frame* frame) -> void
{
  std::ignore = frame;
  halt();
}

// Memory Protection Unit violations
[[gnu::weak]]
auto memory_management_handler() -> void
{
  halt();
}

// Bus errors (external memory access failures)
[[gnu::weak]]
auto bus_fault_handler() -> void
{
  halt();
}

// Undefined instructions, unaligned access, divide by zero
[[gnu::weak]]
auto usage_fault_handler() -> void
{
  halt();
}

// System call request - could implement system services here
// Triggered by SVC instruction from user code
[[gnu::weak]]
auto svcall_handler() -> void
{
  halt();
}

// Debug breakpoints when not using halt mode
[[gnu::weak]]
auto debug_monitor_handler() -> void
{
  halt();
}

// Context switching request - typically used by RTOS
// Lowest priority so it runs after all other interrupts
[[gnu::weak]]
auto pendsv_handler() -> void
{
  halt();
}

// System timer tick - could update system time, task scheduler, etc.
[[gnu::weak]]
auto systick_handler() -> void
{
  halt();
}

// Default IRQ handler for unhandled external interrupts
[[gnu::weak]]
auto default_handler() -> void
{
  halt();
}
}

[[gnu::section(".vector_table"), gnu::used]]
const auto vector_table = vector_table_t{
    .initial_stack_pointer = _stack_start,
    .reset = reset_handler,
    .nmi = nmi_handler,
    .hard_fault = hardfault_trampoline,
    .memory_management = memory_management_handler,
    .bus_fault = bus_fault_handler,
    .usage_fault = usage_fault_handler,
    .reserved1 = {},
    .svc = svcall_handler,
    .debug_monitor = debug_monitor_handler,
    .reserved2 = {},
    .pendsv = pendsv_handler,
    .systick = systick_handler,
    .irq = repeat<240, default_handler>
};

asm(R"(
.section .Reset, "ax"
.global reset_handler
.type reset_handler, %function
.thumb_func
reset_handler:
    ldr r0, =_stack_start
    mov sp, r0
    bl _start
1:  bkpt #0
    b 1b
.size reset_handler, . - reset_handler
)");

asm(R"(
.section .HardFaultTrampoline, "ax"
.global hardfault_trampoline
.type hardfault_trampoline, %function
.thumb_func
hardfault_trampoline:
    mov r0, lr
    ldr r1, =0xFFFFFFFD
    cmp r0, r1
    bne 1f
    mrs r0, psp
    b 2f
1:  mrs r0, msp
2:  bl _hardfault_handler
3:  bkpt #0
    b 3b
.size hardfault_trampoline, . - hardfault_trampoline
)");

// NOLINTEND(bugprone-reserved-identifier,cppcoreguidelines-pro-bounds-array-to-pointer-decay)
