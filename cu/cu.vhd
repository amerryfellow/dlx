library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;
use work.cu.all;
--use work.all;

entity CU_UP is
	generic (
		MICROCODE_MEM_SIZE				: integer := 57;	-- U Microcode Memory Size
															-- Memory Size
		OP_CODE_SIZE	: integer := 6;						-- Op Code Size
		ALU_OPC_SIZE	: integer := 2;						-- ALU Op Code Word Size
		CW_SIZE			: integer := 13						-- U Control Word Size
	);

	port (
		Clk :				in std_logic;		-- Clock
		Rst :				in std_logic;		-- Reset:Active-Low
		OPCODE :			in std_logic_vector(OP_CODE_SIZE - 1 downto 0);

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
		WRF_BUSY:			in std_logic;

		PIPEREG2_ENABLE:	out std_logic;
		MUXA_CTR:			out std_logic;
		MUXB_CTR:			out std_logic;
		ALU_FUNC:			out std_logic_vector(1 downto 0);

		PIPEREG3_ENABLE:	out std_logic;
		MUXC_CTR:			out std_logic;
		MEMORY_ENABLE:		out std_logic;
		MEMORY_RNOTW:		out std_logic;

		PIPEREG4_ENABLE:	out std_logic;
		MUXWB_CTR:			out std_logic;
	);
end CU_UP;

entity HW_CU is
	port (
				-- FIRST PIPE STAGE OUTPUTS
		EN1		: out std_logic;					-- enables the register file and the pipeline registers
		RF1		: out std_logic;					-- enables the read port 1 of the register file
		RF2		: out std_logic;					-- enables the read port 2 of the register file
		WF1		: out std_logic;					-- enables the write port of the register file

		-- SECOND PIPE STAGE OUTPUTS
		EN2		: out std_logic;					-- enables the pipe registers
		S1		: out std_logic;					-- input selection of the first multiplexer
		S2		: out std_logic;					-- input selection of the second multiplexer
		ALU1	: out std_logic;					-- alu control bit
		ALU2	: out std_logic;					-- alu control bit

		-- THIRD PIPE STAGE OUTPUTS
		EN3		: out std_logic;					-- enables the memory and the pipeline registers
		RM		: out std_logic;					-- enables the read-out of the memory
		WM		: out std_logic;					-- enables the write-in of the memory
		S3		: out std_logic;					-- input selection of the multiplexer

		-- INPUTS
		IR		: in  std_logic_vector(31 downto 0);	-- Instruction Register
		Clk		: in std_logic;
		Rst		: in std_logic						-- Active Low
	);
end HW_CU;

architecture HW_CU_RTL of HW_CU is
	signal LUTOUT : std_logic_vector(12 downto 0);

	signal PIPE1	: std_logic_vector(12 downto 0) := (others => '0');
	signal PIPE2	: std_logic_vector(9 downto 0) := (others => '0');
	signal PIPE3	: std_logic_vector(4 downto 0) := (others => '0');
	signal PIPE3	: std_logic_vector(4 downto 0) := (others => '0');
	signal PIPE3	: std_logic_vector(4 downto 0) := (others => '0');

	signal PIPEREG12 : std_logic_vector(9 downto 0) := (others => '0');
	signal PIPEREG23 : std_logic_vector(4 downto 0) := (others => '0');
	signal PIPEREG23 : std_logic_vector(4 downto 0) := (others => '0');
	signal PIPEREG23 : std_logic_vector(4 downto 0) := (others => '0');

	signal OPCODE	: std_logic_vector(OPCODE_SIZE -1 downto 0) := (others => '0');
	signal FUNC		: std_logic_vector(FUNC_SIZE -1 downto 0) := (others => '0');

begin

	--
	-- LUTOUT bits
	-- EN1 | RF1 | RF2 | EN2 | S1 | S2 | ALU1 | ALU2 | EN3 | RM | WM | S3 | WF1
	--
	-- Link the outputs of the pipeline registers to the single control signals.
	--
	EN1		<= PIPE1(12);
	RF1		<= PIPE1(11);
	RF2		<= PIPE1(10);
	EN2		<= PIPE2(9);
	S1		<= PIPE2(8);
	S2		<= PIPE2(7);
	ALU1	<= PIPE2(6);
	ALU2	<= PIPE2(5);
	EN3		<= PIPE3(4);
	RM		<= PIPE3(3);
	WM		<= PIPE3(2);
	S3		<= PIPE3(1);
	WF1		<= PIPE3(0);

	PIPE1		<= LUTOUT;
	PIPEREG12	<= PIPE1(9 downto 0);
	PIPEREG23	<= PIPE2(4 downto 0);

	OPCODE	<= IR(31 downto 31-6);
	FUNC	<= IR(10 downto 0);

	--
	-- Pipeline management process
	--
	-- Updates the values of the internal signals and the pipeline registers
	--

	PROCESS_UPPIPES: process(clk,rst)
	begin
		if rst = '0' then
			PIPE2 <= (others => '0');
			PIPE3 <= (others => '0');
			PIPE4 <= (others => '0');
			PIPE5 <= (others => '0');

		elsif clk'event and clk = '1' then
			PIPE2 <= PIPEREG12;
			PIPE3 <= PIPEREG23;
			PIPE4 <= PIPEREG34;
			PIPE5 <= PIPEREG45;
		end if;
	end process;

	--
	-- Look Up Table
	--
	-- Implements the instruction decode logic
	--

	PROCESS_LUT: process(clk,rst)
	begin
		if rst = '0' then
			LUTOUT <= "000" & "00000" & "00000";

		elsif clk'event and clk = '1' then

	-- EN1 | RF1 | RF2 |||||| EN2 | S1 | S2 | ALU1 | ALU2 |||||| EN3 | RM | WM | S3 | WF1
			case (OPCODE) is

				-- Register - Register [ OPCODE(6) - RS1(5) - RS2(5) - RD(5) - FUNC(11) ]
				when RTYPE =>
					case (FUNC) is
						when RTYPE_ADD	=> LUTOUT <= "111" & "10100" & "10001";
						when RTYPE_AND	=> LUTOUT <= "111" & "10100" & "10001";
						when RTYPE_OR	=> LUTOUT <= "111" & "10111" & "10001";
						when RTYPE_SUB	=> LUTOUT <= "111" & "10101" & "10001";
						when RTYPE_XOR	=> LUTOUT <= "111" & "10111" & "10001";
						when RTYPE_SGE	=> LUTOUT <= "111" & "10111" & "10001";
						when RTYPE_SLE	=> LUTOUT <= "111" & "10111" & "10001";
						when RTYPE_SLL	=> LUTOUT <= "111" & "10111" & "10001";
						when RTYPE_SRL	=> LUTOUT <= "111" & "10111" & "10001";
						when RTYPE_SNE	=> LUTOUT <= "111" & "10111" & "10001";
						when RTYPE_SGT	=> LUTOUT <= "111" & "10111" & "10001";
						when NOP		=> LUTOUT <= "000" & "00000" & "00000";

						when others		=> report "I don't know how to handle this Rtype function!"; null;
					end case;

				when MULT				=> LUTOUT <= "111" & "10111" & "10001";

				-- Jump [ OPCODE(6) - PCOFFSET(26) ]
				when JTYPE_J			=> LUTOUT <= "111" & "10111" & "10001";
				when JTYPE_JAL			=> LUTOUT <= "111" & "10111" & "10001";

				-- Branch [ OPCODE(6) - REG(5) - PCOFFSET(21) ]
				when BTYPE_BEQZ			=> LUTOUT <= "111" & "10111" & "10001";
				when BTYPE_BNEZ			=> LUTOUT <= "111" & "10111" & "10001";

				-- Memory [ OPCODE(6) - RDISPLACEMENT(5) - REG(5) - DISPLACEMENT(16) ]
				when MTYPE_LW			=> LUTOUT <= "111" & "10111" & "10001";
				when MTYPE_SW			=> LUTOUT <= "111" & "10111" & "10001";

				-- Immediate [ OPCODE(6) - RS1(5) - RD(5) - IMMEDIATE(16) ]
				when ITYPE_ADD			=> LUTOUT <= "111" & "10100" & "10001";
				when ITYPE_AND			=> LUTOUT <= "111" & "10100" & "10001";
				when ITYPE_OR			=> LUTOUT <= "111" & "10111" & "10001";
				when ITYPE_SUB			=> LUTOUT <= "111" & "10101" & "10001";
				when ITYPE_XOR			=> LUTOUT <= "111" & "10111" & "10001";
				when ITYPE_SGE			=> LUTOUT <= "111" & "10111" & "10001";
				when ITYPE_SLE			=> LUTOUT <= "111" & "10111" & "10001";
				when ITYPE_SLL			=> LUTOUT <= "111" & "10111" & "10001";
				when ITYPE_SRL			=> LUTOUT <= "111" & "10111" & "10001";
				when ITYPE_SNE			=> LUTOUT <= "111" & "10111" & "10001";
				when ITYPE_SGT			=> LUTOUT <= "111" & "10111" & "10001";

				-- Eh boh!
				when others =>
					report "I don't know how to handle this opcode!";
					null;
			end case;
		end if;
	end process;
end HW_CU_RTL;

