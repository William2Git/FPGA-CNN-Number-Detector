module convolution (image, baseweight_addr, enable, CLOCK_50, featureMap, finished); 
	input [1023:0] image;
	input CLOCK_50;
	//the inputted weight address will be 0 for conv1, 9 for conv2, 18 for conv3, 27 for conv4
	input [8:0] baseweight_addr;
	input enable; //1 = run/load weights, 0 = reset imageCounter to 0
	
	output reg [575:0] featureMap; 
	//indicator that convolution is finished
	//36 bits x 16 so that we can get the 6x6 feature map
	output reg [35:0] finished;
	
	reg [8:0] weight_addr; 
	//only need 10 parameters (9 weights, 1 bias)
   wire signed [15:0] weights_data;  

   //instantiate Quartus ROM IP
	//weights_rom is synchronous on-chip memory block, so it only reads weight_addr on posedge clock
	//weights_data updates RIGHT AFTER the posedge
	//thus when we load into registers, we wait for second posedge
   weights_rom u_weights_rom (
      .address(weight_addr),
      .clock(CLOCK_50),
      .q(weights_data)
   );
	
	reg [143:0] weights;
	reg [15:0] bias;
	
	//need to count to 8 to retrieve all weights
	reg [3:0] imageCounter = 4'd0;

	//combination circuit to select ROM address
	always @(*) begin
		//default
		weight_addr = 9'd0;
		if(imageCounter < 4'd9)begin
			weight_addr = baseweight_addr + imageCounter;
		end
		else if(imageCounter == 4'd9) begin
			//count 9 gets the bias
			case (baseweight_addr)
				9'd0: weight_addr = 9'd36;
				9'd9: weight_addr = 9'd37;
				9'd18: weight_addr = 9'd38;
				9'd27: weight_addr = 9'd39;
				default: ;
			endcase
		end
	end

	//get all the weights from respective addresses
	always @ (posedge CLOCK_50)begin
		//whenever top.v changes enable to 0, that means we start new convolution
		//new convolution starts with imageCounter = 0
		if(!enable)begin
			imageCounter <= 4'd0;
		end
		else begin
			case(imageCounter)
			//it takes one clock cycle for the retrieved weights to appear on weights_data
				4'd0: begin
					//retrieve weights_data from first weight_addr for imageCounter = 0
					//don't store anything because weights_data doesn't have anything yet
					//imageCounter incremented to 1
					imageCounter <= imageCounter + 4'd1;
				end
				4'd1: begin
					//stores the first set of weights_data retrieved on first clock cycle
					//starts retreiving weights_data from the next address (imageCounter =1)
					//imageCounter incremented to 2
					weights[15:0] <= weights_data;
					imageCounter <= imageCounter + 4'd1;
				end
				4'd2: begin
					//stores second set (imageCounter =1)
					//starts retreieving from next address (imageCounter =2)
					//imageCounter incremented to 3
					weights[31:16] <= weights_data;
					imageCounter <= imageCounter + 4'd1;
				end
				4'd3: begin
					weights[47:32] <= weights_data;
					imageCounter <= imageCounter + 4'd1;
				end
				4'd4: begin
					weights[63:48] <= weights_data;
					imageCounter <= imageCounter + 4'd1;
				end
				4'd5: begin
					weights[79:64] <= weights_data;
					imageCounter <= imageCounter + 4'd1;
				end
				4'd6: begin
					weights[95:80] <= weights_data;
					imageCounter <= imageCounter + 4'd1;
				end
				4'd7: begin
					weights[111:96] <= weights_data;
					imageCounter <= imageCounter + 4'd1;
				end
				4'd8: begin
					weights[127:112] <= weights_data;
					imageCounter <= imageCounter + 4'd1;
				end 
				4'd9: begin
					//start retrieve bias
					weights[143:128] <= weights_data;
					imageCounter <= imageCounter + 4'd1;
				end
				4'd10: begin
					//store bias
					//don't retrieve anything
					bias <= weights_data;
					imageCounter <= imageCounter + 4'd1;
				end
				4'd11: begin
					//count to 12, so we know that each parameter is loaded (wait one extra clock cycle)
					imageCounter <= imageCounter + 4'd1;
				end
				default: ;
			endcase
		end
	
	end
	
	
	//convolution block
	//instantiate 9 multipliers, 1 accumulator
	wire [15:0] img [0:7][0:7];

	//store 1024 bit image vector in an 8x8 2D array, each entry is 16 bit Q8.8 pixel
	//genvar is a generate variable, only used by compiler to build circuit
	genvar r, c;
	//generate lets me repeat hardware connections outside always block
	generate
		for (r = 0; r < 8; r = r + 1) begin : unpack_row //unpack row and unpack col are mandatory for compiling
		//gives each module a hierachial name: unpack_row[0].unpack_col[0]
			for (c = 0; c < 8; c = c + 1) begin : unpack_col
				assign img[r][c] = image[(r * 8 + c) * 16 +: 16];
			end
		end
	endgenerate
	
	reg [2:0] row, col; //counts from 3'd1 to 3'd6
	wire [15:0] pixel1, pixel2, pixel3, pixel4, pixel5, pixel6, pixel7, pixel8, pixel9;
	//top row (row - 1)
	assign pixel1 = img[row - 3'd1][col - 3'd1]; //top left
	assign pixel2 = img[row - 3'd1][col];        //top middle
	assign pixel3 = img[row - 3'd1][col + 3'd1]; //top right

	//middle row (row)
	assign pixel4 = img[row][col - 3'd1];// middle left
	assign pixel5 = img[row][col]; //center
	assign pixel6 = img[row][col + 3'd1];// middle right

	//bottom row (row + 1)
	assign pixel7 = img[row + 3'd1][col - 3'd1];// bottom left
	assign pixel8 = img[row + 3'd1][col];// bottom middle
	assign pixel9 = img[row + 3'd1][col + 3'd1];// bottom right
	
	//products 
	wire [31:0] p1, p2, p3, p4, p5, p6, p7, p8, p9;
	
	multiplier m1 (
		.A(pixel1), //16 bit Q8.8
		.B(weights[15:0]), //16 bit Q8.8
		.product(p1), //32 bit Q16.16
		.result() //don't use 16 bit result to have higher accuracy by doing math w 32 bits
	);
	
	multiplier m2 (
		.A(pixel2), //16 bit Q8.8
		.B(weights[31:16]), //16 bit Q8.8
		.product(p2), //32 bit Q16.16
		.result() //don't use 16 bit result to have higher accuracy by doing math w 32 bits
	);
	
	multiplier m3 (
		.A(pixel3), //16 bit Q8.8
		.B(weights[47:32]), //16 bit Q8.8
		.product(p3), //32 bit Q16.16
		.result() //don't use 16 bit result to have higher accuracy by doing math w 32 bits
	);
	
	multiplier m4 (
		.A(pixel4), //16 bit Q8.8
		.B(weights[63:48]), //16 bit Q8.8
		.product(p4), //32 bit Q16.16
		.result() //don't use 16 bit result to have higher accuracy by doing math w 32 bits
	);
	
	multiplier m5(
		.A(pixel5), //16 bit Q8.8
		.B(weights[79:64]), //16 bit Q8.8
		.product(p5), //32 bit Q16.16
		.result() //don't use 16 bit result to have higher accuracy by doing math w 32 bits
	);
	
	multiplier m6 (
		.A(pixel6), //16 bit Q8.8
		.B(weights[95:80]), //16 bit Q8.8
		.product(p6), //32 bit Q16.16
		.result() //don't use 16 bit result to have higher accuracy by doing math w 32 bits
	);
	
	multiplier m7 (
		.A(pixel7), //16 bit Q8.8
		.B(weights[111:96]), //16 bit Q8.8
		.product(p7), //32 bit Q16.16
		.result() //don't use 16 bit result to have higher accuracy by doing math w 32 bits
	);
	
	multiplier m8 (
		.A(pixel8), //16 bit Q8.8
		.B(weights[127:112]), //16 bit Q8.8
		.product(p8), //32 bit Q16.16
		.result() //don't use 16 bit result to have higher accuracy by doing math w 32 bits
	);
	
	multiplier m9 (
		.A(pixel9), //16 bit Q8.8
		.B(weights[143:128]), //16 bit Q8.8
		.product(p9), //32 bit Q16.16
		.result() //don't use 16 bit result to have higher accuracy by doing math w 32 bits
	);
	
	
	//combinational circuit part (including multipliers above)
	//when imageCounter is 4'd12, our reLU will already have an output, so we can store it
	//and then immediately calculate the next value (using next set of pixels)
	wire [287:0] prod_288;
	assign prod_288 ={p9, p8, p7, p6, p5, p4, p3, p2, p1};
	
	wire[31:0] bias_32;
	//bit[23] is -128
	//by leading with eight 1s & bias[15] as 1, this simulates -128 using the new MSB
	//this is -(new MSB) + 8 more positive values = -128 if bit[15] is a 1
	//bit[15] is used twice to make -128 if bias[15] is a 1
	assign bias_32 = {{8{bias[15]}}, bias, 8'b0};
	wire [15:0] relu_out;
	
	//REMEMBER TO MAKE BIAS 32 BIT	
	accumrelu r1 (
		.products(prod_288), //nine 32bit products
		.bias(bias_32), //32 bit bias
		.out(), // raw 36 bit sum, unused
		.result(relu_out)//16 bit answer for one square on 6x6 feature map
	);
	
	//shift a 36-bit 1 hot code until its all zeroes to indicate finished
	//each clock cycle, i calculate a 9x9 and turn it into 1 value on the 6x6
	//each clock cycle, i change the address of what i feed into the adders and multipliers
	
	//feature map is 36 x 16 bits, so 576 bit vector
	//finished is a 36 bit 1 hot code
	always@(posedge CLOCK_50) begin
		if(!enable || imageCounter <4'd12)begin
			finished <= 36'd1;
			row <= 3'd1;
			col <= 3'd1;
		end
		else if(finished != 36'd0) begin
			//if the weights are done loading, we can start feeding into adders and multlipliers
			featureMap[16*(6*(row- 3'd1) + col - 3'd1)+:16]<= relu_out;
			if(row == 3'd7);
			else if(col==3'd6)begin
				col <= 3'd1;
				row <= row + 3'd1; 
			end
			else begin
				col <= col + 3'd1;
			end
			finished <= {finished[34:0], 1'b0};
		end
	end

endmodule