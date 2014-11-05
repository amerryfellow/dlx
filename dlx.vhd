library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use work.CONSTANTS.all;
use work.ROCACHE_PKG.all;
use work.alu_types.all;
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
			ICACHE_STALL:		in std_logic;		-- The instruction cache is in stall
			WRF_STALL:			in std_logic;		-- The WRF is busy
			ISZERO :			in std_logic;		-- Needed for condizional jumps
			JMP_ADDRESS :		in std_logic_vector(31 downto 0);
			NPC_ADDRESS :		in std_logic_vector(31 downto 0);
			PC :				out std_logic_vector(31 downto 0);

			-- Outputs
			JUMP:				out std_logic;
			MUXIR_CTR:			out std_logic;
			PC_UPDATE:			out std_logic;
			MUXRD_CTR:			out std_logic;
			WRF_ENABLE:			out std_logic;
			WRF_CALL:			out std_logic;
			WRF_RET:			out std_logic;
			WRF_RS1_ENABLE:		out std_logic;
			WRF_RS2_ENABLE:		out std_logic;

			MUXALU_CTR:			out std_logic;
			ALU_FUNC:			out std_logic_vector(3 downto 0);

			PIPEREG3_ENABLE:	out std_logic;
			MUXC_CTR:			out std_logic;
			MEMORY_ENABLE:		out std_logic;
			MEMORY_RNOTW:		out std_logic;

			WRF_RD_ENABLE:		out std_logic;
			MUXWB_CTR:			out std_logic;

			ID_STALL:			out std_logic;
			EXE_STALL:			out std_logic;
			MEM_STALL:			out std_logic;
			WB_STALL:			out std_logic
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

	component MUX4TO1 is
		generic (
			N:			integer	:= NSUMG		-- Number of bits
		);

		port (
			A:		in	std_logic_vector(N-1 downto 0);
			B:		in	std_logic_vector(N-1 downto 0);
			C:		in	std_logic_vector(N-1 downto 0);
			D:		in	std_logic_vector(N-1 downto 0);
			SEL:	in	std_logic_vector(1 downto 0);
			Y:		out	std_logic_vector(N-1 downto 0)
		);
	end component;

	component WRF is
		generic (
			NBIT:		integer;
			M:			integer;
			F:			integer;
			N:			integer;
			NREG:		integer;
			LOGNREG:	integer;
			LOGN:		integer
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

			ADDR_RD1:		IN std_logic_vector(LOGNREG-1 downto 0);		-- Read Address 1
			ADDR_RD2:		IN std_logic_vector(LOGNREG-1 downto 0);		-- Read Address 2
			ADDR_WR:		IN std_logic_vector(LOGNREG-1 downto 0);		-- Write Address

			OUT1:			OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 1
			OUT2:			OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 2
			DATAIN:			IN std_logic_vector(NBIT-1 downto 0);			-- Write data

			MEMBUS:			INOUT std_logic_vector(NBIT-1 downto 0);		-- Memory Data Bus
			MEMCTR:			OUT std_logic_vector(10 downto 0);				-- Memory Control Signals
			BUSY:			OUT std_logic									-- The register file is busy
		);
	end component;

	component ALU
		generic (
			N : integer := NSUMG
		);

		port (
			FUNC:					in TYPE_OP;
			A, B:					in std_logic_vector(N-1 downto 0);
			CLK: 					in std_logic;
			RESET: 				in std_logic;
			OUTALU:				out std_logic_vector(N-1 downto 0)
		);
	end component;

	signal CLK								: std_logic := '0';		-- Clock
	signal RST								: std_logic;		-- Reset:Active-Low

	signal IPC, PC, NPC, LPC				: std_logic_vector(Instr_size-1 downto 0) := (others => '0');
	signal IR, IR_RF, ICACHE_IR				: std_logic_vector(Instr_size-1 downto 0) := (others => '0');
	signal RAM_ADDRESS						: std_logic_vector(Instr_size-1 downto 0) := (others => '0');
	signal RAM_DATA							: std_logic_vector(2*Instr_size - 1 downto 0) := (others => '0');
	signal ICACHE_STALL, ICACHE_STALL_NOT	: std_logic := '1';
	signal ENABLE							: std_logic := '0';
	signal RAM_ISSUE, RAM_READY				: std_logic := '0';
	signal JMP_PREDICT						: std_logic;		-- Jump Prediction
	signal JMP_STALL						: std_logic;		-- The WRF is busy
	signal WRF_STALL						: std_logic;		-- The WRF is busy
	signal JUMPER							: std_logic_vector(1 downto 0);
	signal PC_UPDATE						: std_logic;
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
	signal MUXALU_CTR						: std_logic;
	signal ALU_FUNC							: std_logic_vector(3 downto 0);
	signal PIPEREG3_ENABLE					: std_logic;
	signal MUXC_CTR							: std_logic;
	signal MEMORY_ENABLE					: std_logic;
	signal MEMORY_RNOTW						: std_logic;
	signal MUXWB_CTR						: std_logic;
	signal JUMP								: std_logic;
	signal MUXIR_CTR						: std_logic;

	signal ID_STALL							: std_logic;
	signal EXE_STALL						: std_logic;
	signal MEM_STALL						: std_logic;
	signal WB_STALL							: std_logic;

	-- STAGE TWO
	signal IMMEDIATE						: std_logic_vector(31 downto 0) := (others => '0');
	signal JMP_ADDRESS						: std_logic_vector(31 downto 0) := (others => '0');
	signal JMP_ADDRESS_LATCHED				: std_logic_vector(31 downto 0) := (others => '0');
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

	signal RS1_EX							: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Read Address 1
	signal RS2_EX							: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Read Address 1
	signal RS1_DATA_EX						: std_logic_vector(wrfNumBit-1 downto 0);
	signal RS2_DATA_EX						: std_logic_vector(wrfNumBit-1 downto 0);
	signal RD_EX							: std_logic_vector(wrfLogNumRegs-1 downto 0);
	signal IMMEDIATE_EX						: std_logic_vector(INSTR_SIZE-1 downto 0);

	-- STAGE THREE

	signal FWDJ0							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal FWDJ								: std_logic_vector(WORD_SIZE-1 downto 0);
	signal FWDA0							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal FWDA1							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal FWDB0							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal FWDB1							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal ALU_IN1							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal ALU_IN2							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal ALU_OUT							: std_logic_vector(WORD_SIZE-1 downto 0);

	signal ALU_OUT_MEM						: std_logic_vector(WORD_SIZE-1 downto 0);
	signal RD_MEM							: std_logic_vector(wrfLogNumRegs-1 downto 0);
	signal RD_DATA_MEM						: std_logic_vector(wrfNumBit-1 downto 0);
	signal IMMEDIATE_MEM					: std_logic_vector(wrfNumBit-1 downto 0);

	-- STAGE FOUR

	signal RD_WB							: std_logic_vector(wrfLogNumRegs-1 downto 0);
	signal MEM_OUT_WB						: std_logic_vector(WORD_SIZE-1 downto 0);
	signal RD_DATA_WB						: std_logic_vector(wrfNumBit-1 downto 0);

	signal RS1_EQ_RD_EX : std_logic;
	signal RS1_EQ_RD_MEM : std_logic;
	signal RS1_EQ_RD_WB : std_logic;
	signal RS1_EX_EQ_RD_MEM : std_logic;
	signal RS1_EX_EQ_RD_WB : std_logic;
	signal RS2_EX_EQ_RD_MEM : std_logic;
	signal RS2_EX_EQ_RD_WB : std_logic;

begin

	ICACHE_ENABLE <= not JUMP;
	ICACHE_STALL_NOT <= not ICACHE_STALL;
	JMP_PREDICT <= '0';						-- Always predict not taken

	-- Control Unit
	dut: CU_UP
	port map (CLK, RST, IR, JMP_PREDICT, ICACHE_STALL, WRF_STALL, RS1_DATA_ISZERO, JMP_ADDRESS, IPC, PC, JUMP, MUXIR_CTR, PC_UPDATE, MUXRD_CTR, WRF_ENABLE, WRF_CALL, WRF_RET, WRF_RS1_ENABLE, WRF_RS2_ENABLE, MUXALU_CTR, ALU_FUNC, PIPEREG3_ENABLE, MUXC_CTR,MEMORY_ENABLE, MEMORY_RNOTW, WRF_RD_ENABLE, MUXWB_CTR, ID_STALL, EXE_STALL, MEM_STALL, WB_STALL);

	-- IRAM
	IRAM : ROMEM
		port map (CLK, RST, RAM_ADDRESS, RAM_ISSUE, RAM_READY, RAM_DATA);

	ICACHE : ROCACHE
		port map (CLK, RST, '1', PC, ICACHE_IR, ICACHE_STALL, RAM_ISSUE, RAM_ADDRESS, RAM_DATA, RAM_READY);

	MUX_IR : MUX
		generic map ( 32 )
--		port map( (others => '0'), ICACHE_IR, MUXIR_CTR, IR );
		port map( (others => '0'), ICACHE_IR, ICACHE_STALL_NOT, IR );

--	__ INCREMENTER

	NPCEVAL: INCREMENTER
		generic map (32)
		port map (PC, IPC);

	FAKEPIPEREG_NPC: REGISTER_FD
		generic map (32)
		port map(IPC, CLK, RST, NPC);

	PROPAGATE_PC_IF_RF: REGISTER_FD
		generic map (32)
		port map (IR, CLK, RST, IR_RF);

	PROPAGATE_RS1_ID_EX: REGISTER_FD
		generic map (5)
		port map (RS1, CLK, RST, RS1_EX);

	PROPAGATE_RS2_ID_EX: REGISTER_FD
		generic map (5)
		port map (RS2, CLK, RST, RS2_EX);

	--
	-- STAGE TWO
	--

	EXTENDER: SGNEXT
		generic map (16, 32)
		port map (IR_RF(15 downto 0), IMMEDIATE);

	JMP_ADDER: RCA_GENERIC
		generic map (32)
		port map(NPC, IMMEDIATE, '0', JMP_ADDRESS, JMP_CARRYOUT);

	-- WRF

	RS1		<= IR_RF(25 downto 21);
	RS2		<= IR_RF(20 downto 16);
	RD_TEMP	<= IR_RF(15 downto 11);

	REGISTERFILE: WRF
		generic map (wrfNumBit, wrfNumGlobals, wrfNumWindows, wrfNumRegsPerWin, wrfNumRegs, wrfLogNumRegs, wrfLogNumRegsPerWin)
		port map (CLK, RST, WRF_ENABLE, '0', '0', WRF_RS1_ENABLE, WRF_RS2_ENABLE, WRF_RD_ENABLE, RS1, RS2, RD_WB, RS1_DATA, RS2_DATA, RD_DATA_WB, WRFMEMBUS, WRFMEMCTR, WRF_STALL);

	MUXRD: MUX
		generic map (5)
		port map (RS2, RD_TEMP, MUXRD_CTR, RD);

	RS1_EQ_RD_EX <= not or_reduce( RS1 xor RD_EX );
	RS1_EQ_RD_MEM <= not or_reduce( RS1 xor RD_MEM );
	RS1_EQ_RD_WB <= not or_reduce( RS1 xor RD_WB );

	JMP_STALL <= RS1_EQ_RD_EX and ( not or_reduce( JUMPER xor "01" ) or not or_reduce( JUMPER xor "10" ) );

	-- JUMPER forward logic
	MUX_FWDJ1 : MUX
		generic map ( WORD_SIZE )
		port map ( FWDJ0, ALU_OUT_MEM, RS1_EQ_RD_MEM, FWDJ );

	MUX_FWDJ0 : MUX
		generic map ( WORD_SIZE )
		port map ( RS1_DATA, MEM_OUT_WB, RS1_EQ_RD_WB, FWDJ0 );

	-- Comparator

	RS1_DATA_ISZERO <= not or_reduce(FWDJ);

	-- PIPES

	PIPEREG_RD: REGISTER_FD
		generic map (5)
		port map(RD, CLK, RST, RD_EX);

	PIPEREG_RS1_DATA: REGISTER_FD
		generic map (32)
		port map(RS1_DATA, CLK, RST, RS1_DATA_EX);

	PIPEREG_RS2_DATA: REGISTER_FD
		generic map (32)
		port map(RS2_DATA, CLK, RST, RS2_DATA_EX);

	PIPEREG_IMMEDIATE: REGISTER_FD
		generic map (32)
		port map(IMMEDIATE, CLK, RST, IMMEDIATE_EX);

	-- STAGE 3

--	RS1_EX_EQ_RD_MEM <=	( not or_reduce( RS1_EX xor RD_MEM )) and ( or_reduce( RS1_EX ) );
--	RS1_EX_EQ_RD_WB <=	( not or_reduce( RS1_EX xor RD_WB )	) and ( or_reduce( RS1_EX ) );
--	RS2_EX_EQ_RD_MEM <=	( not or_reduce( RS2_EX xor RD_MEM )) and ( or_reduce( RS2_EX ) );
--	RS2_EX_EQ_RD_WB <=	( not or_reduce( RS2_EX xor RD_WB )	) and ( or_reduce( RS2_EX ) );
	RS1_EX_EQ_RD_MEM <=	( not or_reduce( RS1_EX xor RD_MEM )) and ( not MEM_STALL );
	RS1_EX_EQ_RD_WB <=	( not or_reduce( RS1_EX xor RD_WB )	) and ( not WB_STALL );
	RS2_EX_EQ_RD_MEM <=	( not or_reduce( RS2_EX xor RD_MEM )) and ( not MEM_STALL );
	RS2_EX_EQ_RD_WB <=	( not or_reduce( RS2_EX xor RD_WB )	) and ( not WB_STALL );

	-- ALU forward logic
	MUX_FWDA1 : MUX
		generic map ( WORD_SIZE )
		port map ( FWDA0, ALU_OUT_MEM, RS1_EX_EQ_RD_MEM, FWDA1 );

	MUX_FWDA0 : MUX
		generic map ( WORD_SIZE )
		port map ( RS1_DATA_EX, MEM_OUT_WB, RS1_EX_EQ_RD_WB, FWDA0 );

	MUX_FWDB1 : MUX
		generic map ( WORD_SIZE )
		port map ( FWDB0, ALU_OUT_MEM, RS2_EX_EQ_RD_MEM, FWDB1 );

	MUX_FWDB0 : MUX
		generic map ( WORD_SIZE )
		port map ( RS2_DATA_EX, MEM_OUT_WB, RS2_EX_EQ_RD_WB, FWDB0 );

	-- ALU input muxes
	MUX_ALU2 : MUX
		generic map ( WORD_SIZE )
		port map ( IMMEDIATE_EX, FWDB1, MUXALU_CTR, ALU_IN2 );

	ALU_IN1 <= FWDA1;

	-- ALU
	EXECUTER : ALU
		generic map ( WORD_SIZE )
		port map ( ALU_FUNC, ALU_IN1, ALU_IN2, CLK, RST, ALU_OUT );

	PIPEREG_ALU_OUT: REGISTER_FD
		generic map (32)
		port map(ALU_OUT, CLK, RST, ALU_OUT_MEM);

	PIPEREG_IMMEDIATE_EX: REGISTER_FD
		generic map (32)
		port map(IMMEDIATE_EX, CLK, RST, IMMEDIATE_MEM);

	PIPEREG_RD_EX: REGISTER_FD
		generic map (5)
		port map(RD_EX, CLK, RST, RD_MEM);

	-- STAGE FOUR

	PIPEREG_RD_MEM: REGISTER_FD
		generic map (5)
		port map(RD_MEM, CLK, RST, RD_WB);

	PIPEREG_ALU_OUT_MEM: REGISTER_FD
		generic map (32)
		port map(ALU_OUT_MEM, CLK, RST, MEM_OUT_WB);

	-- STAGE FIVE

	RD_DATA_WB <= MEM_OUT_WB;

	-- Nothing

	--  GO!

	ENABLE <= '1';--,'0' after 20 ns,'1' after 30 ns,'0' after 40 ns,'1' after 50 ns,'0' after 60 ns, '1' after 70 ns;
	CLK <= not CLK after 10 ns;
	RST <= '1', '0' after 5 ns;

end test;
