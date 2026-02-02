# RISC-V Core Quick Reference

## Project Structure
```
riscv_core/
├── rtl/               # SystemVerilog RTL
├── tb/                # Testbench
├── software/          # C test program
├── build/             # Build artifacts (auto-generated)
└── docs/              # Documentation files
```

## Quick Commands

### Build
```bash
make hex              # Generate imem.hex
make disasm           # Generate disassembly
make all              # Build everything
```

### Simulate
```bash
make sim              # Default simulator
make sim SIM=questa   # Questa/ModelSim
make sim SIM=vcs      # Synopsys VCS
make sim SIM=iverilog # Icarus Verilog
```

### Verify
```bash
./verify_submission.sh     # Check all files
make view-hex              # View instructions
make view-disasm           # View disassembly
```

### Clean
```bash
make clean            # Remove build artifacts
make distclean        # Deep clean including sim files
```

## Manual Build (No Makefile)
```bash
# 1. Compile C to ELF
riscv64-unknown-elf-gcc -march=rv64i -mabi=lp64 -O0 -nostdlib \
    -Ttext=0x0 software/test.c -o software/test.elf

# 2. Extract binary
riscv64-unknown-elf-objcopy -O binary software/test.elf software/test.bin

# 3. Generate hex
hexdump -v -e '1/4 "%08x\n"' software/test.bin > rtl/imem.hex

# 4. Simulate (example: Questa)
vlog rtl/*.sv tb/tb_processor.sv
vsim -c tb_processor -do "run -all; quit"
```

## Architecture Quick Facts

**Pipeline**: 5 stages (IF, ID, EX, MEM, WB)
**Data Width**: 64-bit
**Register File**: 32 x 64-bit registers
**Memories**: 4 KB IMEM + 4 KB DMEM (configurable)

## Zba Extension Quick Reference

**Opcode**: 0x7F (custom)
**Format**: R-type

### AG_ADD Instruction
```
Encoding: funct7[31:25] | rs2[24:20] | rs1[19:15] | 0[14:12] | rd[11:7] | 0x7F[6:0]
Function: rd = rs1 + rs2
Purpose:  Address generation
```

### Example Encodings
```c
// AG_ADD x10, x1, x5
.word 0x0050852FB

// AG_ADD x11, x3, x4
.word 0x004185AFB

// AG_ADD x12, x7, x6
.word 0x00638607B
```

## RV64I Instructions Implemented

| Instruction | Opcode | Type | Function |
|-------------|--------|------|----------|
| ADD         | 0x33   | R    | rd = rs1 + rs2 |
| SUB         | 0x33   | R    | rd = rs1 - rs2 |
| ADDI        | 0x13   | I    | rd = rs1 + imm |
| LD          | 0x03   | I    | rd = mem[rs1+imm] |
| SD          | 0x23   | S    | mem[rs1+imm] = rs2 |
| JAL         | 0x6F   | J    | rd = PC+4; PC += imm |

## Memory Map

| Address    | Description |
|------------|-------------|
| 0x00000000 | Code start (IMEM) |
| 0x00000100 | Test data location (DMEM) |

## Test Program Behavior

1. Initialize variables (a=10, b=20)
2. Compute c = a + b
3. Store 0x1234 to address 0x100
4. Execute 3 Zba instructions
5. Halt (infinite loop with WFI)

## Expected Simulation Output
```
Starting testbench
Checking dmem[32] = 0000000000001234
TEST PASSED: memory match
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| imem.hex not found | Run `make hex` |
| Test fails | Check memory addressing (byte vs word) |
| Syntax errors | Use SystemVerilog-compatible simulator |
| Toolchain missing | Install RISC-V GNU toolchain |

## File Descriptions

| File | Purpose |
|------|---------|
| core.sv | Top-level processor module |
| regfile.sv | Register file (32 x 64) |
| alu.sv | Arithmetic logic unit |
| imem.sv | Instruction memory (ROM) |
| dmem.sv | Data memory (RAM) |
| tb_processor.sv | Self-checking testbench |
| test.c | C test program |

## Submission Checklist

- [ ] All RTL files present
- [ ] Testbench present
- [ ] Test program present
- [ ] Build commands documented
- [ ] design_diagram.pdf is VALID PDF (not placeholder)
- [ ] Documentation complete
- [ ] Verified with `./verify_submission.sh`

## Create Submission ZIP
```bash
cd "/Users/adityasarna/RISC -V INTERNSHIP"
zip -r riscv_core_submission.zip riscv_core/ \
    -x "riscv_core/build/*" \
    -x "riscv_core/.DS_Store"
```

## Help & Documentation

- **README.md** - Main documentation
- **DOCUMENTATION.md** - Technical details
- **SUBMISSION_GUIDE.md** - Submission instructions
- **PROJECT_SUMMARY.md** - Project overview
- **build_commands.txt** - Toolchain commands

## Simulator-Specific Commands

### Questa/ModelSim
```bash
vlog rtl/*.sv tb/tb_processor.sv
vsim -gui tb_processor
# or headless: vsim -c tb_processor -do "run -all; quit"
```

### Synopsys VCS
```bash
vcs -sverilog rtl/*.sv tb/tb_processor.sv -o simv
./simv
```

### Icarus Verilog
```bash
iverilog -g2012 -o sim rtl/*.sv tb/tb_processor.sv
./sim
```

## Design Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| IMEM ADDR_WIDTH | 12 | 4 KB instruction memory |
| DMEM ADDR_WIDTH | 12 | 4 KB data memory |
| Clock Period | 10ns | 100 MHz equivalent |
| Sim Duration | 10000ns | 1000 clock cycles |

## ALU Operations

| alu_ctrl | Operation | Description |
|----------|-----------|-------------|
| 4'd0 | ADD | Addition |
| 4'd1 | SUB | Subtraction |
| 4'd2 | AND | Bitwise AND |
| 4'd3 | OR | Bitwise OR |
| 4'd4 | XOR | Bitwise XOR |
| 4'd5 | SLL | Shift left logical |
| 4'd6 | SRL | Shift right logical |
| 4'd7 | SRA | Shift right arithmetic |
| 4'd8 | SLT | Set less than (signed) |
| 4'd9 | SLTU | Set less than (unsigned) |

---
Last Updated: January 23, 2026
Version: 1.0
