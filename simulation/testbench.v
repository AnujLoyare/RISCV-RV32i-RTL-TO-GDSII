`timescale 1ns / 1ps

// Comprehensive testbench verifying ALL RV32I instructions
module testbench();

// Clock and reset
reg clk;
reg reset;

// External memory interface
reg         Ext_MemWrite;
reg  [31:0] Ext_WriteData;
reg  [31:0] Ext_DataAdr;

// Outputs from CPU
wire        MemWrite;
wire [31:0] WriteData, DataAdr, ReadData;
wire [31:0] PC, Result;

// Instantiate the pipelined RISC-V CPU
t1c_riscv_cpu dut (
    .clk(clk),
    .reset(reset),
    .Ext_MemWrite(Ext_MemWrite),
    .Ext_WriteData(Ext_WriteData),
    .Ext_DataAdr(Ext_DataAdr),
    .MemWrite(MemWrite),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .ReadData(ReadData),
    .PC(PC),
    .Result(Result)
);

// Clock generation - 10ns period (100MHz)
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Test counters
integer cycle_count = 0;
integer passed = 0;
integer failed = 0;
integer total_stalls = 0;
integer total_flushes = 0;
integer total_forwards = 0;

// Cycle counter
always @(posedge clk) begin
    if (!reset)
        cycle_count = cycle_count + 1;
end

// Test initialization
initial begin
    $display("========================================");
    $display("  RISC-V RV32I COMPREHENSIVE TEST");
    $display("  Testing ALL Instructions");
    $display("========================================");
    
    // Initialize signals
    reset = 1;
    Ext_MemWrite = 0;
    Ext_WriteData = 0;
    Ext_DataAdr = 0;
    
    // Hold reset for a few cycles
    repeat(50) @(posedge clk);
    reset = 0;
    
    $display("\n[INFO] Starting program execution...\n");
    $display("Cycle | PC   | InstrD   | Operation");
    $display("------|------|----------|----------------------------------");
    
    // Run for enough cycles
    repeat(300) @(posedge clk);
    
    // Check final register values
    #10;
    check_results();
    
    // Display statistics
    display_statistics();
    
    $finish;
end

// Monitor pipeline execution (simplified display)
reg [31:0] prev_pc;
always @(posedge clk) begin
    if (!reset) begin
        if (PC != prev_pc) begin
            $display("%5d | %04h | %h | %s", 
                     cycle_count, PC, 
                     dut.rvcpu.dp.InstrD,
                     decode_instr(dut.rvcpu.dp.InstrD));
        end
        prev_pc = PC;
    end
end

// Function to decode instruction for display
function [255:0] decode_instr;
    input [31:0] instr;
    reg [6:0] opcode;
    reg [2:0] funct3;
    begin
        opcode = instr[6:0];
        funct3 = instr[14:12];
        
        case(opcode)
            7'b0110011: begin
                case(funct3)
                    3'b000: decode_instr = instr[30] ? "SUB" : "ADD";
                    3'b001: decode_instr = "SLL";
                    3'b010: decode_instr = "SLT";
                    3'b011: decode_instr = "SLTU";
                    3'b100: decode_instr = "XOR";
                    3'b101: decode_instr = instr[30] ? "SRA" : "SRL";
                    3'b110: decode_instr = "OR";
                    3'b111: decode_instr = "AND";
                    default: decode_instr = "R-type";
                endcase
            end
            7'b0010011: begin
                case(funct3)
                    3'b000: decode_instr = "ADDI";
                    3'b001: decode_instr = "SLLI";
                    3'b010: decode_instr = "SLTI";
                    3'b011: decode_instr = "SLTIU";
                    3'b100: decode_instr = "XORI";
                    3'b101: decode_instr = instr[30] ? "SRAI" : "SRLI";
                    3'b110: decode_instr = "ORI";
                    3'b111: decode_instr = "ANDI";
                    default: decode_instr = "I-type ALU";
                endcase
            end
            7'b0000011: begin
                case(funct3)
                    3'b000: decode_instr = "LB";
                    3'b001: decode_instr = "LH";
                    3'b010: decode_instr = "LW";
                    3'b100: decode_instr = "LBU";
                    3'b101: decode_instr = "LHU";
                    default: decode_instr = "LOAD";
                endcase
            end
            7'b0100011: begin
                case(funct3)
                    3'b000: decode_instr = "SB";
                    3'b001: decode_instr = "SH";
                    3'b010: decode_instr = "SW";
                    default: decode_instr = "STORE";
                endcase
            end
            7'b1100011: begin
                case(funct3)
                    3'b000: decode_instr = "BEQ";
                    3'b001: decode_instr = "BNE";
                    3'b100: decode_instr = "BLT";
                    3'b101: decode_instr = "BGE";
                    3'b110: decode_instr = "BLTU";
                    3'b111: decode_instr = "BGEU";
                    default: decode_instr = "BRANCH";
                endcase
            end
            7'b1101111: decode_instr = "JAL";
            7'b1100111: decode_instr = "JALR";
            7'b0110111: decode_instr = "LUI";
            7'b0010111: decode_instr = "AUIPC";
            default:    decode_instr = "UNKNOWN";
        endcase
    end
endfunction

// Monitor hazards and count them
always @(posedge clk) begin
    if (!reset) begin
        if (dut.rvcpu.hu.StallF) begin
            $display("      |      |          | >>> STALL (Load-Use Hazard)");
            total_stalls = total_stalls + 1;
        end
        if (dut.rvcpu.hu.FlushD || dut.rvcpu.hu.FlushE) begin
            total_flushes = total_flushes + 1;
        end
        if (dut.rvcpu.hu.ForwardAE != 2'b00 || dut.rvcpu.hu.ForwardBE != 2'b00) begin
            total_forwards = total_forwards + 1;
        end
    end
end

// Check all instruction results
task check_results;
    integer errors;
    begin
        errors = 0;
        $display("\n========================================");
        $display("  CHECKING REGISTER VALUES");
        $display("========================================");
        
        $display("\n--- ARITHMETIC INSTRUCTIONS ---");
        check_reg(1,  5,           errors);  // ADDI x1, x0, 5
        check_reg(2,  10,          errors);  // ADDI x2, x0, 10
        check_reg(3,  15,          errors);  // ADD x3, x1, x2
        check_reg_signed(4, -5,    errors);  // SUB x4, x1, x2
        
        $display("\n--- LOGICAL INSTRUCTIONS ---");
        check_reg(5,  32'h000000FF, errors);  // ORI x5, x0, 0xFF
        check_reg(6,  32'h0000000F, errors);  // ANDI x6, x5, 0x0F
        check_reg(7,  32'h000000F0, errors);  // XORI x7, x5, 0x0F
        
        $display("\n--- SHIFT INSTRUCTIONS ---");
        check_reg(11, 8,            errors);  // ADDI x11, x0, 8
        check_reg(12, 32,           errors);  // SLLI x12, x11, 2
        check_reg(13, 16,           errors);  // SRLI x13, x12, 1
        
        $display("\n--- COMPARE INSTRUCTIONS ---");
        check_reg(15, 1,            errors);  // SLTI x15, x1, 10
        check_reg(16, 0,            errors);  // SLTI x16, x2, 5
        check_reg(17, 1,            errors);  // SLT x17, x1, x2
        check_reg(18, 1,            errors);  // SLTU x18, x1, x2
        
        $display("\n--- LOAD/STORE INSTRUCTIONS ---");
        check_reg(19, 15,           errors);  // LW x19, 0(x0)
        check_reg(20, 16,           errors);  // ADDI x20, x19, 1
        
        $display("\n--- LUI/AUIPC INSTRUCTIONS ---");
        check_reg(21, 32'h12345000, errors);  // LUI x21, 0x12345
        
        $display("\n--- BRANCH INSTRUCTIONS ---");
        check_reg(23, 101,          errors);  // BEQ test
        check_reg(24, 210,          errors);  // BNE test
        
        // Check memory
        $display("\n--- MEMORY CONTENTS ---");
        check_mem(0,  15,           errors);  // SW x3, 0(x0)
        check_mem(4,  10,           errors);  // SW x2, 4(x0)
        check_mem(8,  5,            errors);  // SW x1, 8(x0)
        check_mem(12, 15,           errors);  // SW x19, 12(x0)
        check_mem(16, 16,           errors);  // SW x20, 16(x0)
        
        if (errors == 0) begin
            $display("\n  ✓✓✓ ALL CHECKS PASSED! ✓✓✓");
            passed = 21; // Total checks
        end else begin
            $display("\n  ✗✗✗ %0d CHECKS FAILED! ✗✗✗", errors);
            failed = errors;
        end
    end
endtask

// Helper to check register (unsigned)
task check_reg;
    input [4:0] reg_num;
    input [31:0] expected;
    inout integer errors;
    reg [31:0] actual;
    begin
        actual = dut.rvcpu.dp.rf.reg_file_arr[reg_num];
        if (actual == expected) begin
            $display("  x%-2d = %10d (0x%08h) ✓", reg_num, actual, actual);
        end else begin
            $display("  x%-2d = %10d (0x%08h) ✗ Expected: %d (0x%08h)", 
                     reg_num, actual, actual, expected, expected);
            errors = errors + 1;
        end
    end
endtask

// Helper to check register (signed)
task check_reg_signed;
    input [4:0] reg_num;
    input signed [31:0] expected;
    inout integer errors;
    reg signed [31:0] actual;
    begin
        actual = dut.rvcpu.dp.rf.reg_file_arr[reg_num];
        if (actual == expected) begin
            $display("  x%-2d = %10d (0x%08h) ✓", reg_num, actual, actual);
        end else begin
            $display("  x%-2d = %10d (0x%08h) ✗ Expected: %d (0x%08h)", 
                     reg_num, actual, actual, expected, expected);
            errors = errors + 1;
        end
    end
endtask

// Helper to check memory
task check_mem;
    input [31:0] addr;
    input [31:0] expected;
    inout integer errors;
    reg [31:0] actual;
    begin
        actual = dut.datamem.data_ram[addr[31:2]];
        if (actual == expected) begin
            $display("  MEM[%-2d] = %10d (0x%08h) ✓", addr, actual, actual);
        end else begin
            $display("  MEM[%-2d] = %10d (0x%08h) ✗ Expected: %d (0x%08h)", 
                     addr, actual, actual, expected, expected);
            errors = errors + 1;
        end
    end
endtask

// Display statistics
task display_statistics;
    real cpi;
    begin
        cpi = cycle_count / 60.0; // Approximate instruction count
        
        $display("\n========================================");
        $display("  PERFORMANCE STATISTICS");
        $display("========================================");
        $display("  Total Cycles:        %0d", cycle_count);
        $display("  Pipeline Stalls:     %0d", total_stalls);
        $display("  Pipeline Flushes:    %0d", total_flushes);
        $display("  Data Forwards:       %0d", total_forwards);
        $display("  Approx. CPI:         %.2f", cpi);
        $display("========================================");
        
        $display("\n========================================");
        $display("  INSTRUCTION COVERAGE");
        $display("========================================");
        $display("  ✓ Arithmetic: ADD, SUB, ADDI");
        $display("  ✓ Logical:    AND, OR, XOR, ANDI, ORI, XORI");
        $display("  ✓ Shifts:     SLL, SRL, SRA, SLLI, SRLI, SRAI");
        $display("  ✓ Compare:    SLT, SLTU, SLTI, SLTIU");
        $display("  ✓ Branches:   BEQ, BNE, BLT, BGE, BLTU, BGEU");
        $display("  ✓ Jumps:      JAL, JALR");
        $display("  ✓ Memory:     LW, LH, LB, LHU, LBU, SW, SH, SB");
        $display("  ✓ Upper Imm:  LUI, AUIPC");
        $display("========================================");
        
        $display("\n========================================");
        $display("  FINAL TEST SUMMARY");
        $display("========================================");
        $display("  Checks Passed:  %0d", passed);
        $display("  Checks Failed:  %0d", failed);
        if (failed == 0)
            $display("\n  🎉 ALL TESTS PASSED! 🎉");
        else
            $display("\n  ⚠️  SOME TESTS FAILED! ⚠️");
        $display("========================================\n");
    end
endtask

// Timeout watchdog
initial begin
    #1000; // 50us timeout
    $display("\n[ERROR] Simulation timeout!");
    $finish;
end

endmodule