// Simple ALU supporting a subset of RV64I and custom Zba operations
module alu(
    input logic [63:0] a,
    input logic [63:0] b,
    input logic [3:0] alu_ctrl,
    output logic [63:0] result
);

    always_comb begin
        unique case (alu_ctrl)
            4'd0: result = a + b; // ADD
            4'd1: result = a - b; // SUB
            4'd2: result = a & b; // AND
            4'd3: result = a | b; // OR
            4'd4: result = a ^ b; // XOR
            4'd5: result = a << b[5:0]; // SLL
            4'd6: result = a >> b[5:0]; // SRL (logical)
            4'd7: result = $signed(a) >>> b[5:0]; // SRA (arithmetic)
            4'd8: result = ($signed(a) < $signed(b)) ? 64'd1 : 64'd0; // SLT
            4'd9: result = (a < b) ? 64'd1 : 64'd0; // SLTU
            default: result = 64'd0;
        endcase
    end
endmodule
