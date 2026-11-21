
`timescale 1ns/1ps

module multiplier_tb;

    reg signed [15:0] A, B;
    wire signed [31:0] product;
    wire signed [15:0] result;

    integer test_number;

    // Instantiate our multiplier
    multiplier dut (
        .A(A),
        .B(B),
        .product(product),
        .result(result)
    );

    // Task to test a pair of inputs
    task test;
        input signed [15:0] a_input, b_input;
        begin
            A = a_input;
            B = b_input;

            // Allow combinational outputs to settle
            #20;

            test_number = test_number + 1;

        end
    endtask

    initial 
    begin
        test_number = 0;
        A = 0;
        B = 0;
        // Positive x positive
        test(16'sd384, 16'sd512);     // 1.5 x 2.0
        test(16'sd128, 16'sd128);     // 0.5 x 0.5
        // Negative x positive
        test(-16'sd384, 16'sd512);    // -1.5 x 2.0
        // Positive x negative
        test(16'sd256, -16'sd256);    // 1.0 x -1.0
        // Negative x negative
        test(-16'sd384, -16'sd192);   // -1.5 x -0.75
        // Zero
        test(16'sd0, 16'sd512);       // 0 x 2.0
        // Very small numbers: precision loss
        test(16'sd1, 16'sd1);         // (1/256) x (1/256)
        // Positive overflow after Q8.8 conversion
        test(16'sd25600, 16'sd512);   // 100 x 2
        // Negative overflow after Q8.8 conversion
        test(-16'sd25600, 16'sd512);  // -100 x 2
        // Positive 16-bit signed limit
        test(16'sh7FFF, 16'sd256);    // Max positive x 1
        // Negative 16-bit signed limit
        test(16'sh8000, 16'sd256);    // -128 x 1
        // Two extreme negative inputs
        test(16'sh8000, 16'sh8000);   // -128 x -128
        $stop;
    end

endmodule
