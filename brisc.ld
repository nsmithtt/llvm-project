OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 64K     /* Program memory */
    DATA  (rw) : ORIGIN = 0xFFB00000, LENGTH = 4K      /* STACK for stack/data */
}

SECTIONS {
    /* Text and read-only data in FLASH */
    .text : {
        *(.text*)
        *(.rodata*)
    } > FLASH

    /* Data section in SRAM, loaded from FLASH if needed */
    .data : AT(ADDR(.text) + SIZEOF(.text)) {
        __data_start = .;
        *(.data*)
        __data_end = .;
    } > DATA

    __data_source = LOADADDR(.data);
    __data_size   = SIZEOF(.data);

    .bss (NOLOAD) : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    } > DATA

    __bss_size   = SIZEOF(.bss);

    /* Top of stack */
    __stack = ORIGIN(DATA) + LENGTH(DATA);
}
