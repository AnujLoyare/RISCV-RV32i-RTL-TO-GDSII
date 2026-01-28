`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.01.2026 22:02:49
// Design Name: 
// Module Name: reset_ff
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

// reset_ff.v - 8-bit resettable D flip-flop

module reset_ff #(parameter WIDTH = 8) (
    input       clk, rst,en,
    input       [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);

always @(posedge clk or posedge rst) begin
    if (rst) q <= 0;
    else if(!en)    q <= d;
end

endmodule



