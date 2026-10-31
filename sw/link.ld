/* =============================================================================
 * Linker Script (link.ld) for RISC-V SoC
 * IMEM: 64 KB at 0x1000_0000 (Instruction RAM)
 * DMEM: 64 KB at 0x1002_0000 (Data RAM)
 * ============================================================================= */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    IMEM (rx)  : ORIGIN = 0x10000000, LENGTH = 64K
    DMEM (rwx) : ORIGIN = 0x10020000, LENGTH = 64K
}

SECTIONS
{
    .text :
    {
        . = ALIGN(4);
        *(.text.init)
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
        *(.srodata)
        *(.srodata.*)
        . = ALIGN(4);
        _etext = .;
    } > IMEM

    _sidata = LOADADDR(.data);

    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        __global_pointer$ = . + 0x800;
        *(.sdata)
        *(.sdata.*)
        *(.data)
        *(.data.*)
        . = ALIGN(4);
        _edata = .;
    } > DMEM AT > IMEM

    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        _sbss = .;
        *(.sbss)
        *(.sbss.*)
        *(.bss)
        *(.bss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > DMEM

    .stack (NOLOAD) :
    {
        . = ALIGN(16);
        _stack_bottom = .;
        . = . + 0x2000; /* 8 KB stack */
        _stack_top = .;
        _sp = .;
    } > DMEM

    /* Discard unused metadata sections */
    /DISCARD/ :
    {
        *(.comment)
        *(.note*)
        *(.eh_frame*)
    }
}
