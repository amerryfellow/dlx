library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use work.CONSTANTS.all;
use work.ROCACHE_PKG.all;
use work.RWCACHE_PKG.all;
use work.alu_types.all;
use work.cu.all;

entity DLX is
	port (
		-- Inputs
		CLK						: in std_logic;		-- Clock
		RST						: in std_logic;		-- Reset:Active-High

		IRAM_ADDRESS			: out std_logic_vector(Instr_size - 1 downto 0);
		IRAM_ISSUE				: out std_logic;
		IRAM_READY				: in std_logic;
		IRAM_DATA				: in std_logic_vector(2*Data_size-1 downto 0);

		DRAM_ADDRESS			: out std_logic_vector(Instr_size-1 downto 0);
		DRAM_ISSUE				: out std_logic;
		DRAM_READNOTWRITE		: out std_logic;
		DRAM_READY				: in std_logic;
		DRAM_DATA				: inout std_logic_vector(2*Data_size-1 downto 0)
	);
end DLX;

architecture structural of DLX is
	component CU_UP is
		port (
			-- Inputs
			CLK :				in std_logic;		-- Clock
			RST :				in std_logic;		-- Reset:Active-High
			IR  :				in std_logic_vector(31 downto 0);
			JMP_PREDICT :		in std_logic;		-- Jump Prediction
			ICACHE_STALL:		in std_logic;		-- The instruction cache is in stall
			DCACHE_STALL:		in std_logic;		-- The rwcache is busy
			ISZERO :			in std_logic;		-- Needed for condizional jumps
			JMP_ADDRESS :		in std_logic_vector(31 downto 0);
			NPC_ADDRESS :		in std_logic_vector(31 downto 0);
			PC :				out std_logic_vector(31 downto 0);

			-- Outputs
			JUMP:				out std_logic;
			LATCHER:			out std_logic;

			MUXIMMEDIATE_CTR:	out std_logic;
			MUXJMPADDRESS_CTR:	out std_logic;
			MUXRD0_CTR:			out std_logic;
			MUXRD_CTR:			out std_logic;
			WRF_ENABLE:			out std_logic;
			WRF_CALL:			out std_logic;
			WRF_RET:			out std_logic;
			WRF_RS1_ENABLE:		out std_logic;
			WRF_RS2_ENABLE:		out std_logic;

			MUXALUOUT_CTR:		out std_logic;
			MUXALU_CTR:			out std_logic;
			ALU_FUNC:			out std_logic_vector(4 downto 0);

			MEMORY_ENABLE:		out std_logic;
			MEMORY_RNOTW:		out std_logic;

			WRF_RD_ENABLE:		out std_logic;

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

	component REGISTER_FDE is
		generic (
			N: integer := 32
		);
		port (
			DIN:	in	std_logic_vector(N-1 downto 0);		-- Data in
			ENABLE:	in	std_logic;							-- Enable
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
			DATAIN:			IN std_logic_vector(NBIT-1 downto 0)			-- Write data
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

	component RWCACHE is
		port (
			CLK						: in std_logic;
			RST						: in std_logic;  -- active high
			ENABLE					: in std_logic;
			READNOTWRITE			: in std_logic;
			ADDRESS					: in std_logic_vector(DATA_SIZE - 1 downto 0);
			INOUT_DATA				: inout std_logic_vector(DATA_SIZE - 1 downto 0);
			STALL					: out std_logic;
			RAM_ISSUE				: out std_logic;
			RAM_READNOTWRITE		: out std_logic;
			RAM_ADDRESS				: out std_logic_vector(DATA_SIZE - 1 downto 0);
			RAM_DATA				: inout std_logic_vector(2*DATA_SIZE - 1 downto 0);
			RAM_READY				: in std_logic
		);
	end component;

	signal IPC, PC, NPC						: std_logic_vector(Instr_size-1 downto 0) := (others => '0');
	signal IR, IR_RF, ICACHE_IR				: std_logic_vector(Instr_size-1 downto 0) := (others => '0');
	signal ICACHE_STALL, ICACHE_STALL_NOT	: std_logic := '1';
	signal JMP_PREDICT						: std_logic;		-- Jump Prediction
	signal DCACHE_STALL						: std_logic;		-- The WRF is busy
	signal DCACHE_STALL_NOT					: std_logic;		-- The WRF is busy
	signal ICACHE_ENABLE					: std_logic;
	signal MUXRD_CTR						: std_logic;
	signal WRF_ENABLE						: std_logic;
	signal WRF_CALL							: std_logic;
	signal WRF_RET							: std_logic;
	signal WRF_RET_R31						: std_logic;
	signal WRF_RS1_ENABLE					: std_logic;
	signal WRF_RS2_ENABLE					: std_logic;
	signal WRF_RD_ENABLE					: std_logic;
	signal MUXALU_CTR						: std_logic;
	signal ALU_FUNC							: std_logic_vector(4 downto 0);
	signal MEMORY_ENABLE					: std_logic;
	signal MEMORY_RNOTW						: std_logic;
	signal JUMP								: std_logic;
	signal LATCHER						: std_logic;

	signal ID_STALL							: std_logic;
	signal EXE_STALL						: std_logic;
	signal MEM_STALL						: std_logic;
	signal WB_STALL							: std_logic;

	-- STAGE TWO
	signal MUXIMMEDIATE_CTR					: std_logic;
	signal MUXJMPADDRESS_CTR				: std_logic;
	signal MUXRD0_CTR						: std_logic;
	signal IMMEDIATE						: std_logic_vector(31 downto 0) := (others => '0');
	signal IMMEDIATE_IR						: std_logic_vector(31 downto 0) := (others => '0');
	signal JMP_ADDRESS						: std_logic_vector(31 downto 0) := (others => '0');
	signal JMP_RELATIVE_ADDRESS				: std_logic_vector(31 downto 0) := (others => '0');
	signal JMP_REGISTER_ADDRESS				: std_logic_vector(31 downto 0) := (others => '0');
	signal JMP_CARRYOUT						: std_logic;

	signal RD_TEMP							: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Write Address
	signal RD								: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Write Address
	signal RD0								: std_logic_vector(wrfLogNumRegs-1 downto 0);
	signal RS1								: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Read Address 1
	signal RS2								: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Read Address 2
	signal RS1_DATA							: std_logic_vector(wrfNumBit-1 downto 0);			-- Read data 1
	signal RS1_DATA_ISZERO					: std_logic;
	signal RS2_DATA							: std_logic_vector(wrfNumBit-1 downto 0);			-- Read data 2

	signal RS1_EX							: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Read Address 1
	signal RS2_EX							: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Read Address 1
	signal RS1_DATA_EX						: std_logic_vector(wrfNumBit-1 downto 0);
	signal RS2_DATA_EX						: std_logic_vector(wrfNumBit-1 downto 0);
	signal RD_EX							: std_logic_vector(wrfLogNumRegs-1 downto 0);
	signal IMMEDIATE_EX						: std_logic_vector(INSTR_SIZE-1 downto 0);

	-- STAGE THREE

	signal MUXALUOUT_CTR					: std_logic;
	signal FWDJ0							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal FWDJ								: std_logic_vector(WORD_SIZE-1 downto 0);
	signal FWDA0							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal FWDA1							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal FWDB0							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal FWDB1							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal ALU_IN1							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal ALU_IN2							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal ALU_OUT							: std_logic_vector(WORD_SIZE-1 downto 0);
	signal ALU_OUT_REAL						: std_logic_vector(DATA_SIZE-1 downto 0);

	signal RS2_MEM							: std_logic_vector(wrfLogNumRegs-1 downto 0);		-- Read Address 1
	signal RS2_DATA_MEM						: std_logic_vector(wrfNumBit-1 downto 0);
	signal ALU_OUT_MEM						: std_logic_vector(WORD_SIZE-1 downto 0);
	signal RD_MEM							: std_logic_vector(wrfLogNumRegs-1 downto 0);
	signal IMMEDIATE_MEM					: std_logic_vector(wrfNumBit-1 downto 0);

	-- STAGE FOUR

	signal MEM_ADDRESS						: std_logic_vector(WORD_SIZE-1 downto 0);
	signal RS2_DATA_MEM1					: std_logic_vector(WORD_SIZE-1 downto 0);
	signal MEM_DATA							: std_logic_vector(WORD_SIZE-1 downto 0);

	signal RD_WB							: std_logic_vector(wrfLogNumRegs-1 downto 0);
	signal MEM_DATA_WB						: std_logic_vector(WORD_SIZE-1 downto 0);
	signal RD_DATA_WB						: std_logic_vector(wrfNumBit-1 downto 0);

	signal RS1_EQ_RD_EX : std_logic;
	signal RS1_EQ_RD_MEM : std_logic;
	signal RS1_EQ_RD_WB : std_logic;
	signal RS1_EX_EQ_RD_MEM : std_logic;
	signal RS1_EX_EQ_RD_WB : std_logic;
	signal RS2_EX_EQ_RD_MEM : std_logic;
	signal RS2_EX_EQ_RD_WB : std_logic;
	signal RS2_MEM_EQ_RD_WB : std_logic;

begin

	ICACHE_ENABLE <= not JUMP;
	ICACHE_STALL_NOT <= not ICACHE_STALL;
	JMP_PREDICT <= '0';						-- Always predict not taken
	DCACHE_STALL_NOT <= not DCACHE_STALL;

	-- Control Unit
	CONTROL_UNIT : CU_UP
	port map (CLK, RST, IR, JMP_PREDICT, ICACHE_STALL, DCACHE_STALL, RS1_DATA_ISZERO, JMP_ADDRESS, IPC, PC, JUMP, LATCHER, MUXIMMEDIATE_CTR, MUXJMPADDRESS_CTR, MUXRD0_CTR, MUXRD_CTR, WRF_ENABLE, WRF_CALL, WRF_RET, WRF_RS1_ENABLE, WRF_RS2_ENABLE, MUXALUOUT_CTR, MUXALU_CTR, ALU_FUNC, MEMORY_ENABLE, MEMORY_RNOTW, WRF_RD_ENABLE, ID_STALL, EXE_STALL, MEM_STALL, WB_STALL);

	ICACHE : ROCACHE
		port map (CLK, RST, '1', PC, ICACHE_IR, ICACHE_STALL, IRAM_ISSUE, IRAM_ADDRESS, IRAM_DATA, IRAM_READY);

	MUX_IR : MUX
		generic map ( 32 )
--		port map( (others => '0'), ICACHE_IR, LATCHER, IR );
		port map( (others => '0'), ICACHE_IR, ICACHE_STALL_NOT, IR );

--	__ INCREMENTER

	NPCEVAL: INCREMENTER
		generic map (32)
		port map (PC, IPC);

	FAKEPIPEREG_NPC: REGISTER_FDE
		generic map (32)
		port map(IPC, LATCHER, CLK, RST, NPC);

	PROPAGATE_PC_IF_RF: REGISTER_FDE
		generic map (32)
		port map (IR, LATCHER, CLK, RST, IR_RF);

	--
	-- STAGE TWO
	--

	EXTENDER: SGNEXT
		generic map (16, 32)
		port map (IR_RF(15 downto 0), IMMEDIATE_IR);

	MUX_IMMEDIATE : MUX
		generic map ( DATA_SIZE )
		port map ( IMMEDIATE_IR, NPC, MUXIMMEDIATE_CTR, IMMEDIATE );

	JMP_ADDER: RCA_GENERIC
		generic map (32)
		port map(NPC, IMMEDIATE_IR, '0', JMP_RELATIVE_ADDRESS, JMP_CARRYOUT);

	JMP_REGISTER_ADDRESS <= FWDJ;

	MUX_JMP : MUX
		generic map ( DATA_SIZE )
		port map ( JMP_RELATIVE_ADDRESS, JMP_REGISTER_ADDRESS, MUXJMPADDRESS_CTR, JMP_ADDRESS );

	-- WRF

	RS1		<= IR_RF(25 downto 21);
	RS2		<= IR_RF(20 downto 16);
	RD_TEMP	<= IR_RF(15 downto 11);
	WRF_RET_R31 <= WRF_RET and ( not or_reduce( RS1 xor "11111" ) );

	REGISTERFILE: WRF
		generic map (wrfNumBit, wrfNumGlobals, wrfNumWindows, wrfNumRegsPerWin, wrfNumRegs, wrfLogNumRegs, wrfLogNumRegsPerWin)
		port map (CLK, RST, WRF_ENABLE, WRF_CALL, WRF_RET_R31, WRF_RS1_ENABLE, WRF_RS2_ENABLE, WRF_RD_ENABLE, RS1, RS2, RD_WB, RS1_DATA, RS2_DATA, RD_DATA_WB);

	MUX_RD: MUX
		generic map (5)
		port map (RD0, RD_TEMP, MUXRD_CTR, RD);

	MUX_RD0: MUX
		generic map (5)
		port map (RS2, "11111", MUXRD0_CTR, RD0);

	RS1_EQ_RD_EX <= not or_reduce( RS1 xor RD_EX );
	RS1_EQ_RD_MEM <= not or_reduce( RS1 xor RD_MEM );
	RS1_EQ_RD_WB <= not or_reduce( RS1 xor RD_WB );

	-- JUMPER forward logic
	MUX_FWDJ1 : MUX
		generic map ( WORD_SIZE )
		port map ( FWDJ0, ALU_OUT_MEM, RS1_EQ_RD_MEM, FWDJ );

	MUX_FWDJ0 : MUX
		generic map ( WORD_SIZE )
		port map ( RS1_DATA, MEM_DATA_WB, RS1_EQ_RD_WB, FWDJ0 );

	-- Comparator

	RS1_DATA_ISZERO <= not or_reduce(FWDJ);

	-- PIPES

	PIPEREG_RD: REGISTER_FDE
		generic map (5)
		port map(RD, LATCHER, CLK, RST, RD_EX);

	PROPAGATE_RS1_ID_EX: REGISTER_FDE
		generic map (5)
		port map (RS1, LATCHER, CLK, RST, RS1_EX);

	PROPAGATE_RS2_ID_EX: REGISTER_FDE
		generic map (5)
		port map (RS2, LATCHER, CLK, RST, RS2_EX);

	PIPEREG_RS1_DATA: REGISTER_FDE
		generic map (32)
		port map(RS1_DATA, LATCHER, CLK, RST, RS1_DATA_EX);

	PIPEREG_RS2_DATA: REGISTER_FDE
		generic map (32)
		port map(RS2_DATA, LATCHER, CLK, RST, RS2_DATA_EX);

	PIPEREG_IMMEDIATE: REGISTER_FDE
		generic map (32)
		port map(IMMEDIATE, LATCHER, CLK, RST, IMMEDIATE_EX);

	-- STAGE 3

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
		port map ( RS1_DATA_EX, MEM_DATA_WB, RS1_EX_EQ_RD_WB, FWDA0 );

	MUX_FWDB1 : MUX
		generic map ( WORD_SIZE )
		port map ( FWDB0, ALU_OUT_MEM, RS2_EX_EQ_RD_MEM, FWDB1 );

	MUX_FWDB0 : MUX
		generic map ( WORD_SIZE )
		port map ( RS2_DATA_EX, MEM_DATA_WB, RS2_EX_EQ_RD_WB, FWDB0 );

	-- ALU input muxes
	MUX_ALU2 : MUX
		generic map ( WORD_SIZE )
		port map ( IMMEDIATE_EX, FWDB1, MUXALU_CTR, ALU_IN2 );

	ALU_IN1 <= FWDA1;

	-- ALU
	EXECUTER : ALU
		generic map ( WORD_SIZE )
		port map ( ALU_FUNC, ALU_IN1, ALU_IN2, CLK, RST, ALU_OUT );

	MUX_ALU_OUT : MUX
		generic map ( DATA_SIZE )
		port map ( ALU_OUT, IMMEDIATE_EX, MUXALUOUT_CTR, ALU_OUT_REAL );

	PIPEREG_ALU_OUT: REGISTER_FDE
		generic map (32)
		port map(ALU_OUT_REAL, LATCHER, CLK, RST, ALU_OUT_MEM);

	PIPEREG_IMMEDIATE_EX: REGISTER_FDE
		generic map (32)
		port map(IMMEDIATE_EX, LATCHER, CLK, RST, IMMEDIATE_MEM);

	PIPEREG_RD_EX: REGISTER_FDE
		generic map (5)
		port map(RD_EX, LATCHER, CLK, RST, RD_MEM);

	PIPEREG_RS2_DATA_EX: REGISTER_FDE
		generic map (32)
		port map(RS2_DATA_EX, LATCHER, CLK, RST, RS2_DATA_MEM);

	PIPEREG_RS2_EX: REGISTER_FDE
		generic map (5)
		port map(RS2_EX, LATCHER, CLK, RST, RS2_MEM);

	-- STAGE FOUR

	MEM_ADDRESS <= ALU_OUT_MEM;
	MEM_DATA <= ALU_OUT_MEM when MEMORY_ENABLE = '0' else
				RS2_DATA_MEM1 when MEMORY_RNOTW = '0' else
				(others => 'Z');

	RS2_MEM_EQ_RD_WB <= (not or_reduce( RS2_MEM xor RD_WB ) and ( not WB_STALL ));

	MUX_RS2_DATA_MEM1 : MUX
		generic map ( WORD_SIZE )
		port map ( RS2_DATA_MEM, MEM_DATA_WB, RS2_MEM_EQ_RD_WB, RS2_DATA_MEM1 );

	DCACHE : RWCACHE
		port map ( CLK, RST, MEMORY_ENABLE, MEMORY_RNOTW, MEM_ADDRESS, MEM_DATA, DCACHE_STALL, DRAM_ISSUE, DRAM_READNOTWRITE, DRAM_ADDRESS, DRAM_DATA, DRAM_READY );

	PIPEREG_RD_MEM: REGISTER_FDE
		generic map (5)
		port map(RD_MEM, '1', CLK, RST, RD_WB);

	PIPEREG_MEM_DATA: REGISTER_FDE
		generic map (32)
		port map(MEM_DATA, '1', CLK, RST, MEM_DATA_WB);

	-- STAGE FIVE

	RD_DATA_WB <= MEM_DATA_WB;

	-- Nothing

	--  GO!
end structural;
