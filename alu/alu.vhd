library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use WORK.constants.all;
use WORK.alu_types.all;

entity ALU is
  generic (N : integer := numBit);
  port 	 ( FUNC: IN TYPE_OP;
           DATA1, DATA2: IN std_logic_vector(N-1 downto 0);
           OUTALU: OUT std_logic_vector(N-1 downto 0));
end ALU;

architecture BEHAVIOR of ALU is
signal HALF_NBIT:integer;
signal ZERO_SIGNAL: std_logic_vector(N-1 downto 0);
signal POSITION: integer; -- # of position that a signal has to be shifted/rotated



begin

ZERO_SIGNAL <= (others => '0'); 
HALF_NBIT <= N/2;
POSITION <= conv_integer(DATA2); -- POSITION HAS TO BE LOWER THAN N-1



P_ALU: process (FUNC, DATA1, DATA2)
  -- complete all the requested functions

  begin
    case FUNC is
	when ADD 	=> OUTALU <= DATA1 + DATA2 ; 
	when SUB 	=> OUTALU <= DATA1 - DATA2;
	when MULT 	=> OUTALU <= DATA1(HALF_NBIT-1 downto 0) * DATA2(HALF_NBIT-1 downto 0);
	when BITAND => OUTALU <= DATA1 and DATA2; -- bitwise operations
	when BITOR 	=> OUTALU <= DATA1 or DATA2;
	when BITXOR => OUTALU <= DATA1 xor DATA2;
	when FUNCLSL => OUTALU <= DATA1(N-POSITION-1 downto 0) & ZERO_SIGNAL(POSITION-1 downto 0); -- logical shift left, HELP: use the concatenation operator &  
	when FUNCLSR => OUTALU <= ZERO_SIGNAL(POSITION-1 downto 0) & DATA1(N-1 downto POSITION) ; -- logical shift right
	when FUNCRL => OUTALU <=DATA1(N-POSITION-1 downto 0) & DATA1(N-1 downto N-POSITION); -- rotate left
	when FUNCRR => OUTALU <=DATA1(POSITION downto 0) & DATA1(N-1 downto POSITION+1) ; -- rotate right
	when others => null;
    end case; 
  end process P_ALU;

end BEHAVIOR;

configuration CFG_ALU_BEHAVIORAL of ALU is
  for BEHAVIOR
  end for;
end CFG_ALU_BEHAVIORAL;
