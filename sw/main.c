#include "uart.h"

int main(void) {
    // Initialize UART 16550
    // Baud divisor = 16 for simulation testing
    // (For 100 MHz clock and 115200 baud in hardware: divisor = 100_000_000 / (16 * 115200) = 54)
    uart_init(16);

    // Print banner and Hello World message
    uart_puts("\n======================================================\n");
    uart_puts("  Hello, World from RISC-V VeeR EL2 SoC!\n");
    uart_puts("  16550-Compatible AXI UART Output Working.\n");
    uart_puts("======================================================\n\n");

    // Finished
    while (1) {
        __asm__ volatile ("nop");
    }

    return 0;
}
