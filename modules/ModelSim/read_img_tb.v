
`timescale 1ns/1ps

module read_img_tb;

    reg CLOCK_50;
    reg [9:0] SW;
    wire [9:0] LEDR;

    integer i;

    // Instantiate your existing readimg module
    read_img dut (
        .CLOCK_50(CLOCK_50),
        .SW(SW),
        .LEDR(LEDR)
    );

    // Generate clock (10 ns period for simulation)
    initial begin
        CLOCK_50 = 0;
        forever #5 CLOCK_50 = ~CLOCK_50;
    end

    // Test all 64 ROM addresses
    initial begin
        SW = 10'b0;

        for (i = 0; i < 64; i = i + 1) begin

            // Change address at falling edge
            @(negedge CLOCK_50);
            SW[5:0] = i;

            // Wait for ROM to update
            repeat (2) @(posedge CLOCK_50);
            #1;

            // Display address and pixel value
            $display("Address = %0d | Pixel = %h | Decimal = %0d",
                     i, LEDR[7:0], LEDR[7:0]);
        end

        $display("Finished reading all 64 pixels.");
        $finish;
    end

endmodule
