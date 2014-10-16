library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use WORK.alu_types.all;

entity DLX is
	generic (
		N : integer := numBit
	);

	port (
		FUNC:			in TYPE_OP;
		DATA1, DATA2:	in std_logic_vector(N-1 downto 0);
		OUTALU:			out std_logic_vector(N-1 downto 0)
	);
end DLX;

architecture GIANLUCA of DLX is
	component MUX is
		generic (
			N:			integer
		);

		port (
			A:		in	std_logic_vector(N-1 downto 0);
			B:		in	std_logic_vector(N-1 downto 0);
			SEL:	in	std_logic;
			Y:		out	std_logic_vector(N-1 downto 0)
		);
	end component;

	component IRAM is
		generic (
			RAM_DEPTH :	integer := 48;
			I_SIZE :	integer := 32
		);

		port (
			Rst :	in  std_logic;
			Addr :	in  std_logic_vector(I_SIZE - 1 downto 0);
			Dout :	out std_logic_vector(I_SIZE - 1 downto 0)
		);
	end component;

	component PIPEREG is
		generic (
			N		: integer;
			REGS	: integer
		);

		port (
			CLK:		in	std_logic;							-- Clock
			ENABLE:		in	std_logic;							-- Enable
			RESET:		in	std_logic;							-- Reset
			I:			in array(0 to REGS) of std_logic_vector(N-1 downto 0);
			O:			out array(0 to REGS) of std_logic_vector(N-1 downto 0)
		);
	end component;

	component SRF is
		generic(
			NBIT:	integer;
			NREG:	natural
		);

		port (
			CLK:		IN std_logic;
			RESET:		IN std_logic;
			ENABLE:		IN std_logic;

			RNOTW:			IN std_logic;								-- Read not Write
			ADDR:		IN std_logic_vector(LOG(NREG)-1 downto 0);		-- Read Address

			DIN:		IN std_logic_vector(NBIT-1 downto 0);			-- Write data
			DOUT:		OUT std_logic_vector(NBIT-1 downto 0);			-- Read data
		);
	end component;

	component WRF is
		generic (
			NBIT:	integer	:= numBit;
			M:		integer := numGlobals;
			F:		integer := numWindows;
			N:		integer := numRegsPerWin;
			NREG:	integer := numGlobals + 2*numWindows*numRegsPerWin;
			LOGN:	integer := LOG(numRegsPerWin)
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

			ADDR_WR:		IN std_logic_vector(LOG(NREG)-1 downto 0);		-- Write Address
			ADDR_RD1:		IN std_logic_vector(LOG(NREG)-1 downto 0);		-- Read Address 1
			ADDR_RD2:		IN std_logic_vector(LOG(NREG)-1 downto 0);		-- Read Address 2

			DATAIN:			IN std_logic_vector(NBIT-1 downto 0);			-- Write data
			OUT1:			OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 1
			OUT2:			OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 2

			MEMBUS:			INOUT std_logic_vector(NBIT-1 downto 0);		-- Memory Data Bus
			MEMCTR:			OUT std_logic_vector(10 downto 0);				-- Memory Control Signals
			BUSY:			OUT std_logic									-- The register file is busy
		);
	end component;

	component SGNEXT is
		generic (
			INBITS:		integer;
			OUTBITS:	integer;
		);

		port(
			DIN :		in std_logic_vector (INBITS-1 downto 0);
			DOUT :		out std_logic_vector (OUTBITS-1 downto 0);
		);
	end component;

	component ALU is
		generic (
			N : integer
		);

		port (
			FUNC:			in TYPE_OP;
			DATA1, DATA2:	in std_logic_vector(N-1 downto 0);
			OUTALU:			out std_logic_vector(N-1 downto 0)
		);
	end component;

	component INCREMENTER is
		generic (
			N: integer
		);

		port (
			A: in std_logic_vector (N-1 downto 0);
			Y: out std_logic_vector(N-1 downto 0)
		);
	end component;

	signal ZERO_VECT:		std_logic_vector(N-1 downto 0);

	-- CONTROL SIGNALS
	signal PIPEREG1_ENABLE: std_logic;
	signal PIPEREG2_ENABLE: std_logic;
	signal PIPEREG3_ENABLE: std_logic;
	signal PIPEREG4_ENABLE: std_logic;

	signal MUXBOOT_CTR:		std_logic;

	signal MUXRD_CTR:		std_logic;
	signal WRF_ENABLE:		std_logic;
	signal WRF_CALL:		std_logic;
	signal WRF_RET:			std_logic;
	signal WRF_RS1_ENABLE:	std_logic;
	signal WRF_RS2_ENABLE:	std_logic;
	signal WRF_RD_ENABLE:	std_logic;
	signal WRF_MEM_BUS:		std_logic;
	signal WRF_MEM_CTR:		std_logic;
	signal WRF_BUSY:		std_logic;
	signal CMP_EQZ:			std_logic;

	signal MUXA_CTR:		std_logic;
	signal MUXB_CTR:		std_logic;
	signal ALU_FUNC:		std_logic_vector(1 downto 0);

	signal MUXC_CTR:		std_logic;
	signal MEMORY_ENABLE:	std_logic;
	signal MEMORY_RNOTW:	std_logic;

	signal MUXWB_CTR:		std_logic;

	-- FIRST STAGE
	signal PC:				std_logic_vector(N-1 downto 0);
	signal IR:				std_logic_vector(N-1 downto 0);
	signal NPC:				std_logic_vector(N-1 downto 0);
	signal IPC:				std_logic_vector(N-1 downto 0);
	signal JMP_PREDICT:		std_logic := '0';					-- '0' NOT TAKEN ; '1' TAKEN
	signal NPC_REAL:		std_logic_vector(N-1 downto 0);

	-- SECOND STAGE
	signal IR_RF:			std_logic_vector(N-1 downto 0);
	signal NPC_RF:			std_logic_vector(N-1 downto 0);
	signal RS1:				std_logic_vector(N-1 downto 0);
	signal RS2:				std_logic_vector(N-1 downto 0);
	signal RD:				std_logic_vector(N-1 downto 0);
	signal DATAIN:			std_logic_vector(N-1 downto 0);
	signal IM16:			std_logic_vector(N-1 downto 0);
	signal IM:				std_logic_vector(N-1 downto 0);
	signal REGA:			std_logic_vector(N-1 downto 0);
	signal REGB:			std_logic_vector(N-1 downto 0);
	signal ZERO_OUT:		std_logic;
	signal JMP_REAL:		std_logic;

	-- THIRD STAGE
	signal NPC_EX:			std_logic_vector(N-1 downto 0);
	signal REGA_EX:			std_logic_vector(N-1 downto 0);
	signal REGB_EX:			std_logic_vector(N-1 downto 0);
	signal RD:				std_logic_vector(N-1 downto 0);
	signal IM_EX:			std_logic_vector(N-1 downto 0);
	signal RD_EX:			std_logic_vector(N-1 downto 0);
	signal MUXA_OUT:		std_logic_vector(N-1 downto 0);
	signal MUXB_OUT:		std_logic_vector(N-1 downto 0);
	signal ALU_OUT:			std_logic_vector(N-1 downto 0);

	-- FOURTH STAGE
	signal NPC_MEM:			std_logic_vector(N-1 downto 0);
	signal CMP_OUT_MEM:		std_logic_vector(N-1 downto 0);
	signal ALU_OUT_MEM:		std_logic_vector(N-1 downto 0);
	signal IM_MEM:			std_logic_vector(N-1 downto 0);
	signal RD_MEM:			std_logic_vector(N-1 downto 0);
	signal MUXC_OUT:		std_logic_vector(N-1 downto 0);
	signal MUXPC_OUT:		std_logic_vector(N-1 downto 0);
	signal MEM_OUT:			std_logic_vector(N-1 downto 0);

	-- FIFTH STAGE
	signal ALU_OUT_WB:		std_logic_vector(N-1 downto 0);
	signal MEM_OUT_WB:		std_logic_vector(N-1 downto 0);
	signal MUXWB_OUT:		std_logic_vector(N-1 downto 0);
	signal RD_WB:			std_logic_vector(N-1 downto 0);

	begin
		ZERO_VECT	<= (others => '0');

		-- First Pipeline register IF -> ID
		PIPEREG1: PIPEREG
			generic map (N, 2)
			port map (CLK, PIPEREG1_ENABLE, RESET, (NPC, IR), (NPC_RF, IR_RF));

		-- Second Pipeline register ID -> EX
		PIPEREG2: PIPEREG
			generic map (N, 5)
			port map (CLK, PIPEREG2_ENABLE, RESET, (NPC_RF, REGA, REGB, IM, RD), (NPC_EX, REGA_EX, REGB_EX, IM_EX, RD_EX));

		-- Third Pipeline register EX -> MEM
		PIPEREG3: PIPEREG
			generic map (N, 5)
			port map (CLK, PIPEREG3_ENABLE, RESET, (NPC_EX, CMP_OUT, ALU_OUT, IM_EX, RD_EX), (NPC_MEM, CMP_OUT_MEM, ALU_OUT_MEM, IM_MEM, RD_MEM));

		-- Fourth Pipeline register MEM -> WB
		PIPEREG4: PIPEREG
			generic map (N, 2)
			port map (CLK, PIPEREG4_ENABLE, RESET, (ALU_OUT_MEM, MEM_OUT, RD_MEM), (ALU_OUT_WB, MEM_OUT_WB, RD_WB));

		--
		-- FIRST STAGE
		--

--		MUXBOOT: MUX
--			generic map (N)
--			port map (MUXPC_OUT, ZERO_VECT, RESET, PC);

		NPCEVAL: INCREMENTER
			generic map (N)
			port map (PC, IPC);

		STALLER: LATCH
			generic map (N)
			port map (NPC_RF, PC_UPDATE, '0', PC);

		ICACHE: ICACHE
			port map(RESET, PC, IR);

		--
		-- SECOND STAGE
		--

		RS1		:= IR_RF(10 downto 6);
		RS2		:= IR_RF(16 downto 11);
		IM16	:= IR_RF(31 downto 17);

		MUXBOOT: MUX
			generic map (6)
			port map (IR_RF(16 downto 11), IR(21 downto 17), MUXRD_CTR, RD);

		REGISTERFILE: WRF
			generic map (N, registerfileNumGlobals, registerfileNumWindows, registerfileNumRegsPerWin)
			port map (CLK, RESET, WRF_ENABLE, WRF_CALL, WRF_RET, WRF_RS1_ENABLE, WRF_RS2_ENABLE, WRF_RD_ENABLE, RS1, RS2, RD_WB, MUXWB_OUT, REGA, REGB, WRF_MEM_BUS, WRF_MEM_CTR, WRF_BUSY);

		-- WRF_ENABLE, WRF_CALL, WRF_RET, WRF_RS1_ENABLE, WRF_RS2_ENABLE, WRF_RD_ENABLE

		SGNEXTENDER: SGNEXT
			generic map (16, 32)
			port map (IM16, IM);

		ZERO_OUT <= not or_reduce(REGA);

		CMP: MUX
			generic map (1)
			port map (ZERO_OUT, not ZERO_OUT, CMP_EQZ, JMP_REAL);

		--
		-- THIRD STAGE
		--

		MUXA: MUX
			generic map (N)
			port map (NPC_EX, REGA_EX, MUXA_CTR, MUXA_OUT);

		MUXB: MUX
			generic map (N)
			port map (REGB_EX, IM_EX, MUXB_CTR, MUXB_OUT);

		ALUI: ALU
			generic map (N)
			port map (ALU_FUNC, MUXA_OUT, MUXB_OUT, ALU_OUT)

		--
		-- FOURTH STAGE
		--

		MUXC: MUX
			generic map (N)
			port map (CMP_OUT_MEM, ZERO_VECT, MUXC_CTR, MUXC_OUT);

		MUXPC: MUX
			generic map (N)
			port map (NPC_MEM, ALU_OUT_MEM, MUXC_OUT, MUXPC_OUT);

		MEMORY: SRF
			generic map (N, 1024)
			port map(CLK, RESET, MEMORY_ENABLE, MEMORY_RNOTW, ALU_OUT_MEM, IM_MEM, MEM_OUT);

		--
		-- FIFTH STAGE
		--

		MUXWB: MUX
			generic map (N)
			port map (ALU_OUT_WB, MEM_OUT_WB, MUXWB_CTR, MUXWB_OUT);

		POSITION	<= conv_integer(DATA2); -- Position must be lower than N-1

		P_ALU : process (FUNC, DATA1, DATA2)
		begin
			end case;
		end process;
end BEHAVIORAL;

