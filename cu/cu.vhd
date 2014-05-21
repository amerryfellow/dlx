library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;
--use work.all;

entity CU_UP is
	generic (
		INSTRUCTIONS_EXECUTION_CYCLES	: integer := 3;		-- U Instructions Execution
		MICROCODE_MEM_SIZE				: integer := 57;	-- U Microcode Memory Size
															-- Memory Size
		OP_CODE_SIZE	: integer := 6;						-- Op Code Size
		ALU_OPC_SIZE	: integer := 2;						-- ALU Op Code Word Size
		FUNC_SIZE		: integer := 11;					-- Func Field Size for R-Type Ops
		CW_SIZE			: integer := 13						-- U Control Word Size
	);

	port (
		Clk		: in  std_logic;		-- Clock
		Rst		: in  std_logic;		-- Reset:Active-Low
		OPCODE : in  std_logic_vector(OP_CODE_SIZE - 1 downto 0);
		FUNC   : in  std_logic_vector(FUNC_SIZE - 1 downto 0);

		-- FIRST PIPE STAGE OUTPUTS
		EN1		: out std_logic;				-- enables the register file and the pipeline registers
		RF1		: out std_logic;				-- enables the read port 1 of the register file
		RF2		: out std_logic;				-- enables the read port 2 of the register file
		WF1		: out std_logic;				-- enables the write port of the register file

		-- SECOND PIPE STAGE OUTPUTS
		EN2		: out std_logic;				-- enables the pipe registers
		S1		: out std_logic;				-- input selection of the first multiplexer
		S2		: out std_logic;				-- input selection of the second multiplexer
		ALU1	: out std_logic;				-- alu control bit
		ALU2	: out std_logic;				-- alu control bit

		-- THIRD PIPE STAGE OUTPUTS
		EN3		: out std_logic;				-- enables the memory and the pipeline registers
		RM		: out std_logic;				-- enables the read-out of the memory
		WM		: out std_logic;				-- enables the write-in of the memory
		S3		: out std_logic					-- input selection of the multiplexer
	);
end CU_UP;

architecture main of CU_UP is
	type mem_array is array (integer range 0 to MICROCODE_MEM_SIZE - 1) of std_logic_vector(CW_SIZE - 1 downto 0);
	signal microcode : mem_array := (
		"000" & "00000" & "00000",	-- Nop
		"000" & "00000" & "00000",	-- Nop
		"000" & "00000" & "00000",	-- Nop
		"111" & "00000" & "00000",	-- D R ADD
		"000" & "10100" & "00000",	-- E R ADD
		"000" & "00000" & "10001",	-- M R ADD
		"111" & "00000" & "00000",	-- D R SUB
		"000" & "10101" & "00000",	-- E R SUB
		"000" & "00000" & "10001",	-- M R SUB
		"111" & "00000" & "00000",	-- D R AND
		"000" & "10110" & "00000",	-- E R AND
		"000" & "00000" & "10001",	-- M R AND
		"111" & "00000" & "00000",	-- D R OR
		"000" & "10111" & "00000",	-- E R OR
		"000" & "00000" & "10001",	-- M R OR
		"110" & "00000" & "00000",	-- D I ADDI1
		"000" & "11100" & "00000",	-- E I ADDI1
		"000" & "00000" & "10001",	-- M I ADDI1
		"110" & "00000" & "00000",	-- D I SUBI1
		"000" & "11101" & "00000",	-- E I SUBI1
		"000" & "00000" & "10001",	-- M I SUBI1
		"110" & "00000" & "00000",	-- D I ANDI1
		"000" & "11110" & "00000",	-- E I ANDI1
		"000" & "00000" & "10001",	-- M I ANDI1
		"110" & "00000" & "00000",	-- D I ORI1
		"000" & "11111" & "00000",	-- E I ORI1
		"000" & "00000" & "10001",	-- M I ORI1
		"110" & "00000" & "00000",	-- D I ADDI2
		"000" & "10000" & "00000",	-- E I ADDI2
		"000" & "00000" & "10001",	-- M I ADDI2
		"110" & "00000" & "00000",	-- D I SUBI2
		"000" & "10001" & "00000",	-- E I SUBI2
		"000" & "00000" & "10001",	-- M I SUBI2
		"110" & "00000" & "00000",	-- D I ANDI2
		"000" & "10010" & "00000",	-- E I ANDI2
		"000" & "00000" & "10001",	-- M I ANDI2
		"110" & "00000" & "00000",	-- D I ORI2
		"000" & "10011" & "00000",	-- E I ORI2
		"000" & "00000" & "10001",	-- M I ORI2
		"110" & "00000" & "00000",	-- D I MOV
		"000" & "10000" & "00000",	-- E I MOV
		"000" & "00000" & "10001",	-- M I MOV
		"100" & "00000" & "00000",	-- D I S REG1
		"000" & "11000" & "00000",	-- E I S REG1
		"000" & "00000" & "10001",	-- M I S REG1
		"100" & "00000" & "00000",	-- D I S REG2
		"000" & "11000" & "00000",	-- E I S REG2
		"000" & "00000" & "10001",	-- M I S REG2
		"111" & "00000" & "00000",	-- D I S MEM2
		"000" & "10000" & "00000",	-- E I S MEM2
		"000" & "00000" & "10110",	-- M I S MEM2
		"110" & "00000" & "00000",	-- D I L MEM1
		"000" & "11100" & "00000",	-- E I L MEM1
		"000" & "00000" & "11011",	-- M I L MEM1
		"110" & "00000" & "00000",	-- D I L MEM2
		"000" & "10000" & "00000",	-- E I L MEM2
		"000" & "00000" & "11011"	-- M I L MEM2
	);

	signal cw : std_logic_vector(CW_SIZE - 1 downto 0);					-- Current Word
	signal uPC : integer range 0 to 131072;								-- Index in Microcode
	signal ICount : integer range 0 to INSTRUCTIONS_EXECUTION_CYCLES;	-- Current Stage

begin  -- dlx_cu_rtl
	-- Read Current Word from the Microcode using index uPC
	cw		<= microcode(uPC);

	-- Signal assignment
	EN1		<= cw(12);
	RF1		<= cw(11);
	RF2		<= cw(10);
	EN2		<= cw(9);
	S1		<= cw(8);
	S2		<= cw(7);
	ALU1	<= cw(6);
	ALU2	<= cw(5);
	EN3		<= cw(4);
	RM		<= cw(3);
	WM		<= cw(2);
	S3		<= cw(1);
	WF1		<= cw(0);

	-- purpose: Update the uPC value depending on the instruction Op Code
	-- type   : sequential
	-- inputs : Clk, Rst, IR_IN
	-- outputs: CW Control Signals
	UPC_DRIVER: process (Clk, Rst)
	begin  -- process uPC_Proc
		-- RESET
		if Rst = '0' then                   -- Asynchronous Reset (active low)
			uPC <= 0;
			ICount <= 0;

		-- NORMAL
		elsif Clk'event and Clk = '1' then

			-- FIRST CLOCK: ID
			if (ICount < 1) then
				if(OPCODE = RTYPE) then
					uPC <= 3*to_integer(unsigned(FUNC));
				else
					uPC <= 5*3 + 3*to_integer(unsigned(FUNC));
				end if;

				report integer'image(to_integer(unsigned(OPCODE)))&" - "&integer'image(to_integer(unsigned(FUNC)));
				
				ICount <= ICount + 1;

			-- SECOND CLOCK: EXE
			elsif (ICount < 2) then
				uPC <= uPC + 1;
				ICount <= ICount + 1;

			-- THIRD/FOURTH CLOCK: EXE/MEM
			else
				uPC <= uPC + 1;
				ICount <= 0;
			end if;
		end if;
	end process UPC_DRIVER;

end main;
