`timescale 1ns/1ps

// ============================================================
//  Register File Testbench
//
//  Tests:
//    1. Basic write then read back
//    2. Simultaneous read from two different registers
//    3. Write Enable = 0 does NOT update the register
//    4. $zero (register 0) is hardwired to 0 — write is ignored
// ============================================================

module register_file_tb();

    // ---- DUT Inputs ----
    reg        clk;
    reg        reset;
    reg        RegWrite_in;
    reg [4:0]  WriteReg_in;
    reg [31:0] WriteData_in;
    reg [4:0]  ReadReg1_in;
    reg [4:0]  ReadReg2_in;

    // ---- DUT Outputs ----
    wire [31:0] ReadData1_out;
    wire [31:0] ReadData2_out;

    // ---- Instantiate the register file ----
    register_file DUT (
        .clk          (clk),
        .reset        (reset),
        .RegWrite_in  (RegWrite_in),
        .WriteReg_in  (WriteReg_in),
        .WriteData_in (WriteData_in),
        .ReadReg1_in  (ReadReg1_in),
        .ReadReg2_in  (ReadReg2_in),
        .ReadData1_out(ReadData1_out),
        .ReadData2_out(ReadData2_out)
    );

    // ---- 100 MHz clock ----
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // ---- Stimulus ----
    initial begin
        // --- Reset ---
        reset       = 1;
        RegWrite_in = 0;
        WriteReg_in = 0;
        WriteData_in= 0;
        ReadReg1_in = 0;
        ReadReg2_in = 0;
        @(posedge clk); #1;
        reset = 0;

        // ============================================================
        // TEST 1: Write 0xAAAAAAAA to register $t0 (reg 8), read back
        // ============================================================
        WriteReg_in  = 5'd8;
        WriteData_in = 32'hAAAAAAAA;
        RegWrite_in  = 1;
        @(posedge clk); #1;   // write commits on this edge
        RegWrite_in  = 0;

        ReadReg1_in  = 5'd8;
        #1;
        $display("TEST 1 – Write 0xAAAAAAAA to $t0, read back:");
        $display("  ReadData1 = 0x%08h  (expected 0xAAAAAAAA) %s",
                 ReadData1_out,
                 ReadData1_out == 32'hAAAAAAAA ? "PASS" : "FAIL");

        // ============================================================
        // TEST 2: Write 0x12345678 to $t1 (reg 9), simultaneous read
        //         $t0 on port 1,  $t1 on port 2
        // ============================================================
        WriteReg_in  = 5'd9;
        WriteData_in = 32'h12345678;
        RegWrite_in  = 1;
        @(posedge clk); #1;
        RegWrite_in  = 0;

        ReadReg1_in  = 5'd8;   // $t0 = 0xAAAAAAAA
        ReadReg2_in  = 5'd9;   // $t1 = 0x12345678
        #1;
        $display("\nTEST 2 – Simultaneous read: $t0 on port1, $t1 on port2:");
        $display("  ReadData1 = 0x%08h  (expected 0xAAAAAAAA) %s",
                 ReadData1_out,
                 ReadData1_out == 32'hAAAAAAAA ? "PASS" : "FAIL");
        $display("  ReadData2 = 0x%08h  (expected 0x12345678) %s",
                 ReadData2_out,
                 ReadData2_out == 32'h12345678 ? "PASS" : "FAIL");

        // ============================================================
        // TEST 3: RegWrite = 0 — write should NOT happen
        // ============================================================
        WriteReg_in  = 5'd8;
        WriteData_in = 32'hDEADBEEF;
        RegWrite_in  = 0;           // write disabled
        @(posedge clk); #1;

        ReadReg1_in  = 5'd8;
        #1;
        $display("\nTEST 3 – RegWrite=0: $t0 should NOT change:");
        $display("  ReadData1 = 0x%08h  (expected 0xAAAAAAAA) %s",
                 ReadData1_out,
                 ReadData1_out == 32'hAAAAAAAA ? "PASS" : "FAIL");

        // ============================================================
        // TEST 4: Write to $zero (reg 0) — must always read back 0
        // ============================================================
        WriteReg_in  = 5'd0;
        WriteData_in = 32'hFFFFFFFF;
        RegWrite_in  = 1;
        @(posedge clk); #1;
        RegWrite_in  = 0;

        ReadReg1_in  = 5'd0;
        #1;
        $display("\nTEST 4 – Write to $zero (reg 0), must read back 0:");
        $display("  ReadData1 = 0x%08h  (expected 0x00000000) %s",
                 ReadData1_out,
                 ReadData1_out == 32'h00000000 ? "PASS" : "FAIL");

        // ============================================================
        $display("\n-- Testbench complete --");
        $stop;
    end

endmodule
