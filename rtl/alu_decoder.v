`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.01.2026 21:54:38
// Design Name: 
// Module Name: alu_decoder
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

// alu_decoder.v - logic for ALU decoder

module alu_decoder (
    input            opb5,
    input [2:0]      funct3,
    input            funct7b5,
    input [1:0]      ALUOp,
    output reg [3:0] ALUControl
);

always @(*) begin
    case (ALUOp)
        2'b00: ALUControl = 4'b0000;             // addition
        2'b01: ALUControl = 4'b0001;             // subtraction
        default:
            case (funct3) // R-type or I-type ALU
                3'b000: begin
                    // True for R-type subtract
                    if   (funct7b5 & opb5) ALUControl = 4'b0001; //sub
                    else ALUControl = 4'b0000; // add, addi
                end
                3'b010:  ALUControl = 4'b0101; // slt, slti
                3'b110:  ALUControl = 4'b0011; // or, ori
                3'b111:  ALUControl = 4'b0010; // and, andi
                3'b100:  ALUControl = 4'b0100; // xor, xori
                3'b001:  if(!(funct7b5)) ALUControl = 4'b1000; // sll, slli
                3'b101:  begin
                            if(!(funct7b5)) ALUControl = 4'b1111; // srl, srli
                            else ALUControl = 4'b1001; // sra, srai
                        end
                3'b011:  ALUControl = 4'b0111; // sltu, sltiu
                default: ALUControl = 4'bxxxx; // ???
            endcase
    endcase
end

endmodule

