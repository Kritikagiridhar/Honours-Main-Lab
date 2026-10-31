#include "uart.h"

void uart_init(uint16_t baud_divisor) {
    // 1. Set DLAB bit to configure Baud Rate Divisor
    UART_LCR = UART_LCR_DLAB | UART_LCR_8N1;
    UART_DIV = (uint32_t)baud_divisor;

    // 2. Clear DLAB: configure standard 8N1 operation (8 bits, 1 stop bit, no parity)
    UART_LCR = UART_LCR_8N1;

    // 3. Enable FIFO, clear RX and TX FIFOs (FCR: bits [2:0] = 0x07)
    UART_FCR = 0x07;

    // 4. Disable peripheral interrupts for polled I/O mode
    UART_IER = 0x00;
}

void uart_putc(char c) {
    // Wait until Transmitter Holding Register Empty (THRE, bit 5) is set
    while (!(UART_LSR & UART_LSR_THRE));
    UART_THR = (uint32_t)(uint8_t)c;
}

void uart_puts(const char *str) {
    while (*str) {
        if (*str == '\n') {
            uart_putc('\r'); // Carriage return before newline
        }
        uart_putc(*str++);
    }
}

int uart_has_rx(void) {
    return (UART_LSR & UART_LSR_DR) ? 1 : 0;
}

char uart_getc(void) {
    while (!uart_has_rx());
    return (char)(UART_RBR & 0xFF);
}
