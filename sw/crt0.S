/* =============================================================================
 * Startup Code (crt0.S) for RISC-V VeeR EL2 Core
 * Initializes MRAC CSR (0x7C0), Stack Pointer, clears BSS, and jumps to main().
 * ============================================================================= */

    .section .text.init
    .global _start
    .type _start, @function

_start:
    /* 1. Disable global interrupts during bring-up */
    csrci   mstatus, 8

    /* 2. Configure VeeR EL2 MRAC CSR (0x7C0)
     * Region 1 (0x1000_0000..0x1FFF_FFFF) = Cacheable/Idempotent Memory (0x2)
     * Region 4 (0x4000_0000..0x4FFF_FFFF) = Non-Cacheable Device I/O (0x6)
     * Value: 0xAAAAAAA6 */
    lui     t0, 0xaaaab
    addi    t0, t0, -1370
    csrw    0x7c0, t0

    /* 3. Initialize Stack Pointer (sp) to top of on-chip DMEM (0x1002_0000 + 64KB) */
    lui     sp, 0x10030
    addi    sp, sp, -16

    /* 4. Initialize Global Pointer (gp) */
.option push
.option norelax
    la      gp, __global_pointer$
.option pop

    /* 5. Clear BSS Section */
    la      t0, _sbss
    la      t1, _ebss
bss_loop:
    bgeu    t0, t1, bss_done
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       bss_loop
bss_done:

    /* 6. Copy initialized .data section from IMEM (LMA) to DMEM (VMA) if distinct */
    la      t0, _sdata
    la      t1, _edata
    la      t2, _sidata
    beq     t0, t2, data_done
data_loop:
    bgeu    t0, t1, data_done
    lw      t3, 0(t2)
    sw      t3, 0(t0)
    addi    t0, t0, 4
    addi    t2, t2, 4
    j       data_loop
data_done:

    /* 7. Enter C main() */
    call    main

    /* 8. Halt / infinite idle loop if main returns */
halt:
    wfi
    j       halt

    .size _start, . - _start
