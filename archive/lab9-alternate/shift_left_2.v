module shift_left_2 #(parameter WIDTH = 32) (
    input  [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);
    assign out = {in[WIDTH-3:0], 2'b00};
endmodule
