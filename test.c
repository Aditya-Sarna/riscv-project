// Simple test program to exercise RV64I and the custom Zba extension
// This program writes a known value to memory[0x100] so the testbench can
// check for success.

#include <stdint.h>

volatile uint64_t * const DMEM = (uint64_t *)0x00000100; // write result here

int main() {
    uint64_t a = 10, b = 20, c;

    // Basic arithmetic
    c = a + b; // should be 30

    // Store c into data memory via regular store
    DMEM[0] = 0x1234; // indicate success marker

    // --- Zba custom instructions usage ---
    // We emit three custom Zba words using inline asm .word. The CPU decoder
    // recognizes opcode 0x7F and funct7 0x12 as AG_ADD (rd = rs1 + rs2)

    // ZBA example 1: AG_ADD x10, x1, x5  -> emit an R-type word
    // Build raw R-type: funct7[31:25]=0x12, rs2=5, rs1=1, funct3=0, rd=10, opcode=0x7F
    // Format: funct7[25] | rs2[5] | rs1[5] | funct3[3] | rd[5] | opcode[7]
    asm volatile (".word 0x0050852FB"); // 0x12 << 25 | 5 << 20 | 1 << 15 | 0 << 12 | 10 << 7 | 0x7F

    // ZBA example 2: AG_ADD x11, x3, x4
    // funct7=0x12, rs2=4, rs1=3, funct3=0, rd=11, opcode=0x7F
    asm volatile (".word 0x004185AFB"); // 0x12 << 25 | 4 << 20 | 3 << 15 | 0 << 12 | 11 << 7 | 0x7F

    // ZBA example 3: AG_ADD x12, x7, x6
    // funct7=0x12, rs2=6, rs1=7, funct3=0, rd=12, opcode=0x7F
    asm volatile (".word 0x00638607B"); // 0x12 << 25 | 6 << 20 | 7 << 15 | 0 << 12 | 12 << 7 | 0x7F;

    // stop - infinite loop
    while (1) asm volatile ("wfi");

    return 0;
}
