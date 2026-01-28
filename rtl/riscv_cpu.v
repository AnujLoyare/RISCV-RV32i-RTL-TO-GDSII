`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.01.2026 21:45:14
// Design Name: 
// Module Name: riscv_cpu
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

// riscv_cpu.v - Pipelined version
module riscv_cpu (
    input         clk, reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result
);

// ==================== Control Signals ====================
// Decode stage
wire       RegWriteD, MemWriteD, JumpD, JalrD, ALUSrcD;
wire [1:0] ResultSrcD, ImmSrcD, ALUOpD;
wire [3:0] ALUControlD;

// Execute stage  
wire       RegWriteE, MemWriteE, JumpE, JalrE, ALUSrcE;
wire [1:0] ResultSrcE;
wire [3:0] ALUControlE;

// Memory stage
wire       RegWriteM, MemWriteM_wire;
wire [1:0] ResultSrcM;

// Writeback stage
wire       RegWriteW;
wire [1:0] ResultSrcW;

// ==================== Hazard Unit Signals ====================
wire [1:0] ForwardAE, ForwardBE;
wire       StallF, StallD, FlushD, FlushE;
wire       PCSrcE, ZeroE, ALUR31E;

// ==================== Datapath Signals ====================
wire [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;
wire [31:0] InstrD;
wire [31:0] ResultW;

// ==================== CONTROLLER (Decode Stage) ====================
controller c (
    .op(InstrD[6:0]),
    .funct3(InstrD[14:12]),
    .funct7b5(InstrD[30]),
    .Zero(ZeroE),
    .ALUR31(ALUR31E),
    .ResultSrc(ResultSrcD),
    .MemWrite(MemWriteD),
    .PCSrc(/* Not used in pipelined - computed in Execute */),
    .ALUSrc(ALUSrcD),
    .RegWrite(RegWriteD),
    .Jump(JumpD),
    .Jalr(JalrD),
    .ImmSrc(ImmSrcD),
    .ALUControl(ALUControlD)
);

// ==================== DATAPATH ====================
datapath dp (
    .clk(clk),
    .reset(reset),
    .ResultSrcW(ResultSrcW),
    .PCSrcE(PCSrcE),
    .ALUSrcE(ALUSrcE),
    .RegWriteW(RegWriteW),
    .JumpE(JumpE),
    .JalrE(JalrE),
    .ImmSrcD(ImmSrcD),
    .ALUControlE(ALUControlE),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE),
    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .ZeroE(ZeroE),
    .ALUR31E(ALUR31E),
    .PCF(PC),
    .InstrF(Instr),
    .ALUResultM(Mem_WrAddr),
    .WriteDataM(Mem_WrData),
    .ReadDataM(ReadData),
    .InstrD(InstrD),
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .RdM(RdM),
    .RdW(RdW),
    .ResultW(ResultW)
);

// ==================== HAZARD UNIT ====================
hazard_unit hu (
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .RdM(RdM),
    .RdW(RdW),
    .PCSrcE(PCSrcE),
    .ResultSrcE(ResultSrcE),
    .RegWriteM(RegWriteM),
    .RegWriteW(RegWriteW),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE),
    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .FlushE(FlushE)
);

// ==================== PIPELINE REGISTERS FOR CONTROL SIGNALS ====================

// Decode -> Execute
reg       RegWriteE_reg, MemWriteE_reg, JumpE_reg, JalrE_reg, ALUSrcE_reg;
reg [1:0] ResultSrcE_reg;
reg [3:0] ALUControlE_reg;

always @(posedge clk or posedge reset) begin
    if (reset || FlushE) begin
        RegWriteE_reg   <= 0;
        MemWriteE_reg   <= 0;
        JumpE_reg       <= 0;
        JalrE_reg       <= 0;
        ALUSrcE_reg     <= 0;
        ResultSrcE_reg  <= 0;
        ALUControlE_reg <= 0;
    end else begin
        RegWriteE_reg   <= RegWriteD;
        MemWriteE_reg   <= MemWriteD;
        JumpE_reg       <= JumpD;
        JalrE_reg       <= JalrD;
        ALUSrcE_reg     <= ALUSrcD;
        ResultSrcE_reg  <= ResultSrcD;
        ALUControlE_reg <= ALUControlD;
    end
end

assign RegWriteE   = RegWriteE_reg;
assign MemWriteE   = MemWriteE_reg;
assign JumpE       = JumpE_reg;
assign JalrE       = JalrE_reg;
assign ALUSrcE     = ALUSrcE_reg;
assign ResultSrcE  = ResultSrcE_reg;
assign ALUControlE = ALUControlE_reg;

// Branch decision logic in Execute stage
wire BranchE;
reg [2:0] funct3E;
reg [6:0] opE;

// Pipeline funct3 and op for branch decision
always @(posedge clk or posedge reset) begin
    if (reset || FlushE) begin
        funct3E <= 0;
        opE     <= 0;
    end else begin
        funct3E <= InstrD[14:12];
        opE     <= InstrD[6:0];
    end
end

controller_branch_logic branch_logic(
    .funct3(funct3E),
    .Zero(ZeroE),
    .ALUR31(ALUR31E),
    .op(opE),
    .Branch(BranchE)
);

// PCSrc decision in Execute stage
assign PCSrcE = JumpE | JalrE | BranchE;

// Execute -> Memory
reg       RegWriteM_reg, MemWriteM_reg;
reg [1:0] ResultSrcM_reg;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        RegWriteM_reg  <= 0;
        MemWriteM_reg  <= 0;
        ResultSrcM_reg <= 0;
    end else begin
        RegWriteM_reg  <= RegWriteE;
        MemWriteM_reg  <= MemWriteE;
        ResultSrcM_reg <= ResultSrcE;
    end
end

assign RegWriteM  = RegWriteM_reg;
assign MemWriteM_wire = MemWriteM_reg;
assign ResultSrcM = ResultSrcM_reg;
assign MemWrite   = MemWriteM_wire;

// Memory -> Writeback
reg       RegWriteW_reg;
reg [1:0] ResultSrcW_reg;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        RegWriteW_reg  <= 0;
        ResultSrcW_reg <= 0;
    end else begin
        RegWriteW_reg  <= RegWriteM;
        ResultSrcW_reg <= ResultSrcM;
    end
end

assign RegWriteW  = RegWriteW_reg;
assign ResultSrcW = ResultSrcW_reg;

// Result output (for external monitoring)
assign Result = ResultW;

endmodule