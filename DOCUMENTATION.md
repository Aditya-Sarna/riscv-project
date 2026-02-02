# RISC-V RV64I + Zba Extension Implementation Documentation

## Project Overview
This project implements a 5-stage pipelined RISC-V RV64I processor core with the Zba (address generation) extension. The implementation is designed for educational purposes and functional verification rather than performance optimization.

## Design Specifications

### Microarchitecture
- **Pipeline Stages**: 5 (IF, ID, EX, MEM, WB)
- **Data Width**: 64-bit
- **Instruction Width**: 32-bit
- **Register File**: 32 x 64-bit registers (x0-x31)
- **Memory Organization**: Separate instruction and data memories

### Implemented Instructions

#### RV64I Base Instructions
1. **R-type (opcode 0x33)**
   - ADD: `rd = rs1 + rs2`
   - SUB: `rd = rs1 - rs2`

2. **I-type**
   - ADDI (opcode 0x13): `rd = rs1 + imm`
   - LD (opcode 0x03): `rd = mem[rs1 + imm]`

3. **S-type (opcode 0x23)**
   - SD: `mem[rs1 + imm] = rs2`

4. **J-type (opcode 0x6F)**
   - JAL: `rd = PC + 4; PC = PC + imm`

#### Zba Extension (Custom Implementation)
- **Opcode**: 0x7F (custom)
- **Format**: R-type
- **Encoding**: `funct7[31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | rd[11:7] | opcode[6:0]`

**Implemented Operations:**
1. **AG_ADD** (funct7 = 0x12)
   - Function: `rd = rs1 + rs2`
   - Purpose: Address generation through addition
   - Use case: Computing array indices, pointer arithmetic

**Example Zba Instructions:**
```assembly
# AG_ADD x10, x1, x5 (encode as 0x0050852FB)
.word 0x0050852FB

# AG_ADD x11, x3, x4 (encode as 0x004185AFB)
.word 0x004185AFB

# AG_ADD x12, x7, x6 (encode as 0x00638607B)
.word 0x00638607B
```

## Module Descriptions

### 1. core.sv (Top-level Module)
The main processor module implementing the 5-stage pipeline.

**Interfaces:**
- **Input**: `clk`, `reset`
- **Instruction Memory**: `imem_addr[63:0]` (output), `imem_instr[31:0]` (input)
- **Data Memory**: `dmem_addr[63:0]`, `dmem_wdata[63:0]`, `dmem_ren`, `dmem_wen` (outputs), `dmem_rdata[63:0]` (input)
- **Debug**: `halted` (output)

**Pipeline Stages:**

1. **IF (Instruction Fetch)**
   - PC register maintains program counter
   - Fetches instruction from IMEM
   - Increments PC by 4

2. **ID (Instruction Decode)**
   - Decodes instruction fields (opcode, funct3, funct7, rs1, rs2, rd)
   - Generates immediate values
   - Reads register file
   - Checks for Zba extension (opcode == 0x7F)

3. **EX (Execute)**
   - **ALU Control Logic**: Determines operation based on opcode/funct7
   - **Zba Handling**: If opcode==0x7F, uses funct7 to select operation
   - **RV64I Handling**: Standard instruction execution
   - Computes memory addresses for loads/stores

4. **MEM (Memory Access)**
   - Reads from or writes to data memory
   - Passes through ALU results

5. **WB (Write Back)**
   - Selects between memory data and ALU result
   - Writes to register file

**Key Features:**
- Combinational ALU result computation
- Synchronous pipeline registers
- Simple halt detection (PC == 0xFFFFFFFFFFFFFFF0)

### 2. regfile.sv (Register File)
32 x 64-bit register file with dual read ports and single write port.

**Features:**
- x0 hardwired to zero
- Synchronous write
- Asynchronous read
- Initialized to zero for simulation

### 3. alu.sv (Arithmetic Logic Unit)
64-bit ALU supporting multiple operations.

**Operations (alu_ctrl):**
- 4'd0: ADD
- 4'd1: SUB
- 4'd2: AND
- 4'd3: OR
- 4'd4: XOR
- 4'd5: SLL (Shift Left Logical)
- 4'd6: SRL (Shift Right Logical)
- 4'd7: SRA (Shift Right Arithmetic)
- 4'd8: SLT (Set Less Than)
- 4'd9: SLTU (Set Less Than Unsigned)

### 4. imem.sv (Instruction Memory)
Read-only instruction memory (ROM).

**Parameters:**
- ADDR_WIDTH: 12 (default, 4KB memory)

**Initialization:**
- Reads from `rtl/imem.hex` using `$readmemh`
- Each line contains one 32-bit instruction in hexadecimal

### 5. dmem.sv (Data Memory)
Read/write data memory (RAM).

**Parameters:**
- ADDR_WIDTH: 12 (default, 4KB memory)

**Features:**
- 64-bit word size
- Synchronous write
- Combinational read
- Optional initialization from `rtl/dmem.hex`

## Testbench (tb_processor.sv)

### Structure
```
tb_processor
├── core (DUT)
├── imem (instruction memory)
└── dmem (data memory)
```

### Test Sequence
1. Generate 100 MHz clock (10ns period)
2. Apply reset for 20ns
3. Run for 10,000ns (1000 clock cycles)
4. Check memory location 0x100 for expected value (0x1234)
5. Report PASS/FAIL
6. Terminate simulation

### Self-Checking Features
- Monitors data memory writes
- Validates expected result at address 0x100
- Automatic pass/fail reporting

## Test Program (test.c)

### Purpose
Demonstrates processor functionality including:
- Basic arithmetic (addition)
- Memory access (store operation)
- Custom Zba instructions

### Structure
```c
int main() {
    uint64_t a = 10, b = 20, c;
    c = a + b;                    // Basic arithmetic
    DMEM[0] = 0x1234;            // Store success marker
    
    // Three Zba custom instructions
    asm volatile (".word 0x0050852FB");  // AG_ADD x10, x1, x5
    asm volatile (".word 0x004185AFB");  // AG_ADD x11, x3, x4
    asm volatile (".word 0x00638607B");  // AG_ADD x12, x7, x6
    
    while(1) asm volatile ("wfi");       // Halt
    return 0;
}
```

### Memory Map
- **0x00000000**: Code section (loaded into IMEM)
- **0x00000100**: Data section (DMEM test location)

## Build Process

### Prerequisites
- RISC-V GNU Toolchain (riscv64-unknown-elf-*)
- SystemVerilog simulator (Questa/ModelSim, VCS, or similar)

### Step 1: Compile C Program
```bash
riscv64-unknown-elf-gcc -march=rv64i -mabi=lp64 -O0 -nostdlib -Ttext=0x0 \
    software/test.c -o software/test.elf
```

**Flags:**
- `-march=rv64i`: Target RV64I architecture
- `-mabi=lp64`: Use LP64 ABI (long and pointers are 64-bit)
- `-O0`: No optimization (for readability)
- `-nostdlib`: Don't link standard library
- `-Ttext=0x0`: Link code at address 0x0

### Step 2: Extract Binary
```bash
riscv64-unknown-elf-objcopy -O binary software/test.elf software/test.bin
```

### Step 3: Generate Hex File
```bash
hexdump -v -e '1/4 "%08x\n"' software/test.bin > rtl/imem.hex
```

**Format:**
- One 32-bit instruction per line
- Little-endian hexadecimal
- No address prefixes

### Step 4: Simulate
```bash
# Questa/ModelSim
vlog rtl/*.sv tb/tb_processor.sv
vsim -c tb_processor -do "run -all; quit"

# VCS
vcs -sverilog rtl/*.sv tb/tb_processor.sv
./simv

# Icarus Verilog (limited SystemVerilog support)
iverilog -g2012 -o sim rtl/*.sv tb/tb_processor.sv
./sim
```

## Simulation Results

### Expected Output
```
Starting testbench
Checking dmem[32] = 0000000000001234
TEST PASSED: memory match
```

### Debugging
If test fails:
1. Check that `rtl/imem.hex` exists and is correctly formatted
2. Verify memory addressing (byte vs. word addressing)
3. Use waveform viewer to trace instruction execution
4. Check register file values during execution

## Design Trade-offs

### Simplifications
1. **No Hazard Detection**: Data hazards not fully handled
2. **No Forwarding**: Results must pass through all pipeline stages
3. **No Branch Prediction**: Branches cause pipeline bubbles
4. **Limited Instruction Set**: Only subset of RV64I implemented
5. **Custom Zba Encoding**: Uses custom opcode (0x7F) instead of standard

### Justifications
- Focus on functional correctness over performance
- Educational clarity over optimization
- Easier verification and debugging
- Suitable for demonstrating core concepts

## Verification Strategy

### Unit Testing
- Individual module simulation (regfile, ALU)
- Boundary condition testing

### Integration Testing
- Full processor simulation with test program
- Memory interface validation

### Self-Checking Testbench
- Automated pass/fail determination
- No manual waveform inspection required for basic validation

## Extensions and Improvements

### Potential Enhancements
1. **Hazard Handling**: Add forwarding paths and stall logic
2. **Branch Prediction**: Simple 1-bit predictor
3. **More Instructions**: Complete RV64I instruction set
4. **Standard Zba**: Implement official Zba encodings (sh1add, sh2add, sh3add)
5. **CSR Support**: Control and Status Registers
6. **Interrupt Handling**: Basic interrupt controller
7. **Performance Counters**: Cycle count, instruction count, stalls

### Debugging Features
1. **Trace Logger**: Instruction and register trace output
2. **Assertion Checking**: SVA properties for pipeline invariants
3. **Coverage Analysis**: Functional and code coverage

## File Manifest

### RTL Files (rtl/)
- `core.sv` - Top-level processor
- `regfile.sv` - Register file
- `alu.sv` - ALU
- `imem.sv` - Instruction memory
- `dmem.sv` - Data memory

### Testbench (tb/)
- `tb_processor.sv` - System-level testbench

### Software (software/)
- `test.c` - C test program

### Documentation
- `README.md` - Quick start guide
- `DOCUMENTATION.md` - This file
- `design_diagram.txt` - ASCII art datapath diagram
- `design_diagram.drawio` - Draw.io source file
- `design_diagram.pdf` - PDF diagram (user must generate)
- `build_commands.txt` - Toolchain commands

## References

### RISC-V Specifications
- RISC-V Unprivileged ISA Specification v20191213
- RISC-V "Zba" Address Generation Extension (draft)

### Tools
- RISC-V GNU Toolchain: https://github.com/riscv-collab/riscv-gnu-toolchain
- Draw.io: https://app.diagrams.net

## Contact and Support
For questions or issues with this implementation, refer to:
1. RISC-V specification documents
2. SystemVerilog language reference
3. Toolchain documentation

## License
Educational/academic use. Not intended for commercial deployment.

---
**Last Updated**: January 23, 2026
**Version**: 1.0
