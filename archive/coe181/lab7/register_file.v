module register_file(
	input 				clk,
	input 				reset,
	input 				RegWrite_in,
	input 	[4:0] 	WriteReg_in,
	input 	[31:0] 	WriteData_in,
	
	input 	[4:0] 	ReadReg1_in,
	output 	[31:0] 	ReadData1_out,
	
	input 	[4:0]		ReadReg2_in,
	output	[31:0]	ReadData2_out
);

	reg [31:0] registers [0:31];
	
	// Asyonchronous reads, $0 hardwired to 0
	assign ReadData1_out = (ReadReg1_in == 5'b0) ? 32'b0 : registers[ReadReg1_in];
	assign ReadData2_out = (ReadReg2_in == 5'b0) ? 32'b0 : registers[ReadReg2_in];
	
	// Synchronous write
	always @(posedge clk) begin
		if (RegWrite_in && (WriteReg_in != 5'b0)) begin
			registers[WriteReg_in] <= WriteData_in;
			end
		end
endmodule
