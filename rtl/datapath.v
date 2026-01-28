`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.01.2026 21:31:53
// Design Name: 
// Module Name: datapath
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// datapath.v - Pipelined version
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrcW,
    input         PCSrcE, ALUSrcE,
    input         RegWriteW, JumpE, JalrE,
    input [1:0]   ImmSrcD,
    input [3:0]   ALUControlE,
    input [1:0]   ForwardAE, ForwardBE,
    input         StallF, StallD, FlushD, FlushE,
    output        ZeroE, ALUR31E,
    output [31:0] PCF,
    input  [31:0] InstrF,
    output [31:0] ALUResultM, WriteDataM,
    input  [31:0] ReadDataM,
    output [31:0] InstrD,
    output [4:0]  Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
    output [31:0] ResultW
);

// ==================== FETCH STAGE ====================
wire [31:0] PCNextF, PCPlus4F, PCTargetE;

// PC register with enable (stall support)
reset_ff #(32) pcreg(clk, reset, StallF, PCNextF, PCF);

// PC+4 adder
adder pcadd4(PCF, 32'd4, PCPlus4F);

// PC source mux (branch/jump vs sequential)
mux2 #(32) pcmux(PCPlus4F, PCTargetE, PCSrcE, PCNextF);

// ==================== FETCH/DECODE PIPELINE REGISTER ====================
reg [31:0] InstrD_reg, PCD, PCPlus4D;

always @(posedge clk or posedge reset) begin
    if (reset || FlushD) begin
        InstrD_reg <= 32'b0;
        PCD        <= 32'b0;
        PCPlus4D   <= 32'b0;
    end else if (!StallD) begin
        InstrD_reg <= InstrF;
        PCD        <= PCF;
        PCPlus4D   <= PCPlus4F;
    end
end

assign InstrD = InstrD_reg;

// ==================== DECODE STAGE ====================
wire [31:0] RD1D, RD2D, ImmExtD;

// Extract register addresses
assign Rs1D = InstrD[19:15];
assign Rs2D = InstrD[24:20];
wire [4:0] RdD = InstrD[11:7];

// Register file (writes in WB stage)
//wire [31:0] ResultW;
reg_file rf(
    .clk(clk),
    .wr_en(RegWriteW),
    .rd_addr1(Rs1D),
    .rd_addr2(Rs2D),
    .wr_addr(RdW),
    .wr_data(ResultW),
    .rd_data1(RD1D),
    .rd_data2(RD2D)
);

// Immediate extend
imm_extend ext(InstrD[31:7], ImmSrcD, ImmExtD);

// ==================== DECODE/EXECUTE PIPELINE REGISTER ====================
reg [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
reg [4:0]  Rs1E_reg, Rs2E_reg, RdE_reg;
reg [31:0] InstrE; // Store instruction for funct3 (for loads/stores)

always @(posedge clk or posedge reset) begin
    if (reset || FlushE) begin
        RD1E     <= 32'b0;
        RD2E     <= 32'b0;
        PCE      <= 32'b0;
        ImmExtE  <= 32'b0;
        PCPlus4E <= 32'b0;
        Rs1E_reg <= 5'b0;
        Rs2E_reg <= 5'b0;
        RdE_reg  <= 5'b0;
        InstrE   <= 32'b0;
    end else begin
        RD1E     <= RD1D;
        RD2E     <= RD2D;
        PCE      <= PCD;
        ImmExtE  <= ImmExtD;
        PCPlus4E <= PCPlus4D;
        Rs1E_reg <= Rs1D;
        Rs2E_reg <= Rs2D;
        RdE_reg  <= RdD;
        InstrE   <= InstrD;
    end
end

assign Rs1E = Rs1E_reg;
assign Rs2E = Rs2E_reg;
assign RdE = RdE_reg;

// ==================== EXECUTE STAGE ====================
wire [31:0] SrcAE_fwd, SrcBE_fwd, SrcBE, WriteDataE_fwd;
wire [31:0] ALUResultE;

// Forwarding muxes (3-input: register file, Memory stage, Writeback stage)
mux3 #(32) forwardAmux(RD1E, ResultW, ALUResultM, ForwardAE, SrcAE_fwd);
mux3 #(32) forwardBmux(RD2E, ResultW, ALUResultM, ForwardBE, WriteDataE_fwd);

// ALU source B mux (register vs immediate)
mux2 #(32) srcbmux(WriteDataE_fwd, ImmExtE, ALUSrcE, SrcBE);

// ALU
alu alu_inst(SrcAE_fwd, SrcBE, ALUControlE, ALUResultE, ZeroE);

// For branches: BLT, BGE use ALU MSB
assign ALUR31E = ALUResultE[31];

// Branch/Jump target calculation
wire [31:0] PCTargetE_branch, PCTargetE_jalr;
adder pcaddbranch(PCE, ImmExtE, PCTargetE_branch);
adder pcaddjalr(SrcAE_fwd, ImmExtE, PCTargetE_jalr);

// Select between branch target and JALR target
mux2 #(32) pctargetmux(PCTargetE_branch, PCTargetE_jalr, JalrE, PCTargetE);

// AUIPC calculation
wire [31:0] AuiPCE, lAuiPCE;
wire [31:0] upperImmE = {InstrE[31:12], 12'b0};
adder #(32) auipcadder(upperImmE, PCE, AuiPCE);

// LUI vs AUIPC (bit 5 of opcode: LUI=0110111, AUIPC=0010111)
mux2 #(32) lauipcmux(AuiPCE, upperImmE, InstrE[5], lAuiPCE);

// ==================== EXECUTE/MEMORY PIPELINE REGISTER ====================
reg [31:0] ALUResultM_reg, WriteDataM_reg, PCPlus4M, lAuiPCM;
reg [4:0]  RdM_reg;
reg [31:0] InstrM;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        ALUResultM_reg <= 32'b0;
        WriteDataM_reg <= 32'b0;
        PCPlus4M       <= 32'b0;
        RdM_reg        <= 5'b0;
        lAuiPCM        <= 32'b0;
        InstrM         <= 32'b0;
    end else begin
        ALUResultM_reg <= ALUResultE;
        WriteDataM_reg <= WriteDataE_fwd;
        PCPlus4M       <= PCPlus4E;
        RdM_reg        <= RdE_reg;
        lAuiPCM        <= lAuiPCE;
        InstrM         <= InstrE;
    end
end

assign ALUResultM = ALUResultM_reg;
assign WriteDataM = WriteDataM_reg;
assign RdM = RdM_reg;

// ==================== MEMORY/WRITEBACK PIPELINE REGISTER ====================
reg [31:0] ALUResultW, ReadDataW, PCPlus4W, lAuiPCW;
reg [4:0]  RdW_reg;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        ALUResultW <= 32'b0;
        ReadDataW  <= 32'b0;
        PCPlus4W   <= 32'b0;
        RdW_reg    <= 5'b0;
        lAuiPCW    <= 32'b0;
    end else begin
        ALUResultW <= ALUResultM_reg;
        ReadDataW  <= ReadDataM;
        PCPlus4W   <= PCPlus4M;
        RdW_reg    <= RdM_reg;
        lAuiPCW    <= lAuiPCM;
    end
end

assign RdW = RdW_reg;

// ==================== WRITEBACK STAGE ====================
// Result mux: ALU result, Memory data, PC+4 (for JAL/JALR), or LUI/AUIPC
mux4 #(32) resultmux(ALUResultW, ReadDataW, PCPlus4W, lAuiPCW, ResultSrcW, ResultW);

endmodule


