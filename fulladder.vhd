library ieee; 
use ieee.std_logic_1164.all; 

entity FULLADDER is 
	generic (
		DFAS: time := 0 ns;
		DFAC: time := 0 ns
	);

	port (
		A:	In	std_logic;
		B:	In	std_logic;
		Ci:	In	std_logic;
		S:	Out	std_logic;
		Co:	Out	std_logic;
	);
end FULLADDER; 

architecture BEHAVIORAL of FULLADDER is
	begin
		S <= A xor B xor Ci after DFAS;
		Co <= (A and B) or (B and Ci) or (A and Ci) after DFAC;
end BEHAVIORAL;

configuration CFG_FA_BEHAVIORAL of FA is
	for BEHAVIORAL
	end for;
end CFG_FA_BEHAVIORAL;
