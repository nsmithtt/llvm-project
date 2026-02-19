OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 64K     /* Program memory */
    DATA (rw)   : ORIGIN = 0x00010000, LENGTH = 128K    /* Program data */
    STACK  (rw) : ORIGIN = 0xFFB00000, LENGTH = 4K      /* STACK for stack/data */
}

SECTIONS {
    /* Text and read-only data in FLASH */
    .text : {
        *(.text*)
        *(.rodata*)
    } > FLASH

    /* Data section in SRAM, loaded from FLASH if needed */
    .data : {
        *(.data*)
    } > DATA

    .bss (NOLOAD) : {
        *(.bss*)
        *(COMMON)
    } > DATA

    /* Top of stack */
    stack_top = ORIGIN(STACK) + LENGTH(STACK);
}
