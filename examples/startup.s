.global _start
_start:
    ldr sp,=0x11000
    bl main
    b .
