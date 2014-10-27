library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use WORK.alu_types.all;

entity INIT_PG is
	port(
		A:	in	std_logic;
		B:	in	std_logic;
		PG:	out	std_logic_vector(1 downto 0)
	);
end INIT_PG;

architecture BEHAVIORAL of INIT_PG is
	begin
		PG(0) <= A xor B;
		PG(1) <= A and B;
end BEHAVIORAL;
