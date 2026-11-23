module program_counter(
    input clk,
    input reset,
    input [31:0] next_pc,
    output reg [31:0] current_pc
);
    always @(posedge clk) begin
        if (reset)
            current_pc <= 32'h00400000; // Standard MIPS Text Segment Start
        else
            current_pc <= next_pc;
    end
endmodule