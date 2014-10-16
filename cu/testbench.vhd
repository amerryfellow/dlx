library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.cu.all;

entity cu_test is
	end cu_test;

architecture TEST of cu_test is
	component CU_UP is
		port (
		-- Inputs
				Clk :				in std_logic;		-- Clock
				Rst :				in std_logic;		-- Reset:Active-Low
				IR  :				in std_logic_vector(31 downto 0);
				JMP_PREDICT :		in std_logic;		-- Jump Prediction
				JMP_REAL :			in std_logic;		-- Jump real condition
				ICACHE_STALL:			in std_logic;		-- The WRF is busy
				WRF_STALL:			in std_logic;		-- The WRF is busy

		-- Outputs
				MUXBOOT_CTR:		out std_logic;

				PIPEREG1_ENABLE:	out std_logic;
				MUXRD_CTR:			out std_logic;
				WRF_ENABLE:			out std_logic;
				WRF_CALL:			out std_logic;
				WRF_RET:			out std_logic;
				WRF_RS1_ENABLE:		out std_logic;
				WRF_RS2_ENABLE:		out std_logic;
				WRF_RD_ENABLE:		out std_logic;
				WRF_MEM_BUS:		out std_logic;
				WRF_MEM_CTR:		out std_logic;

				PIPEREG2_ENABLE:	out std_logic;
				MUXA_CTR:			out std_logic;
				MUXB_CTR:			out std_logic;
				ALU_FUNC:			out std_logic_vector(1 downto 0);

				PIPEREG3_ENABLE:	out std_logic;
				MUXC_CTR:			out std_logic;
				MEMORY_ENABLE:		out std_logic;
				MEMORY_RNOTW:		out std_logic;

				PIPEREG4_ENABLE:	out std_logic;
				MUXWB_CTR:			out std_logic
	);
	end component;

		-- Inputs
	signal Clk :				 std_logic := '0';		-- Clock
	signal Rst :				 std_logic;		-- Reset:Active-Low
	signal IR  :				 std_logic_vector(31 downto 0);
	signal JMP_PREDICT :		 std_logic;		-- Jump Prediction
	signal JMP_REAL :			 std_logic;		-- Jump real condition
	signal ICACHE_STALL:		 std_logic;		-- Instruction cache stall
	signal WRF_STALL:			 std_logic;		-- The WRF is busy

		-- Outputs
	signal MUXBOOT_CTR:		 std_logic;
	signal PIPEREG1_ENABLE:	 std_logic;
	signal MUXRD_CTR:			 std_logic;
	signal WRF_ENABLE:			 std_logic;
	signal WRF_CALL:			 std_logic;
	signal WRF_RET:			 std_logic;
	signal WRF_RS1_ENABLE:		 std_logic;
	signal WRF_RS2_ENABLE:		 std_logic;
	signal WRF_RD_ENABLE:		 std_logic;
	signal WRF_MEM_BUS:		 std_logic;
	signal WRF_MEM_CTR:		 std_logic;
	signal PIPEREG2_ENABLE:	 std_logic;
	signal MUXA_CTR:			 std_logic;
	signal MUXB_CTR:			 std_logic;
	signal ALU_FUNC:			 std_logic_vector(1 downto 0);
	signal PIPEREG3_ENABLE:	 std_logic;
	signal MUXC_CTR:			 std_logic;
	signal MEMORY_ENABLE:		 std_logic;
	signal MEMORY_RNOTW:		 std_logic;
	signal PIPEREG4_ENABLE:	 std_logic;
	signal MUXWB_CTR:			 std_logic;
begin

	-- instance of DLX
	dut: CU_UP
	port map (Clk, Rst, IR, JMP_PREDICT, JMP_REAL, ICACHE_STALL, WRF_STALL, MUXBOOT_CTR, PIPEREG1_ENABLE, MUXRD_CTR, WRF_ENABLE, WRF_CALL, WRF_RET, WRF_RS1_ENABLE, WRF_RS2_ENABLE, WRF_RD_ENABLE, WRF_MEM_BUS, WRF_MEM_CTR, PIPEREG2_ENABLE, MUXA_CTR, MUXB_CTR ,ALU_FUNC, PIPEREG3_ENABLE, MUXC_CTR,MEMORY_ENABLE, MEMORY_RNOTW, PIPEREG4_ENABLE ,MUXWB_CTR);

	Clk <= not Clk after 10 ns;
	Rst <= '0', '1' after 5 ns;

	CONTROL: process(Clk)
	begin

		IR <= ITYPE_ADD & "00000000000000000000000000";

	end process;

end test;
