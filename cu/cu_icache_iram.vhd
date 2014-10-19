library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.cachepkg.all;
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

	component ROCACHE is
		port (
			CLK						: in std_logic;
			RST						: in std_logic;  -- active high
			ENABLE					: in std_logic;
			ADDRESS					: in std_logic_vector(Instr_size - 1 downto 0);
			OUT_DATA				: out std_logic_vector(Instr_size - 1 downto 0);
			STALL					: out std_logic;
			RAM_ISSUE				: out std_logic;
			RAM_ADDRESS				: out std_logic_vector(Instr_size - 1 downto 0);
			RAM_DATA				: in std_logic_vector(2*Instr_size - 1 downto 0);
			RAM_READY				: in std_logic
		);
	end component;

	component ROMEM is
		generic (
			ENTRIES		: integer := 48;
			WORD_SIZE	: integer := 32
		);
		port (
			CLK					: in std_logic;
			RST					: in std_logic;
			ADDRESS				: in std_logic_vector(WORD_SIZE - 1 downto 0);
			ENABLE				: in std_logic;
			DATA_READY			: out std_logic;
			DATA				: out std_logic_vector(2*WORD_SIZE - 1 downto 0)
		);
	end component;

	component LATCH is
		generic (
					N: integer := 1
				);
		port (
				DIN:	in	std_logic_vector(N-1 downto 0);		-- Data in
				EN:		in std_logic;
				RESET:	in std_logic;
				DOUT:	out	std_logic_vector(N-1 downto 0)		-- Data out
			);
	end component;

	signal PC, IR, RAM_ADDRESS				: std_logic_vector(Instr_size-1 downto 0):=X"00000000" ;
	signal RAM_DATA							: std_logic_vector(2*Instr_size - 1 downto 0);
	signal ICACHE_STALL						: std_logic := '1';
	signal ENABLE							: std_logic:= '0';
	signal RAM_ISSUE, RAM_READY				: std_logic:= '0';

		-- Inputs
	signal CLK :				 std_logic := '0';		-- Clock
	signal RST :				 std_logic;		-- Reset:Active-Low
	signal JMP_PREDICT :		 std_logic;		-- Jump Prediction
	signal JMP_REAL :			 std_logic;		-- Jump real condition
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

	-- Control Unit
	dut: CU_UP
	port map (CLK, RST, IR, JMP_PREDICT, JMP_REAL, ICACHE_STALL, WRF_STALL, MUXBOOT_CTR, PIPEREG1_ENABLE, MUXRD_CTR, WRF_ENABLE, WRF_CALL, WRF_RET, WRF_RS1_ENABLE, WRF_RS2_ENABLE, WRF_RD_ENABLE, WRF_MEM_BUS, WRF_MEM_CTR, PIPEREG2_ENABLE, MUXA_CTR, MUXB_CTR ,ALU_FUNC, PIPEREG3_ENABLE, MUXC_CTR,MEMORY_ENABLE, MEMORY_RNOTW, PIPEREG4_ENABLE, MUXWB_CTR);

	-- IRAM
	IRAM : ROMEM
		port map (CLK, RST, RAM_ADDRESS, ENABLE, RAM_READY, RAM_DATA);

	ICACHE : ROCACHE
		port map (CLK, RST, ENABLE, PC, IR, ICACHE_STALL, RAM_ISSUE, RAM_ADDRESS, RAM_DATA, RAM_READY);

	--  GO!


	ENABLE <= '1';--,'0' after 20 ns,'1' after 30 ns,'0' after 40 ns,'1' after 50 ns,'0' after 60 ns, '1' after 70 ns;
	CLK <= not CLK after 10 ns;
	RST <= '1', '0' after 5 ns;

	PC_GENERATOR : process
	begin
		pc <= X"00000002";
		wait until ICACHE_STALL = '0' and clk'event and clk='1';
		pc <= X"00000003";
		wait until ICACHE_STALL = '0' and clk'event and clk='1';
		pc <= X"00000004";
		wait until ICACHE_STALL = '0' and clk'event and clk='1';
		pc <= X"00000005";
		wait until ICACHE_STALL = '0' and clk'event and clk='1';
		pc <= X"00000006";
		wait until ICACHE_STALL = '0' and clk'event and clk='1';
		pc <= X"00000004";
		wait until ICACHE_STALL = '0' and clk'event and clk='1';
		pc <= X"00000002";
		wait for 20 ns;
	end process PC_GENERATOR;

--	MMU_G			: MMU port map(CLK,reset,READ_M,read_addr,instr_from_ir,mem_busy,IR_EN,addr_to_ir,instr_from_m);

end test;
