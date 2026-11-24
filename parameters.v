module parameters (CLOCK_50, SW, LEDR, HEX0, HEX1, HEX2, HEX3);
   input CLOCK_50;
   input [9:0] SW;
   output [9:0] LEDR;
   output [6:0] HEX0, HEX1, HEX2, HEX3;
	//9-bit address (0 to 409)
   wire [8:0] weight_addr;
	//16-bit Q8.8 signed parameter from weights.mif
   wire signed [15:0] weight_data;  

   //switches control which weight addresses we access and LEDR displays what address we call
   assign weight_addr = SW[8:0];
   assign LEDR = {1'b0, weight_addr};

   //instantiate Quartus ROM IP
   weights_rom u_weights_rom (
      .address(weight_addr),
      .clock(CLOCK_50),
      .q(weight_data)
   );

   //display 16 bits of the parameter in hex across HEX3 (MSB) to HEX0 (LSB)
   hex_to_7seg h0 (weight_data[3:0], HEX0);
   hex_to_7seg h1 (weight_data[7:4], HEX1);
   hex_to_7seg h2 (weight_data[11:8], HEX2);
   hex_to_7seg h3 (weight_data[15:12], HEX3);

endmodule

module hex_to_7seg (hex, seg);
   input [3:0] hex;
   output reg [6:0] seg;

   always @(*) begin
      case (hex)
			4'h0: seg = 7'b1000000;
			4'h1: seg = 7'b1111001;
			4'h2: seg = 7'b0100100;
			4'h3: seg = 7'b0110000;
			4'h4: seg = 7'b0011001;
			4'h5: seg = 7'b0010010;
			4'h6: seg = 7'b0000010;
			4'h7: seg = 7'b1111000;
			4'h8: seg = 7'b0000000;
			4'h9: seg = 7'b0010000;
			4'hA: seg = 7'b0001000;
			4'hB: seg = 7'b0000011;
			4'hC: seg = 7'b1000110;
			4'hD: seg = 7'b0100001;
			4'hE: seg = 7'b0000110;
			4'hF: seg = 7'b0001110;
		endcase
    end
endmodule