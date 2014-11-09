library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use work.alu_types.all;
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
		ICACHE_STALL:		in std_logic;		-- The instruction cache is in stall
		WRF_STALL:			in std_logic;		-- The WRF is busy
		DCACHE_STALL:		in std_logic;		-- The rwcache is busy
		ISZERO :			in std_logic;		-- Needed for condizional jumps
		JMP_ADDRESS :		in std_logic_vector(31 downto 0);
		NPC_ADDRESS :		in std_logic_vector(31 downto 0);
		PC :				out std_logic_vector(31 downto 0);

		-- Outputs
		JUMP:				out std_logic;
		MUXIR_CTR:			out std_logic;

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
		MUXWB_CTR:			out std_logic;

		ID_STALL:			out std_logic;
		EXE_STALL:			out std_logic;
		MEM_STALL:			out std_logic;
		WB_STALL:			out std_logic
	);
end CU_UP;

architecture RTL of CU_UP is
	signal LUTOUT : std_logic_vector(19 downto 0);

	signal PIPE1	: std_logic_vector(19 downto 0) := (others => '0');
	signal PIPE2	: std_logic_vector(10 downto 0) := (others => '0');
	signal PIPE3	: std_logic_vector(3 downto 0) := (others => '0');
	signal PIPE4	: std_logic_vector(1 downto 0) := (others => '0');

	signal JUMPER	: std_logic_vector(1 downto 0);
	signal JUMPER_DELAYED	: std_logic_vector(1 downto 0);

	signal PIPEREG12 : std_logic_vector(10 downto 0) := (others => '0');
	signal PIPEREG23 : std_logic_vector(3 downto 0) := (others => '0');
	signal PIPEREG34 : std_logic_vector(1 downto 0) := (others => '0');

	signal PIPE1_STALL : std_logic;
	signal PIPE2_STALL : std_logic;
	signal PIPE3_STALL : std_logic;
	signal PIPE4_STALL : std_logic;

	signal OPCODE :		OPCODE_TYPE;
	signal FUNC :		FUNC_TYPE;

	signal JMP_PREDICT_DELAYED : std_logic;
	signal STALL_DELAYED : std_logic;
begin

	--
	-- LUTOUT bits
	-- EN1 | RF1 | RF2 | EN2 | S1 | S2 | ALU1 | ALU2 | EN3 | RM | WM | S3 | WF1
	--
	-- Link the outputs of the pipeline registers to the single control signals.
	--

	-- Pipelines
--	PIPE1		<= LUTOUT;
	PIPEREG12	<= PIPE1(10 downto 0);
	PIPEREG23	<= PIPE2(3 downto 0);
	PIPEREG34	<= PIPE3(1 downto 0);

	--
	-- Outputs
	--

	ID_STALL	<= PIPE1_STALL;
	EXE_STALL	<= PIPE2_STALL;
	MEM_STALL	<= PIPE3_STALL;
	WB_STALL	<= PIPE4_STALL;

	-- STAGE ID
	MUXIMMEDIATE_CTR	<= PIPE1(19);
	MUXJMPADDRESS_CTR	<= PIPE1(18);
	MUXRD0_CTR			<= PIPE1(17);
	MUXRD_CTR			<= PIPE1(16);
	WRF_ENABLE			<= PIPE1(15);
	WRF_CALL			<= PIPE1(14);
	WRF_RET				<= PIPE1(13);
	WRF_RS1_ENABLE		<= PIPE1(12);
	WRF_RS2_ENABLE		<= PIPE1(11);

	--Stage EXE
	MUXALUOUT_CTR		<= PIPE2(10);
	MUXALU_CTR			<= PIPE2(9);
	ALU_FUNC			<= PIPE2(8 downto 4);

	-- Stage MEM
	MEMORY_ENABLE		<= PIPE3(3);
	MEMORY_RNOTW		<= PIPE3(2);

	-- Stage WB
	WRF_RD_ENABLE		<= PIPE4(1);
	MUXWB_CTR			<= PIPE4(0);

	--
	-- Inputs
	--

	OPCODE	<= IR(31 downto 31-OPCODE_SIZE+1);
	FUNC	<= IR(FUNC_SIZE-1 downto 0);

	--
	-- Look Up Table
	--
	-- Implements the instruction decode logic
	--

--	PROCESS_LUT: process(RST, OPCODE, FUNC)
	PROCESS_LUT: process(RST, CLK)
		variable JMP_REAL : std_logic;
		variable JMP_REAL_LATCHED : std_logic;
		variable JMP_ADDRESS_LATCHED : std_logic_vector( 31 downto 0 );
		variable INT_LUTOUT : std_logic_vector( 19 downto 0 );
	begin
		-- If reset OR stall -> feed NOPS
		if RST = '1' then
			INT_LUTOUT := "000000000" & "0000000" & "00" & "00";
			PIPE2 <= (others => '0');
			PIPE3 <= (others => '0');
			PIPE4 <= (others => '0');
			PC <= (others => '0');
			JUMPER <= "00";
			JUMP <= '0';
			JMP_REAL := '0';
			JMP_REAL_LATCHED := '0';
			JMP_PREDICT_DELAYED <= '0';

		elsif clk'event and clk = '1' then
--		else
			JUMPER <= "00";

			case (OPCODE) is

				-- Register - Register [ OPCODE(6) - RS1(5) - RS2(5) - RD(5) - FUNC(11) ]
				when RTYPE =>
					--report "RTYPE, Bitch!";
					case (FUNC) is
						when RTYPE_NOP	=> INT_LUTOUT := "000000000" & "0000000"	 & "00" & "00";
						when RTYPE_ADD	=> INT_LUTOUT := "000110011" & "01" & ALUADD & "00" & "10";
						when RTYPE_AND	=> INT_LUTOUT := "000110011" & "01" & ALUAND & "00" & "10";
						when RTYPE_OR	=> INT_LUTOUT := "000110011" & "01" & ALUOR  & "00" & "10";
						when RTYPE_SUB	=> INT_LUTOUT := "000110011" & "01" & ALUSUB & "00" & "10";
						when RTYPE_XOR	=> INT_LUTOUT := "000110011" & "01" & ALUXOR & "00" & "10";
						when RTYPE_SLL	=> INT_LUTOUT := "000110011" & "01" & ALUSLL & "00" & "10";
						when RTYPE_SRL	=> INT_LUTOUT := "000110011" & "01" & ALUSRL & "00" & "10";
						when RTYPE_SRA	=> INT_LUTOUT := "000110011" & "01" & ALUSRA & "00" & "10";
						when RTYPE_SEQ	=> INT_LUTOUT := "000110011" & "01" & ALUSEQ & "00" & "10";
						when RTYPE_SNE	=> INT_LUTOUT := "000110011" & "01" & ALUSNE & "00" & "10";
						when RTYPE_SGE	=> INT_LUTOUT := "000110011" & "01" & ALUSGE & "00" & "10";
						when RTYPE_SGT	=> INT_LUTOUT := "000110011" & "01" & ALUSGT & "00" & "10";
						when RTYPE_SLE	=> INT_LUTOUT := "000110011" & "01" & ALUSLE & "00" & "10";
						when RTYPE_SLT	=> INT_LUTOUT := "000110011" & "01" & ALUSLT & "00" & "10";
						when RTYPE_SGEU	=> INT_LUTOUT := "000110011" & "01" & ALUSGEU & "00" & "10";
						when RTYPE_SGTU	=> INT_LUTOUT := "000110011" & "01" & ALUSGTU & "00" & "10";
						when RTYPE_SLEU	=> INT_LUTOUT := "000110011" & "01" & ALUSLEU & "00" & "10";
						when RTYPE_SLTU	=> INT_LUTOUT := "000110011" & "01" & ALUSLTU & "00" & "10";

						when others		=> --report "I don't know how to handle this Rtype function!"; null;
					end case;

				when NOP				=> INT_LUTOUT := "000000000" & "0000000" & "00" & "00";

				-- Jump [ OPCODE(6) - PCOFFSET(26) ]
				when JTYPE_J			=> INT_LUTOUT := "000000000" & "0000000" & "00" & "00";
											JUMPER <= "11";
				when JTYPE_JAL			=> INT_LUTOUT := "101000000" & "1000000" & "00" & "10";
											JUMPER <= "11";
				when JTYPE_JR			=> INT_LUTOUT := "010010010" & "0000000" & "00" & "00";
											JUMPER <= "11";

				-- Branch [ OPCODE(6) - REG(5) - PCOFFSET(21) ]
				when BTYPE_BEQZ			=> INT_LUTOUT := "000010011" & "0000000" & "00" & "00";
											JUMPER <= "01";
				when BTYPE_BNEZ			=> INT_LUTOUT := "000010011" & "0000000" & "00" & "00";
											JUMPER <= "10";

				-- Memory [ OPCODE(6) - RDISPLACEMENT(5) - REG(5) - DISPLACEMENT(16) ]
				when MTYPE_LW			=> INT_LUTOUT := "000010010" & "00" & ALUADD & "11" & "10";
				when MTYPE_SW			=> INT_LUTOUT := "000010011" & "00" & ALUADD & "10" & "00";

				-- Immediate [ OPCODE(6) - RS1(5) - RD(5) - IMMEDIATE(16) ]
				when ITYPE_ADD			=> INT_LUTOUT := "000010010" & "00" & ALUADD & "00" & "10";
				when ITYPE_AND			=> INT_LUTOUT := "000010010" & "00" & ALUAND & "00" & "10";
				when ITYPE_OR			=> INT_LUTOUT := "000010010" & "00" & ALUOR  & "00" & "10";
				when ITYPE_SUB			=> INT_LUTOUT := "000010010" & "00" & ALUSUB & "00" & "10";
				when ITYPE_XOR			=> INT_LUTOUT := "000010010" & "00" & ALUXOR & "00" & "10";
				when ITYPE_SLL			=> INT_LUTOUT := "000010010" & "00" & ALUSLL & "00" & "10";
				when ITYPE_SRL			=> INT_LUTOUT := "000010010" & "00" & ALUSRL & "00" & "10";
				when ITYPE_SRA			=> INT_LUTOUT := "000010010" & "00" & ALUSRA & "00" & "10";
				when ITYPE_SEQ			=> INT_LUTOUT := "000010010" & "00" & ALUSEQ & "00" & "10";
				when ITYPE_SNE			=> INT_LUTOUT := "000010010" & "00" & ALUSNE & "00" & "10";
				when ITYPE_SGE			=> INT_LUTOUT := "000010010" & "00" & ALUSGE & "00" & "10";
				when ITYPE_SGT			=> INT_LUTOUT := "000010010" & "00" & ALUSGT & "00" & "10";
				when ITYPE_SLE			=> INT_LUTOUT := "000010010" & "00" & ALUSLE & "00" & "10";
				when ITYPE_SLT			=> INT_LUTOUT := "000010010" & "00" & ALUSLT & "00" & "10";
				when ITYPE_SGEU			=> INT_LUTOUT := "000010010" & "00" & ALUSGEU & "00" & "10";
				when ITYPE_SGTU			=> INT_LUTOUT := "000010010" & "00" & ALUSGTU & "00" & "10";
				when ITYPE_SLEU			=> INT_LUTOUT := "000010010" & "00" & ALUSLEU & "00" & "10";
				when ITYPE_SLTU			=> INT_LUTOUT := "000010010" & "00" & ALUSLTU & "00" & "10";

				-- Eh boh!
				when others =>
--					report "I don't know how to handle this opcode!";
					null;
			end case;

			-- JUMPS AND STALLS

			JUMPER_DELAYED <= JUMPER;
			STALL_DELAYED <= ICACHE_STALL or WRF_STALL or DCACHE_STALL;

			JMP_REAL := (
					( not or_reduce(JUMPER xor "01") and ISZERO ) or
					( not or_reduce(JUMPER xor "10") and not ISZERO ) or
					( not or_reduce(JUMPER xor "11") )
				) xor JMP_PREDICT_DELAYED;

			if STALL_DELAYED = '0' then
				JMP_REAL_LATCHED := JMP_REAL;
				JMP_ADDRESS_LATCHED := JMP_ADDRESS;
			end if;

			JUMP <= JMP_REAL_LATCHED;
			JMP_PREDICT_DELAYED <= JMP_PREDICT;

			-- Any stall? Don't update PC, feed NOPS
			if ICACHE_STALL = '0' and WRF_STALL = '0' and DCACHE_STALL = '0' then
				if JMP_REAL_LATCHED = '1' then
					PC <= JMP_ADDRESS_LATCHED;
					report "************************************************* LAT JMP" & integer'image(conv_integer(unsigned(JMP_ADDRESS_LATCHED)));
				else
					PC <= NPC_ADDRESS;
				end if;
			end if;

			-- If there is a stall later on in the pipe, freeze everything
			if DCACHE_STALL = '0' then
				-- Bubble propagation in stage 2 when
				-- 1) Mispredicted branch
				-- 2) Instruction cache stall
				if JMP_REAL_LATCHED = '1' or ICACHE_STALL = '1' then
--				if ICACHE_STALL = '1' then
					PIPE1 <= (others => '0');
					PIPE1_STALL <= '1';
				else
					PIPE1 <= INT_LUTOUT;
					PIPE1_STALL <= '0';
				end if;

				-- Bubble propagation in stage 3 when
				-- 1) Windowed Register File stall
				if WRF_STALL = '1' then
					PIPE2 <= (others => '0');
					PIPE2_STALL <= '1';
				else
					PIPE2 <= PIPEREG12;
					PIPE2_STALL <= PIPE1_STALL;
				end if;

				PIPE3_STALL <= PIPE2_STALL;
				PIPE3 <= PIPEREG23;

				PIPE4 <= PIPEREG34;
				PIPE4_STALL <= PIPE3_STALL;
			else
				PIPE1_STALL <= '1';
				PIPE2_STALL <= '1';
				PIPE3_STALL <= '1';
				PIPE4_STALL <= '1';

				PIPE4 <= (others => '0');
			end if;

			MUXIR_CTR <= not DCACHE_STALL ;
		end if;
	end process;


end RTL;

