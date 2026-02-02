// Top-level simple 5-stage pipelined RV64I core with a tiny Zba (address generation)
// extension. This is a teaching-quality core and not fully optimized. It is
// intended for simulation and functional verification.

// Note: regfile and ALU are instantiated as submodules
// Compile order: regfile.sv, alu.sv, then core.sv

module core(
    input logic clk,
    input logic reset,

    // Instruction memory interface
    output logic [63:0] imem_addr,
    input  logic [31:0] imem_instr,

    // Data memory interface
    output logic        dmem_ren,
    output logic        dmem_wen,
    output logic [63:0] dmem_addr,
    output logic [63:0] dmem_wdata,
    input  logic [63:0] dmem_rdata,

    // debug
    output logic halted
);

    // Program counter
    logic [63:0] pc;

    // Pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB)
    logic [31:0] if_id_instr;
    logic [63:0] if_id_pc;

    // ID/EX
    logic [4:0] id_ex_rs1, id_ex_rs2, id_ex_rd;
    logic [63:0] id_ex_imm;
    logic [63:0] id_ex_rs1_val, id_ex_rs2_val;
    logic [6:0] id_ex_opcode;
    logic [2:0] id_ex_funct3;
    logic [6:0] id_ex_funct7;

    // EX/MEM
    logic [4:0] ex_mem_rd;
    logic [63:0] ex_mem_alu_out;
    logic ex_mem_mem_write;
    logic ex_mem_mem_read;
    logic [63:0] ex_mem_rs2_val;

    // MEM/WB
    logic [4:0] mem_wb_rd;
    logic [63:0] mem_wb_lsu_data;
    logic [63:0] mem_wb_alu_out;
    logic mem_wb_reg_write;

    // Register file
    logic rf_we;
    logic [63:0] rf_wd;
    logic [63:0] rf_rd1, rf_rd2;

    // instantiate regfile
    regfile rf(.clk(clk), .we(rf_we), .ra1(if_id_instr[19:15]), .ra2(if_id_instr[24:20]), .wa(mem_wb_rd), .wd(rf_wd), .rd1(rf_rd1), .rd2(rf_rd2));

    // ALU
    logic [3:0] alu_ctrl;
    logic [63:0] alu_a, alu_b, alu_res;
    alu ALU(.a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl), .result(alu_res));

    // simple halted flag
    assign halted = (pc == 64'hFFFF_FFFF_FFFF_FFF0);

    // IF stage
    assign imem_addr = pc;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 64'd0;
            if_id_instr <= 32'd0;
            if_id_pc <= 64'd0;
        end else begin
            // fetch
            if_id_instr <= imem_instr;
            if_id_pc <= pc;
            pc <= pc + 4;
        end
    end

    // ID stage: decode
    always_comb begin
        id_ex_opcode = if_id_instr[6:0];
        id_ex_funct3 = if_id_instr[14:12];
        id_ex_funct7 = if_id_instr[31:25];
        id_ex_rs1 = if_id_instr[19:15];
        id_ex_rs2 = if_id_instr[24:20];
        id_ex_rd  = if_id_instr[11:7];
        // immediate generation: I-type and S-type and B-type and U/J
        // I-type
        id_ex_imm = $signed(if_id_instr[31:20]);
        id_ex_rs1_val = rf_rd1;
        id_ex_rs2_val = rf_rd2;
    end

    // EX stage: execute; includes small Zba custom decoding (opcode 0x7F)
    logic [63:0] alu_out_comb;
    logic mem_write_comb;
    logic mem_read_comb;
    
    always_comb begin
        // defaults
        alu_ctrl = 4'd0;
        alu_a = id_ex_rs1_val;
        alu_b = id_ex_rs2_val;
        mem_write_comb = 1'b0;
        mem_read_comb = 1'b0;
        alu_out_comb = 64'd0;

        // Zba custom family: opcode == 7'h7F
        if (id_ex_opcode == 7'h7F) begin
            // Treat as custom: use funct7 as sub-opcode
            unique case (id_ex_funct7)
                7'h12: begin // ZBA AG_ADD (R-type): rd = rs1 + rs2
                    alu_ctrl = 4'd0; // ADD
                    alu_out_comb = id_ex_rs1_val + id_ex_rs2_val;
                end
                default: begin
                    alu_ctrl = 4'd0;
                    alu_out_comb = id_ex_rs1_val + id_ex_rs2_val;
                end
            endcase
        end else begin
            // a small subset of RV64I encodings
            unique case (id_ex_opcode)
                7'h33: begin // R-type
                    // determine add/sub
                    if (id_ex_funct3 == 3'b000 && id_ex_funct7 == 7'b0000000) begin
                        alu_ctrl = 4'd0; // ADD
                        alu_out_comb = id_ex_rs1_val + id_ex_rs2_val;
                    end else if (id_ex_funct3 == 3'b000 && id_ex_funct7 == 7'b0100000) begin
                        alu_ctrl = 4'd1; // SUB
                        alu_out_comb = id_ex_rs1_val - id_ex_rs2_val;
                    end else begin
                        alu_ctrl = 4'd0;
                        alu_out_comb = id_ex_rs1_val + id_ex_rs2_val;
                    end
                end
                7'h13: begin // I-type ALU (addi)
                    alu_ctrl = 4'd0; // ADDI
                    alu_b = id_ex_imm;
                    alu_out_comb = id_ex_rs1_val + id_ex_imm;
                end
                7'h03: begin // loads (I-type)
                    alu_ctrl = 4'd0;
                    alu_out_comb = id_ex_rs1_val + id_ex_imm; // address
                    mem_read_comb = 1'b1;
                end
                7'h23: begin // stores (S-type)
                    automatic logic [11:0] imm_s;
                    alu_ctrl = 4'd0;
                    // S-type imm split: [31:25] imm[11:5], [11:7] imm[4:0]
                    imm_s = {if_id_instr[31:25], if_id_instr[11:7]};
                    alu_out_comb = id_ex_rs1_val + $signed(imm_s);
                    mem_write_comb = 1'b1;
                end
                7'h6F: begin // JAL
                    // write PC+4 into rd
                    alu_out_comb = if_id_pc + 4;
                end
                default: begin
                    alu_out_comb = 64'd0;
                end
            endcase
        end
    end

    // latch EX->MEM
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            ex_mem_rd <= 5'd0;
            ex_mem_alu_out <= 64'd0;
            ex_mem_mem_write <= 1'b0;
            ex_mem_mem_read <= 1'b0;
            ex_mem_rs2_val <= 64'd0;
        end else begin
            ex_mem_rd <= id_ex_rd;
            ex_mem_alu_out <= alu_out_comb;
            ex_mem_mem_write <= mem_write_comb;
            ex_mem_mem_read <= mem_read_comb;
            ex_mem_rs2_val <= id_ex_rs2_val;
        end
    end

    // Memory interface wiring
    assign dmem_addr = ex_mem_alu_out;
    assign dmem_wdata = ex_mem_rs2_val;
    assign dmem_wen = ex_mem_mem_write;
    assign dmem_ren = ex_mem_mem_read;

    // MEM stage
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_wb_rd <= 5'd0;
            mem_wb_lsu_data <= 64'd0;
            mem_wb_alu_out <= 64'd0;
            mem_wb_reg_write <= 1'b0;
        end else begin
            mem_wb_rd <= ex_mem_rd;
            mem_wb_alu_out <= ex_mem_alu_out;
            if (ex_mem_mem_read) mem_wb_lsu_data <= dmem_rdata;
            else mem_wb_lsu_data <= 64'd0;
            mem_wb_reg_write <= (ex_mem_rd != 5'd0);
        end
    end

    // WB stage: writeback to register file
    always_comb begin
        if (mem_wb_reg_write) begin
            // simple selection: if load then write load data else alu
            if (mem_wb_lsu_data != 64'd0) rf_wd = mem_wb_lsu_data;
            else rf_wd = mem_wb_alu_out;
        end else rf_wd = 64'd0;
        rf_we = mem_wb_reg_write;
    end

    // simple halt mechanism: if a store writes a special magic to address 0x200 -> stop
    // (the test program writes to dmem[0x100] to communicate results; testbench watches)

endmodule
