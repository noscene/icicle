#include <stdint.h>

#define LEDS        *((volatile uint32_t *) 0x00010000)
#define UART_BAUD   *((volatile uint32_t *) 0x00020000)
#define UART_STATUS *((volatile uint32_t *) 0x00020004)
#define UART_DATA   *((volatile  int32_t *) 0x00020008)
#define MTIME       *((volatile uint64_t *) 0x00030000)
#define MTIMECMP    *((volatile uint64_t *) 0x00030008)
#define LED4X4      *((volatile uint32_t *) 0x00040000)

#define GPIO_DIR   *((volatile uint32_t *)  0x00050000) // lower 8 Bits are Pins F0----F7 0 = In | 1 = Out
#define GPIO_DATA  *((volatile uint32_t *)  0x00050004) // lower 8 Bits are PinState In or Out



#define UART_STATUS_TX_READY 0x1
#define UART_STATUS_RX_READY 0x2

#define BAUD_RATE 9600

static void uart_putc(char c) {
    while (!(UART_STATUS & UART_STATUS_TX_READY));
    UART_DATA = c;
}

static void uart_puts(const char *str) {
    char c;
    while ((c = *str++)) {
        uart_putc(c);
    }
}

static inline void delay(void) {
    for (uint32_t i = 0 ; i < 100000 ; i ++)
      asm volatile ("nop");
}


static inline uint32_t rdcycle(void) {
    uint32_t cycle;
    asm volatile ("rdcycle %0" : "=r"(cycle));
    return cycle;
}

int main() {
    GPIO_DIR = 0x0;  // all inputs

    UART_BAUD = FREQ / BAUD_RATE;
    // LEDS = 0xAA;
    uint32_t ledValue=1;
    for (;;) {
        // uart_puts("Hello, world!\r\n");
        LED4X4 = (GPIO_DATA);
        // delay();
        // ledValue+=1;
        // GPIO_DATA=ledValue;
        //uint32_t start = rdcycle();
        // while ((rdcycle() - start) <= FREQ);
    }
}
