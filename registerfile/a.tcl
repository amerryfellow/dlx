vcom -reportprogress 300 -work work /home/microsystem14.23/labs/lab3/tb_wrf.vhd
vsim -t 100ps -novopt work.tbwrf
add waves *
add wave -r /*
run 20 ns
