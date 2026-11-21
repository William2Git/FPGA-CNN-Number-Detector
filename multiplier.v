
module multiplier(A, B, product,result);
	input signed [15:0] A, B; //Q8.8 numbers, automatic 2 bit complement
    output signed [31:0] product;
    output reg signed [15:0] result;
	 //in signed bit, the MSB if 1 will be treated as a negative, so 11010 is -16 + 8 + 0 + 2 + 0 = -6
	 //or 2 compliments 00101 +1 = 00110

    // Sign-extend A from 16 to 32 bits
	 wire signed [31:0] A_ext;//extending A to 32 bits q1, how is it extended is stuff just added to the left
	 assign A_ext = A; //signed mean the MSB will be extended automatically

    // 16 partial-product rows
    wire [31:0] pp [0:15]; //16 partial products, each having 32 bits

    // Intermediate results of adder tree
    wire [31:0] stage1 [0:7];
    wire [31:0] stage2 [0:3];
    wire [31:0] stage3 [0:1];

    wire signed [31:0] scaled;

    genvar i;

    //And gate logic from class
    generate
        for (i = 0; i < 16; i = i + 1)//calculate all partial sums
        begin
           assign pp[i] = B[i] ? (A_ext << i) : 32'b0;//shift by i to the left to be placed correctly
        end
    endgenerate
    //16 rows -> 8 sums
    generate
        for (i = 0; i < 8; i = i + 1) 
        begin
            if (i == 7) //last 2 rows, last row is negative
            begin
                // B[15] is negative 
                // pp[14] - pp[15]
                carry_skip32 adder (
                    .A(pp[14]),
                    .B(~pp[15]),
                    .Cin(1'b1),
                    .S(stage1[i]),
                    .Cout()
                ); // this is substration since now our cin is 1 and we take the NOT of 15 2^n-k-1 +1

            end
            else 
            begin// first 7 sums are all normal additions

                carry_skip32 adder (
                    .A(pp[2*i]),
                    .B(pp[2*i+1]),
                    .Cin(1'b0),
                    .S(stage1[i]),
                    .Cout()
                );

            end
        end
    endgenerate
	//All sums are already in their respective 2 bit complement form after the first time, so can just treat them with normal addition
    //8 sums -> 4 sums
    generate
        for (i = 0; i < 4; i = i + 1) 
        begin

            carry_skip32 adder (
                .A(stage1[2*i]),
                .B(stage1[2*i+1]),
                .Cin(1'b0),
                .S(stage2[i]),
                .Cout()
            );

        end
    endgenerate

    //4 sums -> 2 sums
    generate
        for (i = 0; i < 2; i = i + 1)
        begin

            carry_skip32 adder (
                .A(stage2[2*i]),
                .B(stage2[2*i+1]),
                .Cin(1'b0),
                .S(stage3[i]),
                .Cout()
            );

        end
    endgenerate

    //2 sums -> final product
    carry_skip32 final_adder (
        .A(stage3[0]),
        .B(stage3[1]),
        .Cin(1'b0),
        .S(product),
        .Cout()
    );

    // Convert Q16.16 to Q8.8 because 256a * 256b has 256^2 and we only want the ratio to be 256
    assign scaled = product >>> 8;

    // Check for overflow and limit to max stored
    always @(*) begin //we don't want to treat a value that takes up all the 16 bits number as a negative
        if (scaled > 32'sd32767) //2^15-1
            result = 16'sh7FFF; //largest possible hexadecimal
        else if (scaled < -32'sd32768) //2^15
            result = 16'sh8000; //smallest possible hexadecimal
        else
            result = scaled[15:0];
    end
endmodule
