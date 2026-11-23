module program_counter #(
    parameter RESET_ADDR = 32'h003FFFFC
)(
    input        clk,
    input        reset,
    input  [31:0] next_pc,
    output reg [31:0] current_pc
);
    always @(posedge clk) begin
        if (reset)
            current_pc <= RESET_ADDR;
        else
            current_pc <= next_pc;
    end
endmodule
