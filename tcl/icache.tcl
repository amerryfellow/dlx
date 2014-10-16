vcom -reportprogress 300 -work work icache/cache_cost.vhd
vcom -reportprogress 300 -work work icache/IRAM.vhd
vcom -reportprogress 300 -work work icache/icache.vhd
vcom -reportprogress 300 -work work icache/prova1.vhd
vsim work.tbcache
add wave -radix hexadecimal -position insertpoint sim:/tbcache/IRAM_G/*
add wave -radix hexadecimal -position insertpoint sim:/tbcache/IC_MEM_G/*
run 200 ns
