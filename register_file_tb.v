`timescale 1ns / 1ps

module register_file_tb;

    // Inputs to the Unit Under Test (UUT) are declared as 'reg' in TB
    reg clk;
    reg reset;
    reg RegWrite_in;
    reg [4:0] WriteReg_in;
    reg [31:0] WriteData_in;
    reg [4:0] ReadReg1_in;
    reg [4:0] ReadReg2_in;

    // Outputs from the UUT are declared as 'wire' in TB
    wire [31:0] ReadData1_out;
    wire [31:0] ReadData2_out;

    // Instantiate the Unit Under Test (UUT)
    register_file uut (
        .clk(clk), 
        .reset(reset), 
        .RegWrite_in(RegWrite_in), 
        .WriteReg_in(WriteReg_in), 
        .WriteData_in(WriteData_in), 
        .ReadReg1_in(ReadReg1_in), 
        .ReadData1_out(ReadData1_out), 
        .ReadReg2_in(ReadReg2_in), 
        .ReadData2_out(ReadData2_out)
    );

    // --- Clock Generation ---
    // This creates a clock with a period of 20ns (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // Toggle clock every 10ns
    end

    // --- Stimulus Process ---
    initial begin
        // 1. Initialize Inputs
        reset = 1;
        RegWrite_in = 0;
        WriteReg_in = 0;
        WriteData_in = 0;
        ReadReg1_in = 0;
        ReadReg2_in = 0;

        // Wait 100 ns for global reset to finish
        #100;
        reset = 0; // Release reset
        #20;

        // --- Test Case 1: Write to Register 8 ($t0) ---
        $display("Test 1: Writing 0xAAAA5555 to Register 8");
        WriteReg_in = 5'd8;         // Target Register 8
        WriteData_in = 32'hAAAA5555; // Data to write
        RegWrite_in = 1;            // Enable write
        #20; // Wait for a clock edge to occur
        RegWrite_in = 0;            // Disable write
        #20;

        // --- Test Case 2: Read back from Register 8 AND Read Register 0 ---
        $display("Test 2: Reading Register 8 and Register 0");
        ReadReg1_in = 5'd8; // Read port 1 looks at Reg 8
        ReadReg2_in = 5'd0; // Read port 2 looks at Reg 0
        #20;
        // Verify results in console
        $display("  Expected: R8=aaaa5555, R0=00000000");
        $display("  Got:      R8=%h, R0=%h", ReadData1_out, ReadData2_out);
        if (ReadData1_out == 32'hAAAA5555 && ReadData2_out == 32'h00000000)
            $display("  SUCCESS: Reads correct.");
        else
            $display("  FAILURE: Reads incorrect.");


        // --- Test Case 3: Attempt to Write to Register 0 ---
        $display("Test 3: Attempting to write 0xFFFFFFFF to Register 0");
        WriteReg_in = 5'd0;          // Target Register 0
        WriteData_in = 32'hFFFFFFFF; // Try to write all 1s
        RegWrite_in = 1;             // Enable write
        #20; // Wait for clock edge
        RegWrite_in = 0;
        #20;

        // --- Test Case 4: Verify Register 0 is still Zero ---
        $display("Test 4: Reading Register 0 back");
        ReadReg1_in = 5'd0;
        #20;
        $display("  Expected: R0=00000000");
        $display("  Got:      R0=%h", ReadData1_out);
        if (ReadData1_out == 32'h00000000)
            $display("  SUCCESS: Register 0 write ignored.");
        else
            $display("  FAILURE: Register 0 was written to!");

        // End simulation
        #100;
        $stop;
    end
      
endmodule 