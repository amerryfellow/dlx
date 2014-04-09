 
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

-- Behavioral

entity SUMGENERATOR is
	generic(
		NBIT:	integer	:= NSUMG; --32
		NCSB:	integer	:= NCSUMG --8
	);
	port (
		A:	in	std_logic_vector(NBIT-1 downto 0);
		B:	in	std_logic_vector(NBIT-1 downto 0);
		Ci:	in	std_logic_vector(NCSB-1 downto 0);
		S:	out	std_logic_vector(NBIT-1 downto 0)
	);
end SUMGENERATOR;

-- Architectures

architecture structural of SUMGENERATOR is
	component CSB 
		generic(
			N:	integer	:= NCSBLOCK
		);
		port (
			A:	in	std_logic_vector(N-1 downto 0);
			B:	in	std_logic_vector(N-1 downto 0);
			Ci:	in	std_logic;
			S:	out	std_logic_vector(N-1 downto 0)
		
		);
	end component;
begin
	CS: for i in 0 to NCSB-1 generate
		CSBX: CSB
			port map(
				A(((i*NCSBLOCK)+NCSBLOCK-1) downto i*NCSBLOCK),
				B(((i*NCSBLOCK)+NCSBLOCK-1) downto i*NCSBLOCK),
				Ci(i),
				S(((i*NCSBLOCK)+NCSBLOCK-1) downto i*NCSBLOCK)
			);
	end generate;
end structural;

-- Configurations

configuration CFG_SUMGENERATOR of SUMGENERATOR is
	for STRUCTURAL 
		for CS
			for all: CSB 
						use configuration work.CFG_CSB;
			end for;
		end for;
	end for;
end CFG_SUMGENERATOR;
