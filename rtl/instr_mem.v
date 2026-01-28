`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.01.2026 21:48:36
// Design Name: 
// Module Name: instr_mem
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

// instr_mem.v - instruction memory

module instr_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 512) (
    input       [ADDR_WIDTH-1:0] instr_addr,
    output      [DATA_WIDTH-1:0] instr
);

// array of 64 32-bit words or instructions
reg [DATA_WIDTH-1:0] instr_ram [0:MEM_SIZE-1];

initial begin
    //$readmemh("rv32i_book.hex", instr_ram);
    //$readmemh("rv32i_test.hex", instr_ram);
    $readmemh("rv32i_test_2.hex", instr_ram);
    
end

// word-aligned memory access
// combinational read logic
assign instr = instr_ram[instr_addr[31:2]];    //used to get word adressing from byte 
                                               //addressing PC (we simply divide by 4 by ignoring lowest 2 bits)

endmodule
