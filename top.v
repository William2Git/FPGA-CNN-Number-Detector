module top(SW, LEDR, HEX0, KEY, CLOCK_50);
	input [9:0] SW;
	output [9:0] LEDR;
	output [6:0] HEX0;
	input CLOCK_50;
	// NEXT STEP SELF NOTE: swith control with mux to determine which image ROM we want to access
	
	
	//KEY[0] is used for reset
	input [0:0]KEY;
	//store all image pixels, to use whenever
	reg [1023:0] image;
	
	// 0 to 63, address of pixel we want to get the value of
	wire [5:0] img_addr;
	// VALUE OF ONE PIXEL
	// 8-bit pixel value (0 to 255) from image_rom, represented by two HEXADECIMAL in image.mif
	wire [7:0] rom_pixel;
	//16 bit signed Q8.8 pixel (0 to 0.9961)
	wire signed [15:0] pixel_q8_8;

	//instantiate image_rom block, it can only retrieve 1 address per clock cycle
	//image block has 1-cycle ROM read latency; after you read on a clock edge, the corresponding
	//data only appears at the output on the next clock edge
	// thus we need 65 clock cycles to retrieve 64 pixels
	image_rom u_image_rom (
		 .address (img_addr),
		 .clock   (CLOCK_50),
		 .q       (rom_pixel)
	);
	// convert 8-bit pixel to 16 bit signed Q8.8
	assign pixel_q8_8 = {8'b0, rom_pixel};
	reg [6:0] counter;
	
	assign img_addr = counter[5:0];
	always @ (posedge CLOCK_50)begin
		if(~KEY[0]) counter <= 7'd0;
		//count to 65, because we data only appears at output on the next clock edge
		else if(counter < 7'd65)begin
			//allows the memory block to retrieve pixels from addresses 0-63
			
			//+: is indexed part-select operator
			//[starting index +: width]
			
			//counter =0: nothing happens, counter =1: write to [15:0]
			//counter = 64: write to [1023:1008]
			if(counter>7'd0) image[(counter-7'd1)*16 +: 16] <= pixel_q8_8;
			counter <= counter + 7'd1;
			//once counter reaches 65, we know the output is stored
		end
	end
	
	//instantiate convolution module with image values
	//output 6x6 feature map
	
	//instantiate max pooling module with 6x6 feature map
	//output 3x3 feature map
	
	//instantiate fully connected module

endmodule