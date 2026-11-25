module accumrelu(products, bias, out, result);
    input[287:0] products;
    input signed [31:0] bias;
    output signed [35:0] out;
    output wire signed [15:0] result;
    genvar i,k;
    wire signed [35:0] p [0:9];
    wire [35:0] stage1 [0:4];
    wire [35:0] stage2 [0:2];
    wire [35:0] stage3 [0:1];
    wire signed [35:0] scaled;
    //cut and save 1d array products into seperated signed numbers to be added
    generate
        for (i = 0; i < 9; i = i + 1)
        begin
            assign p[i] = $signed(products[i*32 +: 32]); //starting from i*32 until the width is 32 bits, then sign extend to 36 bits
        end
    endgenerate
    assign p[9] = $signed(bias);
    // 10->5
    generate
        for(k = 0; k < 5; k = k + 1)
        begin
                carry_skip36 adder (
                    .A(p[2*k]),
                    .B(p[2*k+1]),
                    .Cin(1'b0),
                    .S(stage1[k]),
                    .Cout()
                );
        end
    endgenerate
    // 5->3
    generate
        for(k = 0; k < 2; k = k + 1)
        begin
                carry_skip36 adder (
                    .A(stage1[2*k]),
                    .B(stage1[2*k+1]),
                    .Cin(1'b0),
                    .S(stage2[k]),
                    .Cout()
                );
        end
        assign stage2[2] = stage1[4];
    endgenerate
    //3->2
    generate
        for(k = 0; k < 1; k = k + 1)
        begin
                carry_skip36 adder (
                    .A(stage2[2*k]),
                    .B(stage2[2*k+1]),
                    .Cin(1'b0),
                    .S(stage3[k]),
                    .Cout()
                );
        end
        assign stage3[1] = stage2[2];
    endgenerate
    //2->1
    carry_skip36 adder (
                    .A(stage3[0]),
                    .B(stage3[1]),
                    .Cin(1'b0),
                    .S(out),
                    .Cout()
                );

    // divide by 256 back to Q8.8 format
    assign scaled = out >>> 8;

    // ReLU + overflow + width reduction
    assign result = out[35] ? 16'sd0 : //check msb if 1 means neg become 0
                (scaled > 36'sd32767) ? 16'sh7FFF :scaled[15:0]; //checks pos overflow if none then pass
endmodule


module carry_skip36 (A, B, Cin, S, Cout);
// creating a 32 carry_skip mux through 8 4 bit carry skip mux
    input [35:0] A, B; //num1 and 2
    input Cin; //carry in

    output reg [35:0] S; //ouput num
    output reg Cout;

    reg [36:0] C; //C0 to C16 connections
    reg [8:0] P; //block propagate signal, checks if all four inputs in a cascaded 8 FA are different
    integer k;

    always @(*) begin
        C = 37'b0;
        P = 9'b0;
        S = 36'b0;
        C[0] = Cin;

        // Block propagate signals
        P[0] = (A[3:0]  ^ B[3:0])   == 4'b1111;
        P[1] = (A[7:4]  ^ B[7:4])   == 4'b1111;
        P[2] = (A[11:8] ^ B[11:8])  == 4'b1111;
        P[3] = (A[15:12] ^ B[15:12]) == 4'b1111;
        P[4] = (A[19:16] ^ B[19:16]) == 4'b1111;
        P[5] = (A[23:20] ^ B[23:20]) == 4'b1111;
        P[6] = (A[27:24] ^ B[27:24]) == 4'b1111;
        P[7] = (A[31:28] ^ B[31:28]) == 4'b1111;
        P[8] = (A[35:32] ^ B[35:32]) == 4'b1111;

        for (k = 0; k < 36; k = k + 1) 
		  begin
            // Full-adder sum
           S[k] = A[k] ^ B[k] ^ C[k];
            // Normal carry
           if (A[k] == B[k])
                C[k+1] = B[k]; //0+0 -> 0, 1+1 -> 1
           else
                C[k+1] = C[k];//0+1 -> 1+1-> 1, follows cin
            // Check at the end of each 4-bit block if we can skip
           if (k % 4 == 3)
				begin
                if (P[k/4])
                    C[k+1] = C[k-3];
                end
        end
        Cout = C[36];
    end
endmodule