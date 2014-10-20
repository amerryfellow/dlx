vcom -reportprogress 300 -work work packages/cuTypes.vhd
vcom -reportprogress 300 -work work packages/constants.vhd
vcom -reportprogress 300 -work work packages/cache.vhd
vcom -reportprogress 300 -work work icache/romem.vhd
vcom -reportprogress 300 -work work icache/rocache.vhd
vcom -reportprogress 300 -work work cu/cu.vhd
vcom -reportprogress 300 -work work alu/adder/carrygenerator/init_pg.vhd
vcom -reportprogress 300 -work work basics/inc.vhd
vcom -reportprogress 300 -work work basics/latch.vhd
vcom -reportprogress 300 -work work basics/flipflop.vhd
vcom -reportprogress 300 -work work basics/register.vhd
vcom -reportprogress 300 -work work cu/cu_icache_iram.vhd
vsim work.cu_test
add wave -position insertpoint sim:/cu_test/*
add wave -position insertpoint sim:/cu_test/dut/LUTOUT \
sim:/cu_test/dut/PIPE1 \
sim:/cu_test/dut/PIPE2 \
sim:/cu_test/dut/PIPE3 \
sim:/cu_test/dut/PIPE4 \
sim:/cu_test/dut/PIPE5 \
sim:/cu_test/dut/PIPEREG12 \
sim:/cu_test/dut/PIPEREG23 \
sim:/cu_test/dut/PIPEREG34 \
sim:/cu_test/dut/PIPEREG45
run 500 ns
