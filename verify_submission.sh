#!/bin/bash
# Verification script for RISC-V Core submission

echo "=== RISC-V Core Submission Verification ==="
echo ""

# Check for required files
files=(
    "rtl/core.sv"
    "rtl/regfile.sv"
    "rtl/alu.sv"
    "rtl/imem.sv"
    "rtl/dmem.sv"
    "tb/tb_processor.sv"
    "software/test.c"
    "build_commands.txt"
    "design_diagram.pdf"
    "README.md"
    "DOCUMENTATION.md"
)

missing=0
for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "[MISSING] $file"
        missing=1
    else
        echo "[OK] Found: $file"
    fi
done

echo ""
if [ $missing -eq 0 ]; then
    echo "[OK] All required files present!"
else
    echo "[ERROR] Some files are missing. Please check."
    exit 1
fi

# Check if design_diagram.pdf is valid
if file design_diagram.pdf | grep -q "PDF"; then
    echo "[OK] design_diagram.pdf is a valid PDF"
else
    echo "[WARNING] design_diagram.pdf might be a placeholder (not a PDF)"
    echo "   Run './generate_diagram_pdf.sh' to create it"
fi

# Check if hex file can be generated
if [ ! -f "rtl/imem.hex" ]; then
    echo "[WARNING] rtl/imem.hex not found. Run 'make hex' to generate."
else
    echo "[OK] rtl/imem.hex exists ($(wc -l < rtl/imem.hex) instructions)"
fi

# Count Zba instructions in test.c
zba_count=$(grep -c "\.word 0x" software/test.c)
if [ $zba_count -ge 3 ]; then
    echo "[OK] Test program has $zba_count Zba instruction(s)"
else
    echo "[WARNING] Test program should have at least 3 Zba instructions (found: $zba_count)"
fi

echo ""
echo "=== Summary ==="
if [ $missing -eq 0 ]; then
    echo "[OK] Ready for submission!"
    echo ""
    echo "Next steps:"
    echo "  1. Ensure design_diagram.pdf is a valid PDF (not placeholder)"
    echo "  2. Run 'make hex' to generate imem.hex"
    echo "  3. Run 'make sim' to verify functionality"
    echo "  4. Create ZIP: zip -r riscv_core_submission.zip riscv_core/ -x 'riscv_core/build/*'"
else
    echo "[ERROR] Please add missing files before submission"
fi
