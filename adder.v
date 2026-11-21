module carry_skip32 (A, B, Cin, S, Cout);
// creating a 32 carry_skip mux through 8 4 bit carry skip mux
    input [31:0] A, B; //num1 and 2
    input Cin; //carry in

    output reg [31:0] S; //ouput num
    output reg Cout;

    reg [32:0] C; //C0 to C16 connections
    reg [7:0] P; //block propagate signal, checks if all four inputs in a cascaded 8 FA are different
    integer k;

    always @(*) begin
        C = 33'b0;
        P = 8'b0;
        S = 32'b0;
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

        for (k = 0; k < 32; k = k + 1) 
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
        Cout = C[32];
    end
endmodule