library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use WORK.alu_types.all;
use ieee.std_logic_misc.all;

entity COMPARATOR is
	generic(N:integer:=NSUMG);
	port(
		SUM:	in std_logic_vector(N-1 downto 0);
		Cout:	in std_logic;
		OVERFLOW : in std_logic;
		mod_op: in TYPE_OP;
		comp_result : out std_logic_vector(N-1 downto 0)
		);
end COMPARATOR;


architecture struct of COMPARATOR is
	signal Z:		std_logic:='0';
	signal ALEB:  	std_logic;
	signal ALB:	 	std_logic;
	signal AGB:	 	std_logic;
	signal AGEB:  	std_logic;
	signal ANEB:	std_logic;
	signal AEB:		 std_logic;
	signal ALEBU:  	std_logic;
	signal ALBU:	 	std_logic;
	signal AGBU:	 	std_logic;
	signal AGEBU:  	std_logic;
	
begin

	Z <= nor_reduce(SUM);
	
	--UNSIGNED
	ALBU <= (not Cout);
	-- A LOWER OR EQUAL TO B
	ALEBU <= ((not Cout) or Z);
	-- A GREATER B
	AGBU <= ((not Z) and Cout);
	-- A GREATER OR EQUAL B
	AGEBU <= Cout;
	
	--SIGNED
	-- A LOWER THAN B	
	ALB <= (OVERFLOW XOR SUM(NSUMG - 1));
	-- A LOWER OR EQUAL TO B
	ALEB <= (ALB or Z);
	-- A GREATER B
	AGB <= ((not Z) and (NOT ALB));
	-- A GREATER OR EQUAL B
	AGEB <= NOT ALB;
	
	
	-- A EQUAL B
	AEB <= Z;
	-- A NOT EQUAL B
	ANEB <= not Z;
	
	comp_result(0) <= ALEB when mod_op = ALUSLE else
							AGB  when mod_op = ALUSGT else
							AGEB when mod_op = ALUSGE else
							AEB  when mod_op = ALUSEQ else
							ANEB when mod_op = ALUSNE else 
							ALB  when mod_op = ALUSLT else 
							ALEBU when mod_op = ALUSLEU else
							AGBU  when mod_op = ALUSGTU else
							AGEBU when mod_op = ALUSGEU else
							ALBU  when mod_op = ALUSLTU else 
							'0';
	comp_result(N-1 downto 1) <= (others => '0');
		
		
		
end struct;