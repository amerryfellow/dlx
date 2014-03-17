library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use WORK.constants.all;
use WORK.alu_type.all;

entity ALU is
	generic (
		N : integer := numBit
	);

	port (
		FUNC:			in TYPE_OP;
		DATA1, DATA2:	in std_logic_vector(N-1 downto 0);
		OUTALU:			out std_logic_vector(N-1 downto 0));
end ALU;

-- Architectures

architecture BEHAVIORAL of ALU is
	begin

	P_ALU: process (FUNC, DATA1, DATA2)
	begin
		case FUNC is
			when ADD		=> OUTALU <= ; 
			when SUB		=> OUTALU <= ;
			when MULT		=> OUTALU <= ;
			when BITAND 	=> OUTALU <= ; -- bitwise operations
			when BITOR		=> OUTALU <= ;
			when BITXOR 	=> OUTALU <= ;
			when LSL		=> OUTALU <= ; -- logical shift left, HELP: use the concatenation operator &  
			when LSR	 	=> OUTALU <= ; -- logical shift right
			when LRL		=> OUTALU <= ; -- rotate left
			when LRR		=> OUTALU <= ; -- toate right
			when others		=> null;
		end case; 
	end process P_ALU;
end BEHAVIOR;

-- Configurations

configuration CFG_ALU_BEHAVIORAL of ALU is
	for BEHAVIORAL
	end for;
end CFG_ALU_BEHAVIORAL;
