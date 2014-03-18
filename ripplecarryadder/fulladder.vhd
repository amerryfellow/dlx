library ieee; 
use ieee.std_logic_1164.all; 

entity FULLADDER is 
	generic (
		FULLADDER_DELAY_S: time := 0 ns;
		FULLADDER_DELAY_C: time := 0 ns
	);

	port (
		A:	In	std_logic;
		B:	In	std_logic;
		Ci:	In	std_logic;
		S:	Out	std_logic;
		Co:	Out	std_logic
	);
end FULLADDER; 

architecture BEHAVIORAL of FULLADDER is
	begin
		S <= A xor B xor Ci after FULLADDER_DELAY_S;
		Co <= (A and B) or (B and Ci) or (A and Ci) after FULLADDER_DELAY_C;
end BEHAVIORAL;

configuration CFG_FULLADDER_BEHAVIORAL of FULLADDER is
	for BEHAVIORAL
	end for;
end CFG_FULLADDER_BEHAVIORAL;
