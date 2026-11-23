module register_file(
    // Synchronous Write Ports
    input clk,                    // Clock signal for synchronous write
    input reset,                  // Reset signal
    input RegWrite_in,            // Write Enable signal
    input [4:0] WriteReg_in,      // 5-bit register address for write (R0-R31)
    input [31:0] WriteData_in,    // 32-bit data to write

    // Asynchronous Read Ports
    input [4:0] ReadReg1_in,      // 5-bit register address 1
    output [31:0] ReadData1_out,  // 32-bit data output 1
    input [4:0] ReadReg2_in,      // 5-bit register address 2
    output [31:0] ReadData2_out   // 32-bit data output 2
);
    // Declare the Register Array: 32 elements, each 32 bits wide
    reg [31:0] registers [0:31];

    // 1. Asynchronous Read Logic (Combinational)
    assign ReadData1_out = (ReadReg1_in == 5'b00000) ? 32'h00000000 : registers[ReadReg1_in];
    assign ReadData2_out = (ReadReg2_in == 5'b00000) ? 32'h00000000 : registers[ReadReg2_in];

    // 2. Synchronous Write Logic (Sequential)
    always @(posedge clk) begin
        if (RegWrite_in && WriteReg_in != 5'b00000)
            registers[WriteReg_in] <= WriteData_in;
    end
endmodule
