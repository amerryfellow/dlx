library IEEE;

use IEEE.std_logic_1164.all;
use WORK.alu_types.all;

--
-- Generic n-bit mux with two input vectors and one output vector
--

entity MUX4TO1 is
	generic (
		N:			integer	:= NSUMG		-- Number of bits
	
	);
	
	port (
		A:		in	std_logic_vector(N-1 downto 0);
		B:		in	std_logic_vector(N-1 downto 0);
		C:		in	std_logic_vector(N-1 downto 0);
		D:		in	std_logic_vector(N-1 downto 0);
		SEL:	in	std_logic_vector(1 downto 0);
		Y:		out	std_logic_vector(N-1 downto 0)
	);
end MUX4TO1;

-- Architecture

architecture behavioral of MUX4TO1 is
signal Y_int: std_logic_vector(N-1 downto 0);
begin
MUX : process (SEL,A,B,C,D)
		begin
			case SEL is
			
			when "00" => Y_int <= A;
			when "01" => Y_int <= B;
			when "10" => Y_int <= C;
			when "11" => Y_int <= D;
			when others => Y_int <= (others => 'Z');
			end case;
			end process;
			Y <= Y_int;
end behavioral;

-- Configurations deleted

