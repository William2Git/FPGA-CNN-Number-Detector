module maxpool (A, B, C, D, result);

    input [15:0] A, B, C, D;
    output [15:0] result;
    wire [15:0] max1, max2;

    assign max1 = (A > B) ? A : B;
    assign max2 = (C > D) ? C : D;
    assign result = (max1 > max2) ? max1 : max2;

endmodule