TARGETS = power_test lrwpan_loopback ble_loopback template

#################################
# RISCV Toolchain
#################################

# SiFive Toolchain
#PREFIX = riscv64-unknown-elf-

# Nuclei Toolchain
#PREFIX = riscv-nuclei-elf-

# xPack Toolchain
PREFIX = riscv-none-elf-


CC = $(PREFIX)gcc
CXX = $(PREFIX)g++
CP = $(PREFIX)objcopy
OD = $(PREFIX)objdump
DG = $(PREFIX)gdb
SIZE = $(PREFIX)size


#################################
# Working directories
#################################
VENDOR_ROOT = bsp/
USR_DIR = core/
SRC_DIR = $(USR_DIR)src/
INC_DIR = $(USR_DIR)inc/
BUILD_DIR = build/
SCRIPT_DIR = ../scripts/


#################################
# Source Files
#################################
A_SOURCES  = $(wildcard $(SRC_DIR)*.S) $(wildcard $(SRC_DIR)*/*.S)

TARGET_SRC = $(foreach target, $(TARGETS), $(SRC_DIR)$(target).c)

A_SOURCES += $(USR_DIR)startup/startup.S

C_SOURCES = $(VENDOR_ROOT)scum/src/scum_system.c
C_SOURCES += $(VENDOR_ROOT)scum/src/scum_hal.c
C_SOURCES += $(VENDOR_ROOT)scum/src/scum_hal_core.c
C_SOURCES += $(VENDOR_ROOT)scum/src/scum_hal_clint.c
C_SOURCES += $(VENDOR_ROOT)scum/src/scum_hal_gpio.c
C_SOURCES += $(VENDOR_ROOT)scum/src/scum_hal_plic.c
C_SOURCES += $(VENDOR_ROOT)scum/src/scum_hal_rcc.c
C_SOURCES += $(VENDOR_ROOT)scum/src/scum_hal_uart.c
C_SOURCES += $(VENDOR_ROOT)scum/src/baseband.c

INCLUDES  = -I$(INC_DIR)
INCLUDES += -I$(INC_DIR)hal/
INCLUDES += -I$(VENDOR_ROOT)scum/inc


#################################
# Object List
#################################
A_OBJECTS = $(addsuffix .o,$(addprefix $(BUILD_DIR),$(basename $(A_SOURCES))))
C_OBJECTS = $(addsuffix .o,$(addprefix $(BUILD_DIR),$(basename $(C_SOURCES))))
TARGET_OBJS = $(addsuffix .o,$(addprefix $(BUILD_DIR),$(basename $(TARGET_SRC))))

OBJECTS = $(A_OBJECTS) $(C_OBJECTS)

#################################
# Target Output Files
#################################
TARGET_ELF = $(foreach target, $(TARGETS), $(BUILD_DIR)$(target).elf)
TARGET_DUMP = $(foreach target, $(TARGETS), $(BUILD_DIR)$(target).dump)
TARGET_HEX = $(foreach target, $(TARGETS), $(BUILD_DIR)$(target).hex)
TARGET_BIN = $(foreach target, $(TARGETS), $(BUILD_DIR)$(target).bin)

#################################
# Flags
#################################

# MCU Settings
ARCH = rv32imafc
ABI = ilp32f
CODEMODEL = medany
LD_SCRIPT = $(SRC_DIR)scum.ld

ARCHFLAGS = -march=$(ARCH) -mabi=$(ABI) -mcmodel=$(CODEMODEL) -fno-pie
SPECFLAGS = --specs="nano.specs"

# compiler Flags
CFLAGS  = -g -std=gnu11 -Os -Wall -Wextra -Warray-bounds -Wno-unused-parameter
CFLAGS += -fno-common -fno-builtin-printf
CFLAGS += $(ARCHFLAGS)
CFLAGS += $(SPECFLAGS)
CFLAGS += $(INCLUDES)

# linker Flags
LFLAGS  = -static
# LFLAGS += -nostartfiles -nostdlib
LFLAGS += -nostartfiles
LFLAGS += -T $(LD_SCRIPT)


#################################
# Build
#################################

# default target
all: $(TARGET_ELF) $(TARGET_HEX) $(TARGET_DUMP) $(TARGET_BIN)

$(TARGET_ELF): $(BUILD_DIR)%.elf: $(BUILD_DIR)$(SRC_DIR)%.o $(OBJECTS)
	@echo "[LD] linking $@"
	@$(CC) $(CFLAGS) $(LFLAGS) $^ -o $@
	$(SIZE) $@

$(TARGET_DUMP): %.dump: %.elf
	@echo "[OD] dumping $@"
	@$(OD) -D -S -M numeric $< > $@
	
$(TARGET_HEX): %.hex: %.elf
	@echo "Converting ELF to HEX $@"
	@$(SCRIPT_DIR)smartelf2hex.sh $< > $@

$(TARGET_BIN): %.bin: %.elf
	@echo "Converting ELF to BIN $@"
	@$(CP) -O binary $< $@

$(A_OBJECTS): $(BUILD_DIR)%.o: %.S
	@echo "[CC] compiling $@"
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) -c $< -o $@

$(C_OBJECTS) $(TARGET_OBJS): $(BUILD_DIR)%.o: %.c
	@echo "[CC] compiling $@"
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) -c $< -o $@

#################################
# Recipes
#################################

clean:
	@rm -rf $(BUILD_DIR)

hex: $(TARGET_HEX)

bin: $(TARGET_BIN)

# for debugging Makefile
list:
	@echo "A_SOURCES: $(A_SOURCES)"
	@echo "C_SOURCES: $(C_SOURCES)"
	@echo "A_OBJECTS: $(A_OBJECTS)"
	@echo "C_OBJECTS: $(C_OBJECTS)"
