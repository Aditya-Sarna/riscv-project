# Makefile for RISC-V Core Project
# Supports building test program and running simulation

# Tool Configuration
RISCV_PREFIX ?= riscv64-unknown-elf-
CC = $(RISCV_PREFIX)gcc
OBJCOPY = $(RISCV_PREFIX)objcopy
OBJDUMP = $(RISCV_PREFIX)objdump

# Simulator Configuration (change as needed)
SIM ?= questa
# Options: questa, vcs, iverilog

# Directories
RTL_DIR = rtl
TB_DIR = tb
SW_DIR = software
BUILD_DIR = build

# Source Files
RTL_SOURCES = $(RTL_DIR)/regfile.sv $(RTL_DIR)/alu.sv $(RTL_DIR)/imem.sv $(RTL_DIR)/dmem.sv $(RTL_DIR)/core.sv
TB_SOURCES = $(TB_DIR)/tb_processor.sv
SW_SOURCE = $(SW_DIR)/test.c

# Output Files
ELF = $(SW_DIR)/test.elf
BIN = $(SW_DIR)/test.bin
HEX = $(RTL_DIR)/imem.hex
DISASM = $(BUILD_DIR)/test.dis

# Compilation Flags
CFLAGS = -march=rv64i -mabi=lp64 -O0 -nostdlib -Ttext=0x0

# Default target
.PHONY: all
all: hex disasm

# Create build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Compile C to ELF
$(ELF): $(SW_SOURCE) | $(BUILD_DIR)
	@echo "=== Compiling test program ==="
	$(CC) $(CFLAGS) $(SW_SOURCE) -o $(ELF)
	@echo "✓ Generated $(ELF)"

# Convert ELF to binary
$(BIN): $(ELF)
	@echo "=== Extracting binary ==="
	$(OBJCOPY) -O binary $(ELF) $(BIN)
	@echo "✓ Generated $(BIN)"

# Generate hex file for simulation
$(HEX): $(BIN)
	@echo "=== Generating instruction memory hex file ==="
	hexdump -v -e '1/4 "%08x\n"' $(BIN) > $(HEX)
	@echo "✓ Generated $(HEX)"
	@echo "  Lines: $$(wc -l < $(HEX))"

# Generate disassembly
$(DISASM): $(ELF) | $(BUILD_DIR)
	@echo "=== Generating disassembly ==="
	$(OBJDUMP) -D $(ELF) > $(DISASM)
	@echo "✓ Generated $(DISASM)"

# Build hex file (main build target)
.PHONY: hex
hex: $(HEX)
	@echo ""
	@echo "✓ Build complete! Ready for simulation."
	@echo "  Run 'make sim' to simulate"

# Generate disassembly
.PHONY: disasm
disasm: $(DISASM)

# Simulate with Questa/ModelSim
.PHONY: sim-questa
sim-questa: $(HEX)
	@echo "=== Running Questa/ModelSim simulation ==="
	@mkdir -p $(BUILD_DIR)/questa_work
	cd $(BUILD_DIR) && vlog -work questa_work ../$(RTL_SOURCES) ../$(TB_SOURCES)
	cd $(BUILD_DIR) && vsim -c -work questa_work tb_processor -do "run -all; quit -f"

# Simulate with VCS
.PHONY: sim-vcs
sim-vcs: $(HEX)
	@echo "=== Running VCS simulation ==="
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && vcs -sverilog -o simv ../$(RTL_SOURCES) ../$(TB_SOURCES)
	cd $(BUILD_DIR) && ./simv

# Simulate with Icarus Verilog
.PHONY: sim-iverilog
sim-iverilog: $(HEX)
	@echo "=== Running Icarus Verilog simulation ==="
	@echo "⚠ Warning: Icarus Verilog has limited SystemVerilog support"
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && iverilog -g2012 -o sim ../$(RTL_SOURCES) ../$(TB_SOURCES)
	cd $(BUILD_DIR) && ./sim

# Default simulation target (based on SIM variable)
.PHONY: sim
sim: hex
	@if [ "$(SIM)" = "questa" ]; then \
		$(MAKE) sim-questa; \
	elif [ "$(SIM)" = "vcs" ]; then \
		$(MAKE) sim-vcs; \
	elif [ "$(SIM)" = "iverilog" ]; then \
		$(MAKE) sim-iverilog; \
	else \
		echo "Unknown simulator: $(SIM)"; \
		echo "Set SIM to: questa, vcs, or iverilog"; \
		exit 1; \
	fi

# Generate diagram PDF
.PHONY: diagram
diagram:
	@echo "=== Generating design diagram PDF ==="
	./generate_diagram_pdf.sh

# View hex file
.PHONY: view-hex
view-hex: $(HEX)
	@echo "=== First 20 instructions from $(HEX) ==="
	@head -20 $(HEX)

# View disassembly
.PHONY: view-disasm
view-disasm: $(DISASM)
	@less $(DISASM)

# Clean build artifacts
.PHONY: clean
clean:
	@echo "=== Cleaning build artifacts ==="
	rm -f $(ELF) $(BIN) $(HEX) $(DISASM)
	rm -rf $(BUILD_DIR)
	@echo "✓ Clean complete"

# Deep clean (including simulator artifacts)
.PHONY: distclean
distclean: clean
	@echo "=== Deep cleaning ==="
	rm -rf work questa_work simv* csrc ucli.key vc_hdrs.h .vlogansetup.* *.log
	@echo "✓ Deep clean complete"

# Show project information
.PHONY: info
info:
	@echo "RISC-V RV64I + Zba Core Build System"
	@echo "====================================="
	@echo ""
	@echo "Configuration:"
	@echo "  RISCV_PREFIX = $(RISCV_PREFIX)"
	@echo "  Simulator    = $(SIM)"
	@echo ""
	@echo "Targets:"
	@echo "  make all        - Build hex and disassembly"
	@echo "  make hex        - Generate imem.hex file"
	@echo "  make disasm     - Generate disassembly"
	@echo "  make sim        - Run simulation (default: $(SIM))"
	@echo "  make diagram    - Generate design_diagram.pdf"
	@echo "  make view-hex   - View hex file contents"
	@echo "  make view-disasm- View disassembly"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make distclean  - Deep clean including sim files"
	@echo "  make info       - Show this information"
	@echo ""
	@echo "Simulator options:"
	@echo "  make sim SIM=questa   - Use Questa/ModelSim"
	@echo "  make sim SIM=vcs      - Use Synopsys VCS"
	@echo "  make sim SIM=iverilog - Use Icarus Verilog"

# Help target
.PHONY: help
help: info
