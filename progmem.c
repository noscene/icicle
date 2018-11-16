#include <stdint.h>

/*          DOPPLER-Board-Layout:
 *                                                                                    ---------------- FPGA Pins ------------------
 *                                                     DAC1      SCK  MOSI DAC0      LedR LedG LedB       CT1            CP0
 * DIL Pin 48   47   46   45   44   43   42   41   40   39   38   37   36   35   34   33   32   31   30   29   28   27   26   25
 *       |--O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O---|
 * name  | VIN  5V  3.3V  A10  A9   A8   A7   A6   A5   A4   A3   A2   A1   A0   GND  R2   R1   R0   F14  F13  F12  F11  F10  F9   |
 * alt   | VIN  5V  3.3V PA11 PA10 PA09 PA08 PA07 PA06 PA05 PA04 PB09 PB08 PA02  GND  41   40   39   38   37   36   35   34   32   |
 *       |                                                                                            ö  ö  ö  ö                   |
 *      |                                                                                             ö  ö  ö  ö         |BTN:S1|  |
 *     | USB                           DOPPLER: SamD51 <- SPI -> icE40        |BTN:RESET|             ö  ö  ö  ö                   |
 *      |                                                                                             ö  ö  ö  ö         |BTN:S2|  |
 *       |                                                                                                                         |
 * alt   | GND PA13 PA12 PB11 PA14 PA15 PB10 PA31 PA30  RES PA19 PA20 PA21 PA22 3.3V  11   12   13   18   19   20   21   23   25   |
 * name  | GND   0    1    2    3    4    5                   6    7    8    9  3.3V  F0   F1   F2   F3   F4   F5   F6   F7   F8   |
 *       L--O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O----O---|
 * DIL Pin  1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24
 *             SCL  SDA   MISO           SS   SWD  SWC RES                                 CT0                      CP0
 *             -- I2C--                       --- SWD  ---   ----- Shared  -----      ---------------- FPGA Pins ------------------
 */

/*  Arduino Sketch to Upload into FPGA
#include <ICEClass.h>
#include "/Users/svenbraun/Documents/GitHub/icicle/top.bin.h"
ICEClass ice40;

void setup() {
  ice40.upload(top_bin,sizeof(top_bin)); // Upload BitStream Firmware to FPGA -> see variant.h
}

void loop() {
  delay(1000);
}
*/

// Here we define some Custom Hardware Register ... see top.sv
//#define LEDS        *((volatile uint32_t *) 0x00010000) // need to replace
#define UART_BAUD   *((volatile uint32_t *) 0x00020000)  // uart_rx = PA19  , uart_tx = PA20
#define UART_STATUS *((volatile uint32_t *) 0x00020004)
#define UART_DATA   *((volatile  int32_t *) 0x00020008)

#define MTIME       *((volatile uint64_t *) 0x00030000)
#define MTIMECMP    *((volatile uint64_t *) 0x00030008)

#define LED4X4      *((volatile uint32_t *) 0x00040000) // 16Bit Value for all LEDs
#define GPIO_DIR    *((volatile uint32_t *) 0x00050000) // lower 8 Bits are Pins F0----F7 0 = In | 1 = Out
#define GPIO_DATA   *((volatile uint32_t *) 0x00050004) // lower 8 Bits are PinState In or Out
#define BUTTONS     *((volatile uint32_t *) 0x00060000) // 2 buttons in the lower 2 bits

#define OSC_PITCH   *((volatile uint32_t *) 0x00070000) // 2 buttons in the lower 2 bits
#define VCA_LEVEL   *((volatile uint32_t *) 0x00070004) // 2 buttons in the lower 2 bits


#define UART_STATUS_TX_READY  0x1
#define UART_STATUS_RX_READY  0x2
#define BAUD_RATE             9600

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

static void delay(uint32_t dly) {
    for (uint32_t i = 0 ; i < dly ; i ++)
      asm volatile ("nop");
}

static inline uint32_t rdcycle(void) {
    uint32_t cycle;
    asm volatile ("rdcycle %0" : "=r"(cycle));
    return cycle;
}

/*
// soft FIFO
#define CON_OUT_BUF_SIZE         8 // Buffer masks
#define CON_OUT_MASK             (CON_OUT_BUF_SIZE-1ul) // Buffer read / write macros
#define CON_BUF_RESET(Fifo)      (Fifo->rd_idx = Fifo->wr_idx = 0)
#define CON_BUF_WR(Fifo, dataIn) (Fifo->data[CON_OUT_MASK &  Fifo->wr_idx++] = (dataIn))
#define CON_BUF_RD(Fifo)         (Fifo->data[CON_OUT_MASK & Fifo->rd_idx++])
#define CON_BUF_EMPTY(Fifo)      ((CON_OUT_MASK & Fifo->rd_idx) == (CON_OUT_MASK & Fifo->wr_idx))
#define CON_BUF_FULL(Fifo)       ((CON_OUT_MASK & Fifo->rd_idx) == (CON_OUT_MASK & Fifo->wr_idx+1))
#define CON_BUF_COUNT(Fifo)      ((CON_OUT_MASK & Fifo.wr_idx) - (CON_OUT_MASK & Fifo.rd_idx))
typedef struct {
  unsigned uint32_t data[CON_OUT_BUF_SIZE];
  unsigned int wr_idx;
  unsigned int rd_idx;
} CON_Fifo_t;
*/


int main() {
    GPIO_DIR = 0x0;  // all inputs
    UART_BAUD = FREQ / BAUD_RATE;
    uint32_t pitch = 500;
    uint16_t vca = 32000;
    OSC_PITCH = pitch;
    VCA_LEVEL = vca;
    for (;;) {
        // uart_puts("Hello, world!\r\n");
        // uint32_t start = rdcycle();
        // while ((rdcycle() - start) <= FREQ); // wait a second
        switch(BUTTONS){
          case 0: (LED4X4)++;   break;
          case 1: (LED4X4)--;   break;
          case 3: (LED4X4)+=16; break;
        }
        delay(800000);
        pitch+=1024;
        if(pitch > 8000){
          pitch=500;
          vca = 32000;
        }
        vca-=4000;
        VCA_LEVEL = vca;
        OSC_PITCH = pitch;
    }
}
