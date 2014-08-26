library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

entity TREE_PG is
	port(
		PG0:	in	std_logic_vector(1 downto 0);
		PG1:	in	std_logic_vector(1 downto 0);
		PGO:	out	std_logic_vector(1 downto 0)
	);
end TREE_PG;

architecture BEHAVIORAL of TREE_PG is
	begin
		PGO(0)	<= PG0(0) and PG1(0);--PROPAGATE
		PGO(1)	<= PG0(1) or ( PG0(0) and PG1(1) );--GENERATE
end BEHAVIORAL;
