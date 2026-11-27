`timescale 1ns/1ps
module top_tb;
    reg CLOCK_50 = 0;
    reg [9:0] SW = 0;
    reg [0:0] KEY = 0;
    wire [9:0] LEDR;
    wire [6:0] HEX0;
    reg [15:0] expected [0:143];
    reg [575:0] maps [0:3];
    integer k, i, errors;

    top dut (.CLOCK_50(CLOCK_50), .SW(SW), .KEY(KEY),
             .LEDR(LEDR), .HEX0(HEX0));
    always #10 CLOCK_50 = ~CLOCK_50;

    initial begin
        $readmemh("expected_conv.hex", expected);
        errors = 0;
        repeat (3) @(negedge CLOCK_50);
        KEY = 1;
        wait (dut.conv_counter == 3'd4);
        #1;
        maps[0] = dut.map1_6x6;
        maps[1] = dut.map2_6x6;
        maps[2] = dut.map3_6x6;
        maps[3] = dut.map4_6x6;
        for (k = 0; k < 4; k = k + 1) begin
            for (i = 0; i < 36; i = i + 1) begin
                if ((^expected[k*36+i] === 1'bx) ||
                    (maps[k][i*16 +: 16] !== expected[k*36+i])) begin
                    errors = errors + 1;
                    $display("FAIL filter=%0d row=%0d col=%0d actual=%h expected=%h",
                             k+1, i/6, i%6, maps[k][i*16 +: 16], expected[k*36+i]);
                end
            end
        end
        $display("Passed %0d/144; errors=%0d", 144-errors, errors);
        $stop;
    end
    initial begin
        #20000;
        $display("FAIL: timeout waiting for four convolution maps");
        $stop;
    end
endmodule
