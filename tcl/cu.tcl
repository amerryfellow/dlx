cd /home/gandalf/Documents/Universita/Postgrad/Modules/Microelectronic/dlx
vcom -reportprogress 300 -work work packages/cuTypes.vhd
vcom -reportprogress 300 -work work cu/cu.vhd
vcom -reportprogress 300 -work work cu/testbench.vhd
vsim work.cu_test
add wave -position insertpoint sim:/cu_test/*
run 200 ns
