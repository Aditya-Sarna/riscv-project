#!/bin/bash
# Script to generate design_diagram.pdf from the text or Draw.io file

echo "=== RISC-V Core Design Diagram Generator ==="
echo ""

# Check if draw.io CLI is available
if command -v drawio &> /dev/null; then
    echo "Found Draw.io CLI. Converting .drawio to PDF..."
    drawio --export --format pdf --output design_diagram.pdf design_diagram.drawio
    echo "✓ Generated design_diagram.pdf from Draw.io file"
elif command -v draw.io &> /dev/null; then
    echo "Found Draw.io CLI (draw.io command). Converting .drawio to PDF..."
    draw.io --export --format pdf --output design_diagram.pdf design_diagram.drawio
    echo "✓ Generated design_diagram.pdf from Draw.io file"
else
    echo "Draw.io CLI not found."
    echo ""
    echo "Options to generate design_diagram.pdf:"
    echo ""
    echo "1. MANUAL: Open design_diagram.drawio in Draw.io web app"
    echo "   - Go to https://app.diagrams.net"
    echo "   - Open design_diagram.drawio"
    echo "   - File → Export as → PDF"
    echo "   - Save as design_diagram.pdf"
    echo ""
    echo "2. TEXT TO PDF: Convert design_diagram.txt to PDF"
    echo "   Using enscript (if available):"
    
    if command -v enscript &> /dev/null && command -v ps2pdf &> /dev/null; then
        echo "   Found enscript and ps2pdf. Converting text diagram..."
        enscript -B -f Courier8 --margins=20:20:20:20 -p - design_diagram.txt | ps2pdf - design_diagram.pdf
        echo "   ✓ Generated design_diagram.pdf from text file"
    else
        echo "   Install: brew install enscript ghostscript"
        echo "   Run: enscript -B -f Courier8 -p - design_diagram.txt | ps2pdf - design_diagram.pdf"
    fi
    echo ""
    echo "3. USE SYSTEM PRINT: Open design_diagram.txt and Print to PDF"
    echo ""
fi

# Check if PDF was created
if [ -f "design_diagram.pdf" ]; then
    echo ""
    echo "✓ design_diagram.pdf has been created!"
    echo "  File size: $(du -h design_diagram.pdf | cut -f1)"
else
    echo ""
    echo "⚠ design_diagram.pdf not created yet."
    echo "  Please follow one of the options above."
fi
