`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.01.2026 21:44:01
// Design Name: 
// Module Name: t1c_riscv_cpu
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


// t1c_riscv_cpu.v - Pipelined version top module
module t1c_riscv_cpu (
    input         clk, reset,
    input         Ext_MemWrite,
    input  [31:0] Ext_WriteData, Ext_DataAdr,
    output        MemWrite,
    output [31:0] WriteData, DataAdr, ReadData,
    output [31:0] PC, Result
);

wire [31:0] Instr;
wire [31:0] DataAdr_rv32, WriteData_rv32;
wire        MemWrite_rv32;

// Instantiate pipelined processor
riscv_cpu rvcpu (
    .clk(clk),
    .reset(reset),
    .PC(PC),
    .Instr(Instr),
    .MemWrite(MemWrite_rv32),
    .Mem_WrAddr(DataAdr_rv32),
    .Mem_WrData(WriteData_rv32),
    .ReadData(ReadData),
    .Result(Result)
);

// Instruction memory
instr_mem instrmem (
    .instr_addr(PC),
    .instr(Instr)
);

// Data memory  
// Note: We need to pass funct3 to data memory for byte/halfword operations
// In pipelined version, this comes from the Memory stage
wire [2:0] funct3M;
pipeline_funct3_tracker funct3_track(
    .clk(clk),
    .reset(reset),
    .InstrF(Instr),
    .funct3M(funct3M)
);

data_mem datamem (
    .clk(clk),
    .wr_en(MemWrite),
    .funct3(funct3M),
    .wr_addr(DataAdr),
    .wr_data(WriteData),
    .rd_data_mem(ReadData)
);

// External memory access during reset (for program loading)
assign MemWrite  = (Ext_MemWrite && reset) ? 1 : MemWrite_rv32;
assign WriteData = (Ext_MemWrite && reset) ? Ext_WriteData : WriteData_rv32;
assign DataAdr   = reset ? Ext_DataAdr : DataAdr_rv32;

endmodule

