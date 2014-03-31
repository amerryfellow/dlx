library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

-- 6-bit Ripple Carry Adder

entity RCA is
	generic (
		DRCAS : 	time := DRCAS;
		DRCAC:		time := DRCAC
	);
	
	port (
		A:	in	std_logic_vector(5 downto 0);
		B:	in	std_logic_vector(5 downto 0);
		Ci:	in	std_logic;
		S:	out	std_logic_vector(5 downto 0);
		Co:	out	std_logic
	);
end RCA;

-- Architectures

architecture STRUCTURAL of RCA is
	signal STMP : std_logic_vector(5 downto 0);	-- Sum propagation
	signal CTMP : std_logic_vector(6 downto 0);	-- Carry propagation

	component FULLADDER
		generic (
			DFAS : 	Time := DFAS;
			DFAC : 	Time := DFAC
		);
		
		port (
			A:	in	std_logic;
			B:	in	std_logic;
			Ci:	in	std_logic;
			S:	out	std_logic;
			Co:	out	std_logic
		);
	end component; 

	begin
		CTMP(0)	<= Ci;			-- Carry In
		S		<= STMP;		-- Output parallel sum
		Co		<= CTMP(6);		-- Output carry is the carry of the last FA

		ADDER1: for I in 1 to 6 generate
			FAI : FULLADDER
				generic map (
					DFAS => DRCAS,
					DFAC => DRCAC
				) 
				port map (A(I-1), B(I-1), CTMP(I-1), STMP(I-1), CTMP(I)); 
		end generate;
end STRUCTURAL;

architecture BEHAVIORAL of RCA is
	signal sum : std_logic_vector(6 downto 0) := (others=>'0');
	begin
		sum	<= ('0' & A) + B + Ci after DRCAS;	-- Temporary signal
		S	<= sum(5 downto 0);					-- Sum
		Co	<= sum(6);							-- Carry out
end BEHAVIORAL;

-- Configurations

configuration CFG_RCA_STRUCTURAL of RCA is
	for STRUCTURAL 
		for ADDER1
			for all : FULLADDER
				use configuration WORK.CFG_FULLADDER_BEHAVIORAL;
			end for;
		end for;
	end for;
end CFG_RCA_STRUCTURAL;

configuration CFG_RCA_BEHAVIORAL of RCA is
	for BEHAVIORAL 
	end for;
end CFG_RCA_BEHAVIORAL;
