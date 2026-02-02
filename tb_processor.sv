`timescale 1ns/1ps
module tb_processor;
    logic clk;
    logic reset;

    // imem interface
    logic [63:0] imem_addr;
    logic [31:0] imem_instr;

    // dmem interface
    logic dmem_ren, dmem_wen;
    logic [63:0] dmem_addr;
    logic [63:0] dmem_wdata;
    logic [63:0] dmem_rdata;

    // instantiate imem and dmem
    imem im(.addr(imem_addr), .instr(imem_instr));
    dmem dm(.clk(clk), .ren(dmem_ren), .wen(dmem_wen), .addr(dmem_addr), .wdata(dmem_wdata), .rdata(dmem_rdata));

    // instantiate core
    logic halted;
    core dut(.clk(clk), .reset(reset), .imem_addr(imem_addr), .imem_instr(imem_instr), .dmem_ren(dmem_ren), .dmem_wen(dmem_wen), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_rdata(dmem_rdata), .halted(halted));

    // clock
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz equivalent for simulation

    initial begin
        $display("Starting testbench");
        reset = 1;
        #20;
        reset = 0;

        // run for fixed cycles - the test program should write a result to data memory
        #10000;

        // check memory location 0x100 (word index 0x100 / 8)
        integer idx;
        idx = 16; // 0x100 / 8 = 256/8 = 32 -> but default ADDR_WIDTH might differ; compute below
        // try to compute index from parameterization: use 0x100
        idx = 256 / 8;

        $display("Checking dmem[%0d] = %h", idx, dm.mem[idx]);
        // simple check: expecting value 0x1234 (the test program stores this)
        if (dm.mem[idx] == 64'h0000_0000_0000_1234) begin
            $display("TEST PASSED: memory match");
        end else begin
            $display("TEST FAILED: expected 0x1234, got %h", dm.mem[idx]);
        end

        $finish;
    end
endmodule
