/* Linker script to configure memory regions.
 * This is specific to the LM3S6965EVB board.
 *   FLASH.ORIGIN: starting address of flash
 *   FLASH.LENGTH: length of flash
 *   RAM.ORIGIN: starting address of RAM bank 0
 *   RAM.LENGTH: length of RAM bank 0
 *
 * In the associated linker script, `.text` and `.rodata` sections of the
 * program will be placed in the `FLASH` region, whereas the `.bss` and `.data`
 * sections, as well as the heap, will be placed in the `RAM` region.
 */

/* clang-format off */
MEMORY
{
  FLASH : ORIGIN = 0x00000000, LENGTH = 256K
  RAM   : ORIGIN = 0x20000000, LENGTH = 64K
}
/* clang-format on */
