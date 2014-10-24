vcom -reportprogress 300 -work work packages/rwcache.vhd
vcom -reportprogress 300 -work work rwcache/romem.vhd
vcom -reportprogress 300 -work work rwcache/rwcache.vhd
vcom -reportprogress 300 -work work rwcache/testbench.vhd
vsim work.tbcache
add wave -position insertpoint *
add wave -position insertpoint sim:/tbcache/IRAM_G/*
add wave -position insertpoint sim:/tbcache/IC_MEM_G/*
run 500 ns
