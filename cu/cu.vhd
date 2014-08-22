library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;
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

architecture main of CU_UP is
	type mem_array is array (integer range 0 to MICROCODE_MEM_SIZE - 1) of std_logic_vector(CW_SIZE - 1 downto 0);
	signal microcode : mem_array := (
		"000" & "00000" & "11011"	-- MEM2
	);

	signal cw : std_logic_vector(CW_SIZE - 1 downto 0);					-- Current Word
	signal uPC : integer range 0 to 131072;								-- Index in Microcode
	signal ICount : integer range 0 to INSTRUCTIONS_EXECUTION_CYCLES;	-- Current Stage

begin  -- dlx_cu_rtl
	-- MUXBOOT drives a '0' only upon reset
	MUXBOOT_CTR <= RESET;

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
