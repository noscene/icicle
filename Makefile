QUIET    =
PLL      = pll.sv
SRC      = $(sort $(wildcard *.sv) $(PLL))
TOP      = top
SV       = $(TOP).sv
YS       = $(TOP).ys
YS_ICE40 = `yosys-config --datdir/ice40/cells_sim.v`
BLIF     = $(TOP).blif
JSON     = $(TOP).json
ASC_SYN  = $(TOP)_syn.asc
ASC      = $(TOP).asc
BIN      = $(TOP).bin
TIME_RPT = $(TOP).rpt
STAT     = $(TOP).stat
BOARD   ?= doppler
PNR     ?= arachne-pnr
PCF      = boards/$(BOARD).pcf
FREQ_PLL = 16
TARGET   = riscv32-unknown-elf
AS       = $(TARGET)-as
ASFLAGS  = -march=rv32i -mabi=ilp32
LD       = $(TARGET)-gcc
LDFLAGS  = $(CFLAGS) -Wl,-Tprogmem.lds
CC       = $(TARGET)-gcc
CFLAGS   = -march=rv32i -mabi=ilp32 -Wall  -mno-relax  -Wextra -pedantic -DFREQ=$(FREQ_PLL)000000 -Os -ffreestanding -nostartfiles -g
OBJCOPY  = $(TARGET)-objcopy

include boards/$(BOARD).mk

.PHONY: all clean syntax time stat flash

all: $(BIN) header

header: $(BIN)
		xxd -i $(BIN) > $(BIN).h
		sed -i -r 's/unsigned/const unsigned/g' $(BIN).h

clean:
	$(RM) $(BLIF) $(JSON) $(ASC_SYN) $(ASC) $(BIN) $(PLL) $(TIME_RPT) $(STAT) progmem_syn.hex progmem.hex progmem.bin progmem.o start.o start.s progmem progmem.lds defines.sv

progmem.bin: progmem
	$(OBJCOPY) -O binary $< $@

progmem.hex: progmem.bin
	xxd -p -c 4 < $< > $@

progmem: progmem.o start.o progmem.lds
	$(LD) $(LDFLAGS) -o $@ progmem.o start.o

progmem_syn.hex:
	icebram -g 32 2048 > $@

$(PLL):
	icepll $(QUIET) -i $(FREQ_OSC) -o $(FREQ_PLL) -m -f $@

$(BLIF) $(JSON): $(YS) $(SRC) progmem_syn.hex defines.sv
	yosys $(QUIET) $<

syntax: $(SRC) progmem_syn.hex defines.sv
	iverilog -Wall -t null -g2012 $(YS_ICE40) $(SV)

defines.sv: boards/$(BOARD)-defines.sv
	cp boards/$(BOARD)-defines.sv defines.sv

start.s: start-$(PROGMEM).s
	cp $< $@

progmem.lds: progmem-$(PROGMEM).lds
	cp $< $@

ifeq ($(PNR),arachne-pnr)
$(ASC_SYN): $(BLIF) $(PCF)
	arachne-pnr $(QUIET) -d $(DEVICE) -P $(PACKAGE) -o $@ -p $(PCF) $<
else
$(ASC_SYN): $(JSON) $(PCF)
	nextpnr-ice40 $(QUIET) --$(SPEED)$(DEVICE) --package $(PACKAGE) --json $< --pcf $(PCF) --freq $(FREQ_PLL) --asc $@
endif

$(TIME_RPT): $(ASC_SYN) $(PCF)
	icetime -t -m -d $(SPEED)$(DEVICE) -P $(PACKAGE) -p $(PCF) -c $(FREQ_PLL) -r $@ $<

$(ASC): $(ASC_SYN) progmem_syn.hex progmem.hex
ifeq ($(PROGMEM),ram)
	icebram progmem_syn.hex progmem.hex < $< > $@
else
	cp $< $@
endif

$(BIN): $(ASC)
	icepack $< $@

time: $(TIME_RPT)
	cat $<

$(STAT): $(ASC_SYN)
	icebox_stat $< > $@

stat: $(STAT)
	cat $<

flash: $(BIN) progmem.bin $(TIME_RPT)
	iceprog $<
ifeq ($(PROGMEM),flash)
	iceprog -o 1M progmem.bin
endif

# Flash to BlackIce-II board
dfu-flash: $(BIN) $(TIME_RPT)
	dfu-util -d 0483:df11 --alt 0 --dfuse-address 0x0801F000 -D $(BIN)
