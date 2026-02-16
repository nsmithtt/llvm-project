OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 64K     /* Program memory */
    SRAM  (rw)  : ORIGIN = 0xFFB00000, LENGTH = 4K      /* SRAM for stack/data */
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
    } > SRAM AT > FLASH

    .bss (NOLOAD) : {
        *(.bss*)
        *(COMMON)
    } > SRAM

    /* Top of stack */
    stack_top = ORIGIN(SRAM) + LENGTH(SRAM);
}
