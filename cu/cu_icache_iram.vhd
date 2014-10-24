library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use work.CONSTANTS.all;
use work.ROCACHE_PKG.all;
use work.cu.all;

entity cu_test is
	end cu_test;

architecture TEST of cu_test is
	component CU_UP is
		port (
			-- Inputs
			CLK :				in std_logic;		-- Clock
			RST :				in std_logic;		-- Reset:Active-High
			IR  :				in std_logic_vector(31 downto 0);
			JMP_PREDICT :		in std_logic;		-- Jump Prediction
			JMP_REAL :			in std_logic;		-- Jump real condition
			ICACHE_STALL:		in std_logic;		-- The instruction cache is in stall
			WRF_STALL:			in std_logic;		-- The WRF is busy

			-- Outputs
			PC_UPDATE:			out std_logic;
			JUMPER:				out std_logic_vector(1 downto 0);
			MUXRD_CTR:			out std_logic;
			WRF_ENABLE:			out std_logic;
			WRF_CALL:			out std_logic;
			WRF_RET:			out std_logic;
			WRF_RS1_ENABLE:		out std_logic;
			WRF_RS2_ENABLE:		out std_logic;
			WRF_RD_ENABLE:		out std_logic;

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

	component INCREMENTER is
		generic (
			N: integer			:= 32
		);

		port (
			A: in std_logic_vector (N-1 downto 0);
			Y: out std_logic_vector(N-1 downto 0)
		);
	end component;

	component RCA_GENERIC is
		generic (
			NBIT	:	integer	:= 32
		);

		port (
			A :		in	std_logic_vector(NBIT-1 downto 0);
			B :		in	std_logic_vector(NBIT-1 downto 0);
			Ci :	in	std_logic;
			S :		out	std_logic_vector(NBIT-1 downto 0);
			Co :	out	std_logic
		);
	end component;

	component SGNEXT is
		generic (
			INBITS:		integer;
			OUTBITS:	integer
		);

		port(
			DIN :		in std_logic_vector (INBITS-1 downto 0);
			DOUT :		out std_logic_vector (OUTBITS-1 downto 0)
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

	component REGISTER_FD is
		generic (
			N: integer := 32
		);
		port (
			DIN:	in	std_logic_vector(N-1 downto 0);		-- Data in
			CLK:	in	std_logic;							-- Clock
			RESET:	in	std_logic;							-- Reset
			DOUT:	out	std_logic_vector(N-1 downto 0)		-- Data out
		);
	end component;

	component MUX is
		generic (
			N:			integer := 1		-- Number of bits
		);
		port (
			A:		in	std_logic_vector(N-1 downto 0);
			B:		in	std_logic_vector(N-1 downto 0);
			SEL:	in	std_logic;
			Y:		out	std_logic_vector(N-1 downto 0)
		);
	end component;

	component WRF is
		generic (
			NBIT:		integer	:= wrfNumBit;
			M:			integer := wrfNumGlobals;
			F:			integer := wrfNumWindows;
			N:			integer := wrfNumRegsPerWin;
			NREG:		integer := wrfNumRegs; -- 16 + 2*7*8; -- numGlobals + 2*numWindows*numRegsPerWin;
			LOGNREG:	integer := wrfLogNumRegs;
			LOGN:		integer := wrfLogNumRegsPerWin
		);

		port (
			CLK:			IN std_logic;
			RESET:			IN std_logic;
			ENABLE:			IN std_logic;

			CALL:			IN std_logic;									-- Call -> Next context
			RET:			IN std_logic;									-- Return -> Previous context

			RD1:			IN std_logic;									-- Read 1
			RD2:			IN std_logic;									-- Read 2
			WR:				IN std_logic;									-- Write

			ADDR_WR:		IN std_logic_vector(LOGNREG-1 downto 0);		-- Write Address
			ADDR_RD1:		IN std_logic_vector(LOGNREG-1 downto 0);		-- Read Address 1
			ADDR_RD2:		IN std_logic_vector(LOGNREG-1 downto 0);		-- Read Address 2

			DATAIN:			IN std_logic_vector(NBIT-1 downto 0);			-- Write data
			OUT1:			OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 1
			OUT2:			OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 2

			MEMBUS:			INOUT std_logic_vector(NBIT-1 downto 0);		-- Memory Data Bus
			MEMCTR:			OUT std_logic_vector(10 downto 0);				-- Memory Control Signals
			BUSY:			OUT std_logic									-- The register file is busy
		);
	end component;

	signal CLK								: std_logic := '0';		-- Clock
	signal RST								: std_logic;		-- Reset:Active-Low

	signal IPC, PC, NPC, LPC				: std_logic_vector(Instr_size-1 downto 0) := (others => '0');
	signal IR, IR_RF, ICACHE_IR				: std_logic_vector(Instr_size-1 downto 0) := (others => '0');
	signal RAM_ADDRESS						: std_logic_vector(Instr_size-1 downto 0) := (others => '0');
	signal RAM_DATA							: std_logic_vector(2*Instr_size - 1 downto 0) := (others => '0');
	signal ICACHE_STALL						: std_logic := '1';
	signal ENABLE							: std_logic := '0';
	signal RAM_ISSUE, RAM_READY				: std_logic := '0';
	signal JMP_PREDICT						: std_logic;		-- Jump Prediction
	signal WRF_STALL						: std_logic;		-- The WRF is busy
	signal JUMPER							: std_logic_vector(1 downto 0);
	signal PC_UPDATE						: std_logic;
	signal MUXBEQZ_CTR						: std_logic;
	signal ICACHE_ENABLE					: std_logic;
	signal MUXRD_CTR						: std_logic;
	signal WRF_ENABLE						: std_logic;
	signal WRF_CALL							: std_logic;
	signal WRF_RET							: std_logic;
	signal WRF_RS1_ENABLE					: std_logic;
	signal WRF_RS2_ENABLE					: std_logic;
	signal WRF_RD_ENABLE					: std_logic;
	signal WRF_MEM_BUS						: std_logic;
	signal WRF_MEM_CTR						: std_logic;
	signal PIPEREG2_ENABLE					: std_logic;
	signal MUXA_CTR							: std_logic;
	signal MUXB_CTR							: std_logic;
	signal ALU_FUNC							: std_logic_vector(1 downto 0);
	signal PIPEREG3_ENABLE					: std_logic;
	signal MUXC_CTR							: std_logic;
	signal MEMORY_ENABLE					: std_logic;
	signal MEMORY_RNOTW						: std_logic;
	signal PIPEREG4_ENABLE					: std_logic;
	signal MUXWB_CTR						: std_logic;
	signal JUMP								: std_logic;

	-- STAGE TWO
	signal PC_OFFSET						: std_logic_vector(31 downto 0) := (others => '0');
	signal JMP_ADDRESS						: std_logic_vector(31 downto 0) := (others => '0');
	signal JMP_ADDRESS_DELAYED				: std_logic_vector(31 downto 0) := (others => '0');
	signal JMP_CARRYOUT						: std_logic;

	signal RD_TEMP							: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Write Address
	signal RD								: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Write Address
	signal RS1								: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Read Address 1
	signal RS2								: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Read Address 2
	signal RD_DATA							: std_logic_vector(wrfNumBit-1 downto 0);			-- Write data
	signal RS1_DATA							: std_logic_vector(wrfNumBit-1 downto 0);			-- Read data 1
	signal RS1_DATA_ISZERO					: std_logic;
	signal RS2_DATA							: std_logic_vector(wrfNumBit-1 downto 0);			-- Read data 2
	signal WRFMEMBUS						: std_logic_vector(wrfNumBit-1 downto 0);		-- Memory Data Bus
	signal WRFMEMCTR						: std_logic_vector(10 downto 0);				-- Memory Control Signals
	signal JUMP_RF							: std_logic;

	signal RS1_DATA_EX						: std_logic_vector(wrfNumBit-1 downto 0);
	signal RS2_DATA_EX						: std_logic_vector(wrfNumBit-1 downto 0);
	signal RD_EX							: std_logic_vector(wrfLogNumRegs-1 downto 0);
	signal PC_OFFSET_EX						: std_logic_vector(INSTR_SIZE-1 downto 0);

	-- STAGE THREE

	signal RD_WB							: std_logic_vector(wrfLogNumRegs-1 downto 0);
	signal RD_DATA_WB						: std_logic_vector(wrfNumBit-1 downto 0);

begin

	ICACHE_ENABLE <= not JUMP;
	JMP_PREDICT <= '0';						-- Always predict not taken

	-- Control Unit
	dut: CU_UP
	port map (CLK, RST, IR, JMP_PREDICT, JUMP_RF, ICACHE_STALL, WRF_STALL, PC_UPDATE, JUMPER, MUXRD_CTR, WRF_ENABLE, WRF_CALL, WRF_RET, WRF_RS1_ENABLE, WRF_RS2_ENABLE, WRF_RD_ENABLE, PIPEREG2_ENABLE, MUXA_CTR, MUXB_CTR ,ALU_FUNC, PIPEREG3_ENABLE, MUXC_CTR,MEMORY_ENABLE, MEMORY_RNOTW, PIPEREG4_ENABLE, MUXWB_CTR);

	-- IRAM
	IRAM : ROMEM
		port map (CLK, RST, RAM_ADDRESS, RAM_ISSUE, RAM_READY, RAM_DATA);

	ICACHE : ROCACHE
		port map (CLK, RST, '1', PC, ICACHE_IR, ICACHE_STALL, RAM_ISSUE, RAM_ADDRESS, RAM_DATA, RAM_READY);

	ICACHE_OUT: MUX
		generic map (32)
		port map ((others=>'0'), ICACHE_IR, ICACHE_ENABLE, IR);

--	__ INCREMENTER

	NPCEVAL: INCREMENTER
		generic map (32)
		port map (PC, IPC);

	JMP_UNIT : process(JUMPER, RS1_DATA_ISZERO)
	begin
		case ( JUMPER ) is
			when "00" =>						-- No jump
				JUMP_RF <= '0';

			when "01" =>						-- BEQZ
				JUMP_RF <= RS1_DATA_ISZERO;

			when "10" =>						-- BNEQZ
				JUMP_RF <= not RS1_DATA_ISZERO;

			when "11" =>						-- Jump
				JUMP_RF <= '1';

			when others =>
				report "WHAT?!?!?";
		end case;
	end process;

	JUMP_DELAYER: REGISTER_FD
		generic map (1)
		port map(DIN(0) =>JUMP_RF, CLK => CLK, RESET => RST, DOUT(0) => JUMP);

	LATCHIPLEXER : process(JMP_ADDRESS_DELAYED, NPC, PC_UPDATE, JUMP)
	begin
		if JUMP = '1' then
			PC <= JMP_ADDRESS_DELAYED;
		elsif PC_UPDATE = '1' then
			PC <= NPC;
		end if;
	end process;

	FAKEPIPEREG_NPC: REGISTER_FD
		generic map (32)
		port map(IPC, CLK, RST, NPC);

	PROPAGATE_PC_IF_RF: REGISTER_FD
		generic map (32)
		port map (IR, CLK, RST, IR_RF);

	--
	-- STAGE TWO
	--

	EXTENDER: SGNEXT
		generic map (26, 32)
		port map (IR_RF(25 downto 0), PC_OFFSET);

	JMP_ADDER: RCA_GENERIC
		generic map (32)
		port map(NPC, PC_OFFSET, '0', JMP_ADDRESS, JMP_CARRYOUT);

	FAKEPIPEREG_JMP_ADDRESS: REGISTER_FD
		generic map (32)
		port map(JMP_ADDRESS, CLK, RST, JMP_ADDRESS_DELAYED);

	-- WRF

	RS1		<= IR_RF(25 downto 21);
	RS2		<= IR_RF(20 downto 16);
	RD_TEMP	<= IR_RF(16 downto 12);

	REGISTERFILE: WRF
		port map (CLK, RST, WRF_ENABLE, WRF_CALL, WRF_RET, WRF_RS1_ENABLE, WRF_RS2_ENABLE, WRF_RD_ENABLE, RS1, RS2, RD_WB, RD_DATA_WB, RS1_DATA, RS2_DATA, WRFMEMBUS, WRFMEMCTR, WRF_STALL);

	MUXRD: MUX
		generic map (5)
		port map (RS2, RD_TEMP, MUXRD_CTR, RD);

	-- Comparator

	RS1_DATA_ISZERO <= not or_reduce(RS1_DATA);

	-- PIPES

	PIPEREG_RD: REGISTER_FD
		generic map (5)
		port map(RD, CLK, RST, RD_EX);

	PIPEREG_RS1_DATA: REGISTER_FD
		generic map (32)
		port map(RS1_DATA, CLK, RST, RS1_DATA_EX);

	PIPEREG_RS2_DATA: REGISTER_FD
		generic map (32)
		port map(RS2_DATA, CLK, RST, RS1_DATA_EX);

	PIPEREG_PC_OFFSET: REGISTER_FD
		generic map (32)
		port map(PC_OFFSET, CLK, RST, PC_OFFSET_EX);


	-- STAGE 3


	--  GO!

	ENABLE <= '1';--,'0' after 20 ns,'1' after 30 ns,'0' after 40 ns,'1' after 50 ns,'0' after 60 ns, '1' after 70 ns;
	CLK <= not CLK after 10 ns;
	RST <= '1', '0' after 5 ns;

end test;
