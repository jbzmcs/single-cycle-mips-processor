module mux_2input #(parameter WIDTH = 32) (
    input [WIDTH-1:0] in0, 
    input [WIDTH-1:0] in1, 
    input sel,
    output [WIDTH-1:0] out
);
    // If sel is 1, choose in1. Else choose in0.
    assign out = (sel) ? in1 : in0;
endmodule