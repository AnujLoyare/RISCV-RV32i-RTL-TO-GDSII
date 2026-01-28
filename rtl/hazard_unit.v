`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.01.2026 17:29:57
// Design Name: 
// Module Name: hazard_unit
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

// hazard_unit.v
module hazard_unit (
    // Inputs from different pipeline stages
    input [4:0]  Rs1D, Rs2D,      // Source registers in Decode stage
    input [4:0]  Rs1E, Rs2E,      // Source registers in Execute stage
    input [4:0]  RdE,              // Destination register in Execute stage
    input [4:0]  RdM,              // Destination register in Memory stage
    input [4:0]  RdW,              // Destination register in Writeback stage
    input        PCSrcE,           // Branch/Jump taken signal
    input [1:0]  ResultSrcE,       // Result source in Execute (for load detection)
    input        RegWriteM,        // Register write enable in Memory stage
    input        RegWriteW,        // Register write enable in Writeback stage
    
    // Outputs - Control signals for hazard handling
    output reg [1:0] ForwardAE,    // Forwarding control for ALU input A
    output reg [1:0] ForwardBE,    // Forwarding control for ALU input B
    output       StallF,           // Stall Fetch stage
    output       StallD,           // Stall Decode stage
    output       FlushD,           // Flush Decode stage
    output       FlushE            // Flush Execute stage
);

// ========== Forwarding Logic ==========
// ForwardAE control (for source register 1 in Execute stage)
always @(*) begin
    // Priority: Memory stage forwarding > Writeback stage forwarding > No forwarding
    if (((Rs1E == RdM) && RegWriteM) && (Rs1E != 0))
        ForwardAE = 2'b10;  // Forward from Memory stage (ALUResultM)
    else if (((Rs1E == RdW) && RegWriteW) && (Rs1E != 0))
        ForwardAE = 2'b01;  // Forward from Writeback stage (ResultW)
    else
        ForwardAE = 2'b00;  // No forwarding (use register file output)
end

// ForwardBE control (for source register 2 in Execute stage)
always @(*) begin
    // Priority: Memory stage forwarding > Writeback stage forwarding > No forwarding
    if (((Rs2E == RdM) && RegWriteM) && (Rs2E != 0))
        ForwardBE = 2'b10;  // Forward from Memory stage (ALUResultM)
    else if (((Rs2E == RdW) && RegWriteW) && (Rs2E != 0))
        ForwardBE = 2'b01;  // Forward from Writeback stage (ResultW)
    else
        ForwardBE = 2'b00;  // No forwarding (use register file output)
end

// ========== Load-Use Hazard Detection ==========
// Detect when a load instruction in Execute stage is followed by
// an instruction that uses the loaded value in Decode stage
// ResultSrcE == 2'b01 indicates a load instruction
wire lwStall;
assign lwStall = (ResultSrcE == 2'b01) && ((Rs1D == RdE) || (Rs2D == RdE));

// ========== Stall and Flush Signals ==========
assign StallF = lwStall;           // Stall PC register (prevent new instruction fetch)
assign StallD = lwStall;           // Stall Decode pipeline register (keep current instruction)

assign FlushD = PCSrcE;            // Flush Decode on control hazard (branch/jump taken)
assign FlushE = lwStall || PCSrcE; // Flush Execute on load-use or control hazard (insert bubble)

endmodule