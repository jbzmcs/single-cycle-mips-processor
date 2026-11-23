module zero_extender #(parameter IN_WIDTH = 16, parameter OUT_WIDTH = 32) (
    input  [IN_WIDTH-1:0]  in,
    output [OUT_WIDTH-1:0] out
);
    assign out = {{(OUT_WIDTH-IN_WIDTH){1'b0}}, in};
endmodule
