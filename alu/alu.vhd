library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use WORK.constants.all;
use WORK.alu_types.all;

entity ALU is
	generic (
		N : integer := numBit
	);
	
	port (
		FUNC:			in TYPE_OP;
		DATA1, DATA2:	in std_logic_vector(N-1 downto 0);
		OUTALU:			out std_logic_vector(N-1 downto 0)
	);
end ALU;

architecture BEHAVIORAL of ALU is
	signal HALF_NBIT:	integer;
	signal ZERO_SIGNAL:	std_logic_vector(N-1 downto 0);
	signal POSITION:	integer; -- # of position that a signal has to be shifted/rotated

	begin
		ZERO_SIGNAL <= (others => '0'); 
		HALF_NBIT <= N/2;
		POSITION <= conv_integer(DATA2); -- Position must be lower than N-1

		P_ALU : process (FUNC, DATA1, DATA2)
		begin
			case FUNC is
				when ADD 	=> OUTALU <= DATA1 + DATA2 ; 
				when SUB 	=> OUTALU <= DATA1 - DATA2;
				when MULT 	=> OUTALU <= DATA1(HALF_NBIT-1 downto 0) * DATA2(HALF_NBIT-1 downto 0);

				-- Bitwise Ops

				when BITAND		=> OUTALU <= DATA1 and DATA2;
				when BITOR		=> OUTALU <= DATA1 or DATA2;
				when BITXOR		=> OUTALU <= DATA1 xor DATA2;
				when FUNCLSL	=> OUTALU <= DATA1(N-POSITION-1 downto 0) & ZERO_SIGNAL(POSITION-1 downto 0);
				when FUNCLSR	=> OUTALU <= ZERO_SIGNAL(POSITION-1 downto 0) & DATA1(N-1 downto POSITION) ;
				when FUNCRL		=> OUTALU <= DATA1(N-POSITION-1 downto 0) & DATA1(N-1 downto N-POSITION);
				when FUNCRR		=> OUTALU <= DATA1(POSITION downto 0) & DATA1(N-1 downto POSITION+1) ;

				-- Others

				when others		=> null;
			end case; 
		end process;
end BEHAVIORAL;

configuration CFG_ALU_BEHAVIORAL of ALU is
  for BEHAVIORAL
  end for;
end CFG_ALU_BEHAVIORAL;
