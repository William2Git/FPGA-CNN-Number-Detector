`timescale 1ns/1ps

module parameters_tb ( );
   reg CLOCK_50;
   reg  [9:0] SW;
   wire [9:0] LEDR;
   wire [6:0] HEX0, HEX1, HEX2, HEX3;

   integer i;

   //instantiate parameters module 
   parameters dut (
      .CLOCK_50 (CLOCK_50),
      .SW(SW),
      .LEDR(LEDR),
      .HEX0(HEX0),
      .HEX1(HEX1),
      .HEX2(HEX2),
      .HEX3(HEX3)
    );

   //generate a 50 MHz clock (20 ns period; 10 ns low, 10 ns high)
   initial begin
      CLOCK_50 = 0;
      forever #10 CLOCK_50 = ~CLOCK_50;
   end

   //sweep through all 410 ROM addresses (0 to 409)
   initial begin
		SW = 10'd0;

		for (i = 0; i < 410; i = i + 1) begin
			//change the address on the falling clock edge
			@(negedge CLOCK_50);
			SW = {1'b0, i[8:0]};

			//wait 2 rising clock edges so the synchronous ROM output settles
			//the ROM output should settle on 1 rising clock edge
			repeat (2) @(posedge CLOCK_50);
			#1;

			//print the address, LEDR value, 16-bit hex weight, signed decimal, and HEX bits
		   $display("Addr = %3d | LEDR = %3d | weight_data = %h | HEX3..0 = %b_%b_%b_%b",
                     i, LEDR[8:0], dut.weight_data, HEX3, HEX2, HEX1, HEX0);
	   end

		$display("Finished reading all 410 weights.");
		$stop;
   end

endmodule
