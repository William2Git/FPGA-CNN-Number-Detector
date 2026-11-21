module read_img (
    input CLOCK_50,
    input [9:0] SW,
    output [9:0] LEDR
);

    wire [7:0] pixel_value;

    image_rom img_rom (
        .address(SW[5:0]),
        .clock(CLOCK_50),
        .q(pixel_value)
    );

    assign LEDR[7:0] = pixel_value;
    assign LEDR[9:8] = 2'b00;

endmodule