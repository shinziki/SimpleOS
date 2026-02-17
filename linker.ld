OUTPUT_FORMAT(binary)       /* Output raw binary, not ELF */
ENTRY(_start)               /* Entry point is _start from kernel_entry.asm */

SECTIONS
{
    /* Kernel starts at 0x10000 (64KB mark) */
    . = 0x10000;

    .text : {
        *(.text)           /* All code sections */
    }

    .rodata : {
        *(.rodata)         /* Read-only data (strings, etc.) */
    }

    .data : {
        *(.data)           /* Initialized data */
    }

    .bss : {
        *(COMMON)
        *(.bss)            /* Uninitialized data */
    }
}