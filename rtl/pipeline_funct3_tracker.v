`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.01.2026 18:27:10
// Design Name: 
// Module Name: pipeline_funct3_tracker
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


// ==================== FUNCT3 PIPELINE TRACKER ====================
// This module tracks funct3 through the pipeline to Memory stage
// for proper byte/halfword load/store operations
module pipeline_funct3_tracker (
    input         clk, reset,
    input  [31:0] InstrF,
    output [2:0]  funct3M
);

reg [2:0] funct3D, funct3E, funct3M_reg;

// Decode stage
always @(posedge clk or posedge reset) begin
    if (reset)
        funct3D <= 0;
    else
        funct3D <= InstrF[14:12];
end

// Execute stage
always @(posedge clk or posedge reset) begin
    if (reset)
        funct3E <= 0;
    else
        funct3E <= funct3D;
end

// Memory stage
always @(posedge clk or posedge reset) begin
    if (reset)
        funct3M_reg <= 0;
    else
        funct3M_reg <= funct3E;
end

assign funct3M = funct3M_reg;

endmodule