library IEEE;

use IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use WORK.constants.all;
use WORK.alu_types.all;

entity TBALU is
end TBALU;

architecture TEST of TBALU is
         constant NBIT: integer := 16;
	signal	FUNC_CODE:	TYPE_OP:=ADD;
	signal	OP1:	STD_LOGIC_VECTOR(NBIT-1 downto 0);
	signal	OP2:	STD_LOGIC_VECTOR(NBIT-1 downto 0);
	signal	RESULT:	STD_LOGIC_VECTOR(NBIT-1 downto 0);
	
	component ALU
		generic (
			N : integer := numBit
		);
		
		port (
			FUNC:			in TYPE_OP;
			DATA1, DATA2:	in std_logic_vector(N-1 downto 0);
			OUTALU:			out std_logic_vector(N-1 downto 0)
		);
	end component;

	begin
		U1 : ALU
		generic map (NBIT)
		port map (FUNC_CODE, OP1, OP2,  RESULT); 

		OP1 <= "0000000000110101";
		OP2 <= "0000000000010110","0000000000000110" after 14 ns;
		FUNC_CODE <=
			ADD after 2 ns,
			SUB after 4 ns,
			MULT after 6 ns,
			BITAND after 8 ns,
			BITOR after 10 ns,
			BITXOR after 12 ns,
			FUNCRL after 16 ns,
			FUNCRR after 18 ns, 
			FUNCLSL after 20 ns,
			FUNCLSR after 22 ns;
end TEST;

configuration ALU_TEST of TBALU is
	for TEST
		for U1: ALU
			use configuration WORK.CFG_ALU_BEHAVIORAL; 
		end for;
	end for;
end ALU_TEST;

