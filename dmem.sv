// Simple data memory (read/write) with 64-bit words, byte-addressable
module dmem #(
    parameter ADDR_WIDTH = 12 // 4 KB data memory
) (
    input  logic clk,
    input  logic ren,
    input  logic wen,
    input  logic [63:0] addr,
    input  logic [63:0] wdata,
    output logic [63:0] rdata
);
    localparam WORDS = (1 << (ADDR_WIDTH-3)); // number of 64-bit words
    logic [63:0] mem [0:WORDS-1];

    // optional initialization: look for rtl/dmem.hex
    initial begin
        if ($fopen("rtl/dmem.hex") != 0) begin
            $readmemh("rtl/dmem.hex", mem);
        end
    end

    // synchronous write
    always_ff @(posedge clk) begin
        if (wen) begin
            mem[addr[ADDR_WIDTH-1:3]] <= wdata;
        end
    end

    // combinational read
    always_comb begin
        if (ren) rdata = mem[addr[ADDR_WIDTH-1:3]];
        else rdata = 64'd0;
    end

    // for testbench visibility
    // expose mem for checking via hierarchical path in testbench
endmodule
