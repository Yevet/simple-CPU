
module signext(
    input  [15:0] a,
    input  [1:0] op,
    output [31:0] y
);
    
    assign y=( op == 2'b11 ) ? { {16{1'b0}},a } : {{16{a[15]}}, a}; 

endmodule
