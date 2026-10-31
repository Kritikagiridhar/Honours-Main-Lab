# ==============================================================================
# Makefile for RISC-V C Firmware
# Targets VeeR EL2 core (RV32IMC, ilp32 ABI)
# ==============================================================================

CROSS_COMPILE ?= riscv64-unknown-elf-
CC            := $(CROSS_COMPILE)gcc
OBJCOPY       := $(CROSS_COMPILE)objcopy
OBJDUMP       := $(CROSS_COMPILE)objdump
SIZE          := $(CROSS_COMPILE)size

TARGET        := hello_world

SRCS_C        := main.c uart.c
SRCS_S        := crt0.S
OBJS          := $(SRCS_C:.c=.o) $(SRCS_S:.S=.o)

CFLAGS        := -march=rv32imc_zicsr -mabi=ilp32 -mcmodel=medlow -Os -Wall -Wextra \
                 -ffreestanding -nostdlib -fno-builtin -I.
LDFLAGS       := -T link.ld -nostdlib -Wl,--gc-sections -Wl,-Map=$(TARGET).map

.PHONY: all clean dump

all: $(TARGET).elf $(TARGET).bin $(TARGET).dump $(TARGET).hex firmware_words.vh
	@echo "========================================================"
	@echo " Build Complete: $(TARGET).elf"
	@echo "========================================================"
	$(SIZE) $(TARGET).elf

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET).elf: $(OBJS) link.ld
	$(CC) $(CFLAGS) $(OBJS) $(LDFLAGS) -o $@

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O verilog $< $@

$(TARGET).dump: $(TARGET).elf
	$(OBJDUMP) -d -S $< > $@

firmware_words.vh: $(TARGET).bin bin2hex.py
	python3 bin2hex.py $(TARGET).bin firmware_words.vh

clean:
	rm -f *.o *.elf *.bin *.hex *.dump *.map
