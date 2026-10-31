#ifndef UART_H
#define UART_H

#include <stdint.h>

// =============================================================================
// 16550-Compatible AXI UART Register Definitions
// Base Address in SoC Memory Map: 0x4000_6000
// =============================================================================
#define UART_BASE_ADDR      0x40006000UL

#define UART_REG(offset)    (*(volatile uint32_t *)(UART_BASE_ADDR + (offset)))

#define UART_RBR            UART_REG(0x00) // Receiver Buffer Register (Read, DLAB=0)
#define UART_THR            UART_REG(0x00) // Transmitter Holding Register (Write, DLAB=0)

#define UART_IER            UART_REG(0x04) // Interrupt Enable Register (DLAB=0)

#define UART_DIV            UART_REG(0x08) // Baud Divisor Register (Read/Write, DLAB=1)
#define UART_IIR            UART_REG(0x08) // Interrupt Identification Register (Read, DLAB=0)
#define UART_FCR            UART_REG(0x08) // FIFO Control Register (Write, DLAB=0)

#define UART_LCR            UART_REG(0x0C) // Line Control Register
#define UART_MCR            UART_REG(0x10) // Modem Control Register
#define UART_LSR            UART_REG(0x14) // Line Status Register
#define UART_MSR            UART_REG(0x18) // Modem Status Register
#define UART_SCR            UART_REG(0x1C) // Scratch Register

// Line Control Register (LCR) Bits
#define UART_LCR_8N1        (0x03)         // 8 Data Bits, 1 Stop Bit, No Parity
#define UART_LCR_DLAB       (1 << 7)       // Divisor Latch Access Bit

// Line Status Register (LSR) Bits
#define UART_LSR_DR         (1 << 0)       // Data Ready (RX FIFO has byte)
#define UART_LSR_THRE       (1 << 5)       // Transmitter Holding Register Empty (ready to send)
#define UART_LSR_TEMT       (1 << 6)       // Transmitter Empty (FIFO and shift reg empty)

// Function Prototypes
void uart_init(uint16_t baud_divisor);
void uart_putc(char c);
void uart_puts(const char *str);
int  uart_has_rx(void);
char uart_getc(void);

#endif // UART_H
