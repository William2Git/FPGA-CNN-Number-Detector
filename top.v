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
	reg [6:0] img_counter;
	
	//image address depends on counter
	//everytime counter changes, we call different address, stored into pixel_q8_8
	assign img_addr = img_counter[5:0]; //only goes up to 63
	always @ (posedge CLOCK_50)begin
		if(~KEY[0]) img_counter <= 7'd0;
		//count to 65, because we data only appears at output on the next clock edge
		else if(img_counter < 7'd65)begin
			//allows the memory block to retrieve pixels from addresses 0-63
			
			//+: is indexed part-select operator
			//[starting index +: width]
			
			//counter =0: nothing happens, counter =1: write to [15:0]
			//counter = 64: write to [1023:1008]
			//storing into image happens one clock cycle after we retrieve the memory from address
			//this staggering lets pixel_q8_8 actually have the memory value 
			//(because storage happens after one clock cycle)
			if(img_counter>7'd0) image[(img_counter-7'd1)*16 +: 16] <= pixel_q8_8;
			img_counter <= img_counter + 7'd1;
			//once counter reaches 65, we know the output is stored
		end
	end
	
	
	//FSM to control if which stage of calculation we are in
	
	
	//instantiate convolution module with image values
	//output 6x6 feature map
	
	
	//will figure out FSM later; we can have one big convolution state, one big pooling state, etc
	
	//Combinational circuit
	reg enable = 1'b0;
	wire [575:0] tempMap_6x6;
	reg [575:0] map1_6x6, map2_6x6, map3_6x6, map4_6x6;
	wire [35:0] finished;
	reg [2:0] conv_counter = 3'd0;
	
	reg [8:0] baseweight_addr = 9'd0;
	convolution c1 (
		.image(image),
		.baseweight_addr(baseweight_addr),
		.enable(enable),
		.CLOCK_50(CLOCK_50),
		.featureMap(tempMap_6x6),
		.finished(finished)
	);
	
	always @(*) begin
		case(conv_counter)
			3'd0: baseweight_addr = 9'd0;
			3'd1: baseweight_addr = 9'd9;
			3'd2: baseweight_addr = 9'd18;
			3'd3: baseweight_addr = 9'd27;
			default: baseweight_addr = 9'd0;
		endcase
	end
	
	//depending on which convolution it is, we store it in the correct place
	//toggle enable to trigger the retrieving of new parameters for new convolutions
	//reset the finished signal
	always @(posedge CLOCK_50)begin
		if(~KEY[0]) begin
			conv_counter <= 3'd0;
			enable <= 1'b0;
		end
		//convolutions are done
		else if(conv_counter == 3'd4) enable <= 1'b0;
		else if(enable && finished == 36'd0)begin
			//finished resets to decimal 1 in convolution module on next clock edge
			enable <= 1'b0;
			case(conv_counter)
				3'd0: begin
					map1_6x6 <= tempMap_6x6;
					conv_counter <= conv_counter +1;
				end
				3'd1: begin
					map2_6x6 <= tempMap_6x6;
					conv_counter <= conv_counter +1;
				end
				3'd2: begin
					map3_6x6 <= tempMap_6x6;
					conv_counter <= conv_counter +1;
				end
				3'd3: begin
					map4_6x6 <= tempMap_6x6;
					conv_counter <= conv_counter +1;
				end
				default: ;
			endcase
		end
		//only enable convolution when image is done loading and it is not being reset
		else if(img_counter == 7'd65 && KEY[0]) enable <= 1'b1;
		else enable <= 1'b0;
	end
	
	
	//instantiate max pooling module with 6x6 feature map
	//output 3x3 feature map
	
	//instantiate fully connected module
	
	

endmodule