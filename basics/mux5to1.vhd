library IEEE;

use IEEE.std_logic_1164.all;
use WORK.alu_types.all;

--
-- Generic n-bit mux with two input vectors and one output vector
--

entity MUX5TO1 is
	generic (
		N:			integer	:= NSUMG		-- Number of bits
	
	);
	
	port (
		A:		in	std_logic_vector(N-1 downto 0);
		B:		in	std_logic_vector(N-1 downto 0);
		C:		in	std_logic_vector(N-1 downto 0);
		D:		in	std_logic_vector(N-1 downto 0);
		F:		in	std_logic_vector(N-1 downto 0);
		SEL:	in	std_logic_vector(2 downto 0);
		Y:		out	std_logic_vector(N-1 downto 0)
	);
end MUX5TO1;

-- Architecture

architecture behavioral of MUX5TO1 is
signal Y_int: std_logic_vector(N-1 downto 0);
begin
MUX : process (SEL,A,B,C,D,F)
		begin
			case SEL is
			
			when "000" => Y_int <= A;
			when "001" => Y_int <= B;
			when "010" => Y_int <= C;
			when "011" => Y_int <= D;
			when "100" => Y_int <= F;
			when others => Y_int <= (others => 'Z');
			end case;
			end process;
			Y <= Y_int;
end behavioral;

-- Configurations deleted

