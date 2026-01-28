`timescale 1ns / 1ps

module tb();
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
    // Clock: 10ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset
    initial begin
        reset = 1;
        repeat(10) @(posedge clk);
        reset = 0;
    end

    // Run & check
//    initial begin
//        $display("\n=================================");
//        $display("   ADDI INSTRUCTION TEST");
//        $display("=================================\n");

//        repeat(30) @(posedge clk);

//        check_reg(1, 32'd5);
//        check_reg(2, 32'd10);
//        check_reg(3, 32'd2);
//        check_reg(4, 32'd17);
//        check_reg(5, 32'd14);

//        $display("\n✅ ADDI TEST PASSED");
//        $finish;
//    end
    
    // Test
    initial begin
        $display("\n=================================");
        $display("     AUIPC INSTRUCTION TEST");
        $display("=================================\n");

        repeat(30) @(posedge clk);

        check_reg(1, 32'h00001000);
        check_reg(2, 32'h00002004);
        check_reg(3, 32'hFFFFF008);
        check_reg(4, 32'h0000000C);

        $display("\n✅ AUIPC TEST PASSED");
        $finish;
    end


    // Simple checker
    task check_reg;
        input [4:0] regnum;
        input [31:0] expected;
        reg   [31:0] actual;
        begin
            actual = dut.rvcpu.dp.rf.reg_file_arr[regnum];
            if (actual !== expected) begin
                $display("❌ x%0d = %0d (expected %0d)", regnum, actual, expected);
                $finish;
            end else begin
                $display("✔ x%0d = %0d", regnum, actual);
            end
        end
    endtask

endmodule
