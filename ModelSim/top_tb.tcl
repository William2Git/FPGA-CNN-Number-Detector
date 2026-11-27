# Run from the project root, where image.mif and weights.mif live.
if {![file exists expected_conv.hex]} {error "Run python verify_cnn.py from the project root first"}
if {![file isdirectory work]} {vlib work}
vmap work work
vlog adder.v multiplier.v accumulator.v image_rom.v weights_rom.v convolution.v top.v ModelSim/top_tb.v
vsim -voptargs=+acc -L altera_mf_ver work.top_tb
view wave
add wave sim:/top_tb/CLOCK_50 sim:/top_tb/KEY
add wave -radix unsigned sim:/top_tb/dut/img_counter sim:/top_tb/dut/rom_pixel sim:/top_tb/dut/conv_counter sim:/top_tb/dut/enable
add wave -radix unsigned sim:/top_tb/dut/c1/imageCounter sim:/top_tb/dut/c1/weight_addr sim:/top_tb/dut/c1/row sim:/top_tb/dut/c1/col
add wave -radix hexadecimal sim:/top_tb/dut/c1/weights_data sim:/top_tb/dut/c1/bias_32 sim:/top_tb/dut/c1/relu_out sim:/top_tb/dut/c1/finished
add wave -radix unsigned sim:/top_tb/errors
run -all
wave zoom full
