library IEEE;
use std.textio.all;
use IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
use WORK.alu_types.all;

entity TBALU is
end TBALU;

architecture ALU_TEST of TBALU is
  constant NBIT: integer := NSUMG;
	signal	FUNC_CODE:	TYPE_OP:=ADD;
	signal CLK: std_logic:='0';
	signal RESET: std_logic;
	signal	OP1:	STD_LOGIC_VECTOR(NBIT-1 downto 0);
	signal	OP2:	STD_LOGIC_VECTOR(NBIT-1 downto 0);
	signal	RESULT:	STD_LOGIC_VECTOR(NBIT-1 downto 0);
	
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

	begin
		p_clock: process (CLK)
		begin  -- process p_clock
			CLK <= not(CLK) after 2 ns;
 		end process p_clock;
		
		RESET <= '1', '0' after 1 ns;
		U1 : ALU
		generic map (NBIT)
		port map (FUNC_CODE, OP1, OP2,CLK, RESET,  RESULT); 

		OP1 <= "00000000000000000000000000110101";
		OP2 <= "00000000000000000000000000010110";
		FUNC_CODE <=
			ADD after 8 ns,
			SUBT after 16 ns,
			--MULT after 24 ns,
			BITAND after 32 ns,
			BITOR after 40 ns,
			BITXOR after 48 ns,
			FUNCSLL after 56 ns,
			FUNCSRL after 64 ns, 
			FUNCSRA after 72 ns,
			COMP after 80 ns;

end ALU_TEST;

