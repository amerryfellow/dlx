library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use work.myTypes.all;
use work.cu.all;
--use work.all;

entity CU_UP is
	generic (
		MICROCODE_MEM_SIZE : integer := 57;		-- U Microcode Memory Size
--		OPCODE_SIZE :		integer := 6;		-- Op Code Size
--		FUNC_SIZE :			integer := 11;		-- Op Code Size
		ALU_OPC_SIZE :		integer := 2;		-- ALU Op Code Word Size
		CW_SIZE :			integer := 13		-- U Control Word Size
	);

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
		JUMPER:				out std_logic_vector(1 downto 0);
		PC_UPDATE:			out std_logic;

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
end CU_UP;

architecture RTL of CU_UP is
	signal INT_LUTOUT : std_logic_vector(19 downto 0);
	signal LUTOUT : std_logic_vector(19 downto 0);

	signal PIPE1	: std_logic_vector(19 downto 0) := (others => '0');
	signal PIPE2	: std_logic_vector(17 downto 0) := (others => '0');
	signal PIPE3	: std_logic_vector(10 downto 0) := (others => '0');
	signal PIPE4	: std_logic_vector(5 downto 0) := (others => '0');
	signal PIPE5	: std_logic_vector(1 downto 0) := (others => '0');

	signal INT_PC_UPDATE : std_logic;

	signal PIPEREG12 : std_logic_vector(17 downto 0) := (others => '0');
	signal PIPEREG23 : std_logic_vector(10 downto 0) := (others => '0');
	signal PIPEREG34 : std_logic_vector(5 downto 0) := (others => '0');
	signal PIPEREG45 : std_logic_vector(1 downto 0) := (others => '0');

	signal OPCODE :		OPCODE_TYPE;
	signal FUNC :		FUNC_TYPE;

	signal JMP_PREDICT_DELAYED : std_logic;

begin

	--
	-- LUTOUT bits
	-- EN1 | RF1 | RF2 | EN2 | S1 | S2 | ALU1 | ALU2 | EN3 | RM | WM | S3 | WF1
	--
	-- Link the outputs of the pipeline registers to the single control signals.
	--

	-- Pipelines
	PIPE1		<= LUTOUT;
	PIPEREG12	<= PIPE1(17 downto 0);
	PIPEREG23	<= PIPE2(10 downto 0);
	PIPEREG34	<= PIPE3(5 downto 0);
	PIPEREG45	<= PIPE4(1 downto 0);

	--
	-- Outputs
	--

	-- Stage IF
	JUMPER				<= PIPE1(19 downto 18);

	-- STAGE ID
	MUXRD_CTR			<= PIPE2(17);
	WRF_ENABLE			<= PIPE2(16);
	WRF_CALL			<= PIPE2(15);
	WRF_RET				<= PIPE2(14);
	WRF_RS1_ENABLE		<= PIPE2(13);
	WRF_RS2_ENABLE		<= PIPE2(12);
	WRF_RD_ENABLE		<= PIPE2(11);

	--Stage EXE
	PIPEREG2_ENABLE		<= PIPE3(10);
	MUXA_CTR			<= PIPE3(9);
	MUXB_CTR			<= PIPE3(8);
	ALU_FUNC			<= PIPE3(7 downto 6);

	-- Stage MEM
	PIPEREG3_ENABLE		<= PIPE4(5);
	MUXC_CTR			<= PIPE4(4);
	MEMORY_ENABLE		<= PIPE4(3);
	MEMORY_RNOTW		<= PIPE4(2);

	-- Stage WB
	PIPEREG4_ENABLE		<= PIPE5(1);
	MUXWB_CTR			<= PIPE5(0);

	--
	-- Inputs
	--

	OPCODE	<= IR(31 downto 31-OPCODE_SIZE+1);
	FUNC	<= IR(FUNC_SIZE-1 downto 0);

	--
	-- Pipeline management process
	--
	-- Updates the values of the internal signals and the pipeline registers
	--

	PROCESS_UPPIPES: process(CLK, RST)
	begin
		JMP_PREDICT_DELAYED <= JMP_PREDICT;

		if RST = '1' then
			PIPE2 <= (others => '0');
			PIPE3 <= (others => '0');
			PIPE4 <= (others => '0');
			PIPE5 <= (others => '0');

		elsif clk'event and clk = '1' then
			-- Bubble propagation in stage 2 when
			-- 1) Mispredicted branch
			-- 2) Instruction cache stall

			if (JMP_REAL xor JMP_PREDICT_DELAYED) = '1' or ICACHE_STALL = '1' then
				PIPE2 <= (others => '0');
			else
				PIPE2 <= PIPEREG12;
			end if;

			-- Bubble propagation in stage 3 when
			-- 1) Windowed Register File stall
			if WRF_STALL = '1' then
				PIPE3 <= (others => '0');
			else
				PIPE3 <= PIPEREG23;
			end if;

			PIPE4 <= PIPEREG34;
			PIPE5 <= PIPEREG45;
		end if;
	end process;

	--
	-- Look Up Table
	--
	-- Implements the instruction decode logic
	--

	PROCESS_LUT: process(clk,RST)
	begin
		if RST = '1' then
			INT_LUTOUT <= "00" & "0000000" & "0000" & "00000" & "00";

		elsif clk'event and clk = '1' then

			case (OPCODE) is

				-- Register - Register [ OPCODE(6) - RS1(5) - RS2(5) - RD(5) - FUNC(11) ]
				when RTYPE =>
					--report "RTYPE, Bitch!";
					case (FUNC) is
						when NOP		=> INT_LUTOUT <= "00" & "0000000" & "00000" & "0000" & "00";
						when RTYPE_ADD	=> INT_LUTOUT <= "00" & "0110110" & "01000" & "0000" & "01";
						when RTYPE_AND	=> INT_LUTOUT <= "00" & "0110110" & "01000" & "0000" & "10";
						when RTYPE_OR	=> INT_LUTOUT <= "00" & "0110110" & "01000" & "0000" & "11";
						when RTYPE_SUB	=> INT_LUTOUT <= "00" & "0110110" & "01000" & "0001" & "00";
						when RTYPE_XOR	=> INT_LUTOUT <= "00" & "0110110" & "01000" & "0001" & "01";
						when RTYPE_SGE	=> INT_LUTOUT <= "00" & "0110110" & "01000" & "0001" & "10";
						when RTYPE_SLE	=> INT_LUTOUT <= "00" & "0110110" & "01000" & "0001" & "11";
						when RTYPE_SLL	=> INT_LUTOUT <= "00" & "0110110" & "01000" & "0010" & "00";
						when RTYPE_SRL	=> INT_LUTOUT <= "00" & "0110110" & "01000" & "0010" & "01";
						when RTYPE_SNE	=> INT_LUTOUT <= "00" & "0110110" & "01000" & "0010" & "10";
						when RTYPE_SGT	=> INT_LUTOUT <= "00" & "0110110" & "01000" & "0010" & "11";

						when others		=> --report "I don't know how to handle this Rtype function!"; null;
					end case;

				when MULT				=> INT_LUTOUT <= "00" & "0100110" & "00000" & "0000" & "00";

				-- Jump [ OPCODE(6) - PCOFFSET(26) ]
				when JTYPE_J			=> INT_LUTOUT <= "11" & "0000000" & "00000" & "0000" & "00";
											report "Jumping!";
				when JTYPE_JAL			=> INT_LUTOUT <= "11" & "0000000" & "00000" & "0000" & "00";

				-- Branch [ OPCODE(6) - REG(5) - PCOFFSET(21) ]
				when BTYPE_BEQZ			=> INT_LUTOUT <= "01" & "0100100" & "00000" & "0000" & "00";
				when BTYPE_BNEZ			=> INT_LUTOUT <= "10" & "0100100" & "00000" & "0000" & "00";

				-- Memory [ OPCODE(6) - RDISPLACEMENT(5) - REG(5) - DISPLACEMENT(16) ]
				when MTYPE_LW			=> INT_LUTOUT <= "00" & "0100110" & "00000" & "0000" & "00";
				when MTYPE_SW			=> INT_LUTOUT <= "00" & "0100110" & "00000" & "0000" & "00";

				-- Immediate [ OPCODE(6) - RS1(5) - RD(5) - IMMEDIATE(16) ]
				when ITYPE_ADD			=> INT_LUTOUT <= "00" & "0100100" & "00000" & "0000" & "00";
				when ITYPE_AND			=> INT_LUTOUT <= "00" & "0100100" & "00000" & "0000" & "00";
				when ITYPE_OR			=> INT_LUTOUT <= "00" & "0100100" & "00000" & "0000" & "00";
				when ITYPE_SUB			=> INT_LUTOUT <= "00" & "0100100" & "00000" & "0000" & "00";
				when ITYPE_XOR			=> INT_LUTOUT <= "00" & "0100100" & "00000" & "0000" & "00";
				when ITYPE_SGE			=> INT_LUTOUT <= "00" & "0100100" & "00000" & "0000" & "00";
				when ITYPE_SLE			=> INT_LUTOUT <= "00" & "0100100" & "00000" & "0000" & "00";
				when ITYPE_SLL			=> INT_LUTOUT <= "00" & "0100100" & "00000" & "0000" & "00";
				when ITYPE_SRL			=> INT_LUTOUT <= "00" & "0100100" & "00000" & "0000" & "00";
				when ITYPE_SNE			=> INT_LUTOUT <= "00" & "0100100" & "00000" & "0000" & "00";
				when ITYPE_SGT			=> INT_LUTOUT <= "00" & "0100100" & "00000" & "0000" & "00";

				-- Eh boh!
				when others =>
--					report "I don't know how to handle this opcode!";
					null;
			end case;
		end if;
	end process;

	--
	-- Stall Unit
	--
	-- Implements the stall logic
	--

	PROCESS_STALL: process(CLK, RST)
	begin
		if clk'event and clk = '1' and RST = '0' then
--			if (
--				ICACHE_STALL = '1' or
--				WRF_STALL = '1' --or
--				(JMP_REAL xor JMP_PREDICT_DELAYED) = '1'
--			) then
--				INT_PC_UPDATE <= '0';
--			else
--				INT_PC_UPDATE <= '1';
--			end if;
--
--			if(INT_PC_UPDATE = '1') then
--				LUTOUT <= INT_LUTOUT;
--			else
--				LUTOUT <= (others => '0');
--			end if;
			PC_UPDATE <= INT_PC_UPDATE;
		end if;
	end process;

INT_PC_UPDATE <= '0' when ICACHE_STALL = '1' or WRF_STALL = '1' else '1';
--LUTOUT <= INT_LUTOUT;
	LUTOUT <= INT_LUTOUT when INT_PC_UPDATE = '1' else (others => '0');

end RTL;

