library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.myTypes.all;
--use ieee.numeric_std.all;
--use work.all;

entity HW_CU is
	port (
		-- FIRST PIPE STAGE OUTPUTS
		EN1    : out std_logic;               -- enables the register file and the pipeline registers
		RF1    : out std_logic;               -- enables the read port 1 of the register file
		RF2    : out std_logic;               -- enables the read port 2 of the register file
		WF1    : out std_logic;               -- enables the write port of the register file

		-- SECOND PIPE STAGE OUTPUTS
		EN2    : out std_logic;               -- enables the pipe registers
		S1     : out std_logic;               -- input selection of the first multiplexer
		S2     : out std_logic;               -- input selection of the second multiplexer
		ALU1   : out std_logic;               -- alu control bit
		ALU2   : out std_logic;               -- alu control bit

		-- THIRD PIPE STAGE OUTPUTS
		EN3    : out std_logic;               -- enables the memory and the pipeline registers
		RM     : out std_logic;               -- enables the read-out of the memory
		WM     : out std_logic;               -- enables the write-in of the memory
		S3     : out std_logic;               -- input selection of the multiplexer

		-- INPUTS
		OPCODE : in  std_logic_vector(OP_CODE_SIZE - 1 downto 0);
		FUNC   : in  std_logic_vector(FUNC_SIZE - 1 downto 0);
		Clk : in std_logic;
		Rst : in std_logic					  -- Active Low
	);
end HW_CU;

architecture HW_CU_RTL of HW_CU is
	signal LUTOUT : std_logic_vector(12 downto 0);

	signal PIPE1 : std_logic_vector(12 downto 0) := (others => '0');
	signal PIPE2 : std_logic_vector(9 downto 0) := (others => '0');
	signal PIPE3 : std_logic_vector(4 downto 0) := (others => '0');

	signal PIPEREG12 : std_logic_vector(9 downto 0) := (others => '0');
	signal PIPEREG23 : std_logic_vector(4 downto 0) := (others => '0');

begin

	--
	-- LUTOUT bits
	--
	-- EN1 | RF1 | RF2 | EN2 | S1 | S2 | ALU1 | ALU2 | EN3 | RM | WM | S3 | WF1
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

	PIPE1 <= LUTOUT;
	PIPEREG12 <= PIPE1(9 downto 0);
	PIPEREG23 <= PIPE2(4 downto 0);

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

		elsif clk'event and clk = '1' then
			PIPE2 <= PIPEREG12;
			PIPE3 <= PIPEREG23;
		end if;
	end process;

	--
	-- Look Up Table
	--
	-- Implements the LUT
	--

	PROCESS_LUT: process(clk,rst)
	begin
		if rst = '0' then
			LUTOUT <= "000" & "00000" & "00000";

		elsif clk'event and clk = '1' then
			
	-- EN1 | RF1 | RF2 |||||| EN2 | S1 | S2 | ALU1 | ALU2 |||1||| EN3 | RM | WM | S3 | WF1
			case (OPCODE) is
				when RTYPE =>
					case (FUNC) is
						when RTYPE_ADD	=> LUTOUT <= "111" & "10100" & "10001";
						when RTYPE_SUB	=> LUTOUT <= "111" & "10101" & "10001";
						when RTYPE_AND	=> LUTOUT <= "111" & "10110" & "10001";
						when RTYPE_OR	=> LUTOUT <= "111" & "10111" & "10001";
						when NOP		=> LUTOUT <= "000" & "00000" & "00000";
						when others		=> report "I don't know how to handle this func!"; null;
					end case;

				when ITYPE =>
					case (FUNC) is
						when ITYPE_ADDI1	=> LUTOUT <= "110" & "11100" & "10001"; -- R2 = R1 + INP1
						when ITYPE_SUBI1	=> LUTOUT <= "110" & "11101" & "10001";
						when ITYPE_ANDI1	=> LUTOUT <= "110" & "11110" & "10001";
						when ITYPE_ORI1		=> LUTOUT <= "110" & "11111" & "10001";

						when ITYPE_ADDI2	=> LUTOUT <= "110" & "10000" & "10001";
						when ITYPE_SUBI2	=> LUTOUT <= "110" & "10001" & "10001";
						when ITYPE_ANDI2	=> LUTOUT <= "110" & "10010" & "10001";
						when ITYPE_ORI2		=> LUTOUT <= "110" & "10011" & "10001";

						when ITYPE_MOV		=> LUTOUT <= "110" & "10000" & "10001"; -- Like ADDI2, must be sure INP2 = 0

						when ITYPE_S_REG1	=> LUTOUT <= "100" & "11000" & "10001"; -- Like ADDI1, INP1 = val, INP2 = 0
						when ITYPE_S_REG2	=> LUTOUT <= "100" & "11000" & "10001"; -- Like ADDI2, INP1 = 0, INP2 = val

						when ITYPE_S_MEM2	=> LUTOUT <= "111" & "10000" & "10110";

						when ITYPE_L_MEM1	=> LUTOUT <= "110" & "11100" & "11011"; -- Like ADDI1
						when ITYPE_L_MEM2	=> LUTOUT <= "110" & "10000" & "11011"; -- Like ADDI2

						when others		=> report "I don't know how to handle this func!"; null;
					end case;

				when others =>
					report "I don't know how to handle this opcode!";
					null;
			end case;
		end if;
	end process;
end HW_CU_RTL;
