`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.01.2026 21:49:34
// Design Name: 
// Module Name: data_mem
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

// data_mem.v - data memory

module data_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 64) (
    input       clk, wr_en,
	 input [2:0] funct3,
    input       [ADDR_WIDTH-1:0] wr_addr, wr_data,
    output    reg  [DATA_WIDTH-1:0] rd_data_mem
);

// array of 64 32-bit words or data
reg [DATA_WIDTH-1:0] data_ram [0:MEM_SIZE-1];

wire [ADDR_WIDTH-1:0] word_addr = wr_addr[ADDR_WIDTH-1:2] % 64;

always @(posedge clk) begin
	 if (wr_en) begin
        case (funct3[1:0])
            2'b00: begin // SB 
                case (wr_addr[1:0])
                    2'b00: data_ram[word_addr] <= (data_ram[word_addr] & 32'hFFFFFF00) | (wr_data[7:0] << 0);   
                    2'b01: data_ram[word_addr] <= (data_ram[word_addr] & 32'hFFFF00FF) | (wr_data[7:0] << 8);   
                    2'b10: data_ram[word_addr] <= (data_ram[word_addr] & 32'hFF00FFFF) | (wr_data[7:0] << 16);  
                    2'b11: data_ram[word_addr] <= (data_ram[word_addr] & 32'h00FFFFFF) | (wr_data[7:0] << 24);  
                endcase
            end
            2'b01: begin // SH 
                case (wr_addr[1])
                    1'b0: data_ram[word_addr] <= (data_ram[word_addr] & 32'hFFFF0000) | (wr_data[15:0] << 0);   // Lower Halfword
                    1'b1: data_ram[word_addr] <= (data_ram[word_addr] & 32'h0000FFFF) | (wr_data[15:0] << 16);  // Upper Halfword
                endcase
            end
            default: data_ram[word_addr] <= wr_data;  // SW (Store Word)
        endcase
    end
end


always @(*) begin
    rd_data_mem = data_ram[word_addr]; 
    case (funct3[1:0])
        2'b00: begin  // LB 
            case (wr_addr[1:0])
                2'b00: rd_data_mem = {{24{~funct3[2] & data_ram[word_addr][7]}}, data_ram[word_addr][7:0]};  // Byte 0
                2'b01: rd_data_mem = {{24{~funct3[2] & data_ram[word_addr][15]}}, data_ram[word_addr][15:8]}; // Byte 1
                2'b10: rd_data_mem = {{24{~funct3[2] & data_ram[word_addr][23]}}, data_ram[word_addr][23:16]}; // Byte 2
                2'b11: rd_data_mem = {{24{~funct3[2] & data_ram[word_addr][31]}}, data_ram[word_addr][31:24]}; // Byte 3
            endcase
        end
        2'b01: begin  // LH 
            case (wr_addr[1])
                1'b0: rd_data_mem = {{16{~funct3[2] & data_ram[word_addr][15]}}, data_ram[word_addr][15:0]};   // Lower Halfword
                1'b1: rd_data_mem = {{16{~funct3[2] & data_ram[word_addr][31]}}, data_ram[word_addr][31:16]};  // Upper Halfword
            endcase
        end
        default: rd_data_mem = data_ram[word_addr]; // Default full word read for SW
    endcase
end

endmodule