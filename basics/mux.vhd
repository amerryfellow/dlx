library IEEE;
use IEEE.std_logic_1164.all;

--
-- Generic n-bit mux with two input vectors and one output vector
--

entity MUX is
	generic (
		N:			integer := 1		-- Number of bits
	);

	port (
		A:		in	std_logic_vector(N-1 downto 0);
		B:		in	std_logic_vector(N-1 downto 0);
		SEL:	in	std_logic;
		Y:		out	std_logic_vector(N-1 downto 0)
	);
end MUX;

-- Architectures

architecture BEHAVIORAL of MUX is
	begin
		Y <= A when SEL = '0' else B;
end BEHAVIORAL;
