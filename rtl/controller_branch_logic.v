`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.01.2026 18:21:30
// Design Name: 
// Module Name: controller_branch_logic
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


// ==================== BRANCH LOGIC MODULE ====================
// This handles the branch decision that was in main_decoder
module controller_branch_logic (
    input [2:0]  funct3,
    input        Zero,
    input        ALUR31,
    input [6:0]  op,
    output reg   Branch
);

always @(*) begin
    Branch = 0;
    if (op == 7'b1100011) begin // Branch instruction
        case (funct3)
            3'b000: Branch = Zero;      // BEQ
            3'b001: Branch = !Zero;     // BNE
            3'b100: Branch = ALUR31;    // BLT
            3'b101: Branch = !ALUR31;   // BGE
            3'b110: Branch = ALUR31;    // BLTU
            3'b111: Branch = !ALUR31;   // BGEU
            default: Branch = 0;
        endcase
    end
end

endmodule