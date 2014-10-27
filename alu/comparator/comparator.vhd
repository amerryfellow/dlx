library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use WORK.alu_types.all;

entity COMPARATOR is
	generic(N:integer:=NSUMG);
	port(
		SUM:	in std_logic_vector(N-1 downto 0);
		Cout:	in std_logic;
		ALEB: 	out std_logic;
		ALB:	out std_logic;
		AGB:	out std_logic;
		AGEB: 	out std_logic;
		ANEB:	out std_logic;
		AEB:	out std_logic
		);
end COMPARATOR;


architecture struct of COMPARATOR is
	signal Z: std_logic:='0';
	
	component nor32to1
		port (
				A: in std_logic_vector(N-1 downto 0);
				Z: out std_logic
			);
	end component;
	
begin

	NOR_OUT: nor32to1 port map(SUM,Z);
		

	-- A LOWER THAN B	
	ALB <= (not Cout);
	-- A LOWER OR EQUAL TO B
	ALEB <= ((not Cout) or Z);
	-- A GREATER B
	AGB <= ((not Z) and Cout);
	-- A GREATER OR EQUAL B
	AGEB <= Cout;
	-- A EQUAL B
	AEB <= Z;
	-- A NOT EQUAL B
	ANEB <= not Z;
	
end struct;