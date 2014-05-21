library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

entity TREE_G is
	port(
		PG:	in	std_logic_vector(1 downto 0);
		GI:	in	std_logic;
		GO:	out	std_logic
	);
end TREE_G;

architecture BEHAVIORAL of tree_g is
	begin
		GO <= PG(1) or (PG(0) and GI);
end behavioral;
