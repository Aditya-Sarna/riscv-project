// Simple instruction memory (read-only) initialized from a hex file (32-bit words)
module imem #(
    parameter ADDR_WIDTH = 12 // 4 KB instruction memory by default
) (
    input  logic [63:0] addr, // byte address
    output logic [31:0] instr
);
    localparam WORDS = (1 << (ADDR_WIDTH-2));
    logic [31:0] mem [0:WORDS-1];

    // initialize from file if present
    initial begin
        if ($value$plusargs("imem_init=%s")) begin
            // if a sim + parameter passed, $readmemh will be attempted by the user
        end
        // default: try to read rtl/imem.hex
        if ($fopen("rtl/imem.hex") != 0) begin
            $readmemh("rtl/imem.hex", mem);
        end
    end

    // Combinational read (assuming aligned, 32-bit)
    always_comb begin
        instr = mem[addr[ADDR_WIDTH-1:2]];
    end
endmodule
