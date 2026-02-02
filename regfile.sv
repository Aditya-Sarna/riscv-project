// Simple 32 x 64-bit register file
module regfile(
    input logic clk,
    input logic we,
    input logic [4:0] ra1,
    input logic [4:0] ra2,
    input logic [4:0] wa,
    input logic [63:0] wd,
    output logic [63:0] rd1,
    output logic [63:0] rd2
);

    logic [63:0] regs [31:0];

    // Register x0 is hardwired to zero
    always_ff @(posedge clk) begin
        if (we && wa != 0) begin
            regs[wa] <= wd;
        end
    end

    assign rd1 = (ra1 == 0) ? 64'd0 : regs[ra1];
    assign rd2 = (ra2 == 0) ? 64'd0 : regs[ra2];

    // initialize registers to 0 for simulation clarity
    initial begin
        integer i;
        for (i = 0; i < 32; i = i + 1) regs[i] = 64'd0;
    end
endmodule
