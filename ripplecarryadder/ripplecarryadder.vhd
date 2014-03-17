library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

entity RIPPLECARRYADDER is 
	generic (
		DRCAS : 	time := 0 ns;
		 DRCAC : 	time := 0 ns;
	);
	
	port (
		A:	in	std_logic_vector(5 downto 0);
		B:	in	std_logic_vector(5 downto 0);
		Ci:	in	std_logic;
		S:	out	std_logic_vector(5 downto 0);
		Co:	out	std_logic;
	);
end RIPPLECARRYADDER;

-- Architectures

architecture STRUCTURAL of RIPPLECARRYADDER is
	signal STMP : std_logic_vector(5 downto 0);
	signal CTMP : std_logic_vector(6 downto 0);

	component FULLADDER
		generic (
			DFAS : 	time := 0 ns;
			DFAC : 	time := 0 ns;
		);
		
		port (
			A:	in	std_logic;
			B:	in	std_logic;
			Ci:	in	std_logic;
			S:	out	std_logic;
			Co:	out	std_logic;
		);
	end component; 

	begin
		CTMP(0)	<= Ci;
		S		<= STMP;
		Co		<= CTMP(6);

		ADDER1:
			for i in 1 to 6 generate
				FAI : FULLADDER
					generic map (DFAS => DRCAS, DFAC => DRCAC) 
					port map (A(i-1), B(i-1), CTMP(i-1), STMP(i-1), CTMP(i)); 
			end generate;
end STRUCTURAL;

architecture BEHAVIORAL of RIPPLECARRYADDER is
	begin
		S <= (A + B) after DRCAS;
end BEHAVIORAL;

-- Configurations

configuration CFG_RIPPLECARRYADDER_STRUCTURAL of RIPPLECARRYADDER is
	for STRUCTURAL 
		for ADDER1
			for all : FULLADDER
				use configuration WORK.CFG_FULLADDER_BEHAVIORAL;
			end for;
		end for;
	end for;
end CFG_RIPPLECARRYADDER_STRUCTURAL;

configuration CFG_RIPPLECARRYADDER_BEHAVIORAL of RIPPLECARRYADDER is
	for BEHAVIORAL
	end for;
end CFG_RIPPLECARRYADDER_BEHAVIORAL;
