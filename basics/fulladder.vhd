library ieee; 
use ieee.std_logic_1164.all;
use work.constants.all; 

entity FULLADDER is 
	generic (
		DFAS: time := DFAS;
		DFAC: time := DFAC
	);

	port (
		A:	in	std_logic;
		B:	in	std_logic;
		Ci:	in	std_logic;
		S:	out	std_logic;
		Co:	out	std_logic
	);
end FULLADDER; 

-- Architectures

architecture BEHAVIORAL of FULLADDER is
	begin
		S	<= A xor B xor Ci after DFAS;
		Co	<= (A and B) or (B and Ci) or (A and Ci) after DFAC;
end BEHAVIORAL;

-- Configurations

configuration CFG_FULLADDER_BEHAVIORAL of FULLADDER is
	for BEHAVIORAL
	end for;
end CFG_FULLADDER_BEHAVIORAL;
