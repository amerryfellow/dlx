vcom -reportprogress 300 -work work packages/cuTypes.vhd
vcom -reportprogress 300 -work work packages/constants.vhd
vcom -reportprogress 300 -work work packages/rocache.vhd
vcom -reportprogress 300 -work work packages/rwcache.vhd
vcom -reportprogress 300 -work work packages/aluTypes.vhd
vcom -reportprogress 300 -work work rocache/romem.vhd
vcom -reportprogress 300 -work work rocache/rocache.vhd
vcom -reportprogress 300 -work work cu/cu.vhd
vcom -reportprogress 300 -work work basics/halfadder.vhd
vcom -reportprogress 300 -work work basics/inc.vhd
vcom -reportprogress 300 -work work basics/latch.vhd
vcom -reportprogress 300 -work work basics/flipflop.vhd
vcom -reportprogress 300 -work work basics/register.vhd
vcom -reportprogress 300 -work work basics/register_fde.vhd
vcom -reportprogress 300 -work work basics/fulladder.vhd
vcom -reportprogress 300 -work work basics/rca_generic.vhd
vcom -reportprogress 300 -work work basics/sgnext.vhd
vcom -reportprogress 300 -work work basics/mux.vhd
vcom -reportprogress 300 -work work basics/wrf_nomem.vhd
vcom -reportprogress 300 -work work basics/inverter.vhd
vcom -reportprogress 300 -work work basics/nand3to1.vhd
vcom -reportprogress 300 -work work basics/and2to1.vhd
vcom -reportprogress 300 -work work basics/nor2to1.vhd
vcom -reportprogress 300 -work work basics/nor32to1.vhd
vcom -reportprogress 300 -work work basics/mux4to1.vhd
vcom -reportprogress 300 -work work alu/bitwise/T2logic.vhd
vcom -reportprogress 300 -work work alu/comparator/comparator.vhd
vcom -reportprogress 300 -work work alu/adder/sumgenerator/csb.vhd
vcom -reportprogress 300 -work work alu/adder/sumgenerator/sumgenerator.vhd
vcom -reportprogress 300 -work work alu/adder/carrygenerator/init_pg.vhd
vcom -reportprogress 300 -work work alu/adder/carrygenerator/tree_g.vhd
vcom -reportprogress 300 -work work alu/adder/carrygenerator/tree_pg.vhd
vcom -reportprogress 300 -work work alu/adder/carrygenerator/tree.vhd
vcom -reportprogress 300 -work work alu/adder/p4adder.vhd
vcom -reportprogress 300 -work work alu/shifter/barrelshifter.vhd
vcom -reportprogress 300 -work work alu/alu.vhd
vcom -reportprogress 300 -work work rwcache/rwmem.vhd
vcom -reportprogress 300 -work work rwcache/rwcache.vhd
vcom -reportprogress 300 -work work dlx.vhd
vcom -reportprogress 300 -work work testbench.vhd
vsim work.DLX_TB
add wave -position insertpoint sim:/DLX_TB/*
add wave -position insertpoint sim:/DLX_TB/GIANLUCA/*
add wave -position insertpoint sim:/DLX_TB/DRAM/*
run 1500 ns
