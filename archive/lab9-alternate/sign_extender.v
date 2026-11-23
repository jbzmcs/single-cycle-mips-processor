module sign_extender(
    input [15:0] in,
    output [31:0] out
);
    // Replicate the sign bit (MSB) 16 times and concatenate
    assign out = {{16{in[15]}}, in}; 
endmodule