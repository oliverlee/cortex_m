/*
 * Linker Script for Cortex-M3
 *
 * This script is heavily based on the example linker script from
 * rust-embedded/cortex-m
 * https://github.com/rust-embedded/cortex-m/blob/6d566b220b9fe1c8e67f7a6808bf105e3f01dc03/cortex-m-rt/link.x.in
 *
 * No support for:
 * - Dynamic memory allocation (no heap)
 * - C++ exceptions (no unwinding tables)
 */

/*
 * Provides information about the memory layout of the device
 * This will be provided by the user for a specific board
 */
INCLUDE memory.ld

ASSERT(ORIGIN(FLASH) % 4 == 0, "ERROR: FLASH origin must be 4-byte aligned");
ASSERT(ORIGIN(RAM) % 4 == 0, "ERROR: RAM origin must be 4-byte aligned");

ENTRY(reset_handler)

_stack_size = 0x1000;
ASSERT(_stack_size >= 256, "ERROR: Stack size too small");

/* stack pointer at top of RAM */
_stack_start = ORIGIN(RAM) + LENGTH(RAM);
ASSERT(_stack_start % 8 == 0, "ERROR: Stack must be 8-byte aligned for ARM EABI");

/* vector table constants for Cortex-M3 */
_vector_table_entries = 256;  /* 1 SP + 15 system + 240 IRQ */
_pointer_size = 4;  /* 32-bit architecture */
_vector_table_size = _vector_table_entries * _pointer_size;

PHDRS
{
  rx PT_LOAD FLAGS(5);  /* read + execute */
  rw PT_LOAD FLAGS(6);  /* read + write */
}

SECTIONS
{
    /* vector table must be at address 0x0 (start of FLASH) */
    .vector_table :
    {
        . = ALIGN(4);
        KEEP(*(.vector_table))
    } > FLASH :rx

    .Reset :
    {
        *(.Reset)
    } > FLASH :rx

    .HardFaultTrampoline :
    {
        *(.HardFaultTrampoline)
    } > FLASH :rx

    .text :
    {
        . = ALIGN(4);
        *(.text)
        *(.text*)
        . = ALIGN(4);
    } > FLASH :rx

    /* Read-only data */
    .rodata :
    {
        . = ALIGN(4);
        *(.rodata)
        *(.rodata*)
        . = ALIGN(4);
    } > FLASH :rx

    /* C++ constructors/destructors */
    .preinit_array :
    {
        . = ALIGN(4);
        PROVIDE_HIDDEN(__preinit_array_start = .);
        KEEP(*(.preinit_array*))
        PROVIDE_HIDDEN(__preinit_array_end = .);
    } > FLASH :rx

    .init_array :
    {
        . = ALIGN(4);
        PROVIDE_HIDDEN(__init_array_start = .);
        KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*)))
        KEEP(*(.init_array*))
        PROVIDE_HIDDEN(__init_array_end = .);
    } > FLASH :rx

    .fini_array :
    {
        . = ALIGN(4);
        PROVIDE_HIDDEN(__fini_array_start = .);
        KEEP(*(SORT_BY_INIT_PRIORITY(.fini_array.*)))
        KEEP(*(.fini_array*))
        PROVIDE_HIDDEN(__fini_array_end = .);
    } > FLASH :rx

    /* end of text/rodata in FLASH */
    . = ALIGN(4);
    _etext = .;

    /* initialized data - copied from FLASH to RAM by startup code */
    .data : AT(_etext)
    {
        . = ALIGN(4);
        _sdata = .;
        *(.data)
        *(.data*)
        . = ALIGN(4);
        _edata = .;
    } > RAM :rw

    /* load address of .data in FLASH */
    _sidata = LOADADDR(.data);

    /* uninitialized data - zeroed by startup code */
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > RAM :rw

    /* Stack grows down from top of RAM */
    .stack (NOLOAD) :
    {
        . = ALIGN(8);
        . = . + _stack_size;
        . = ALIGN(8);
    } > RAM :rw
}


ASSERT(_etext <= ORIGIN(FLASH) + LENGTH(FLASH),
       "ERROR: FLASH overflow");
ASSERT(_ebss + _stack_size <= _stack_start,
       "ERROR: RAM overflow - reduce stack size or global variables");

/* symbols for debugging */
PROVIDE(__stack_size = _stack_size);
PROVIDE(__ram_used = _ebss - ORIGIN(RAM));
PROVIDE(__ram_free = _stack_start - _ebss - _stack_size);
PROVIDE(__flash_used = _etext - ORIGIN(FLASH));
PROVIDE(__flash_free = ORIGIN(FLASH) + LENGTH(FLASH) - _etext);
