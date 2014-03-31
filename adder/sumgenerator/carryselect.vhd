 
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

entity CARRYSELECT is
	generic(
		NBIT:integer:=32;
		NCSB:integer:=8
	);
	port (
		A:	in	std_logic_vector(NBIT-1 downto 0);
		B:	in	std_logic_vector(NBIT-1 downto 0);
		Ci:	in	std_logic_vector(NCSB-1 downto 0);
		S:	out	std_logic_vector(NBIT-1 downto 0)
	
	);
end CARRYSELECT;

architecture structural of CARRYSELECT is

component CSB 
	port (
		A:	in	std_logic_vector(3 downto 0);
		B:	in	std_logic_vector(3 downto 0);
		Ci:	in	std_logic;
		S:	out	std_logic_vector(3 downto 0)
	
	);
end component;

begin

CS: for i in 0 to NCSB-1 generate
	CSBX: CSB
			port map(A(((i*4)+3) downto i*4),B(((i*4)+3) downto i*4),Ci(i),S(((i*4)+3) downto i*4));
	end generate;
end structural;

configuration CFG_CARRYSELECT of CARRYSELECT is
	for STRUCTURAL 
		for CS
			for all: CSB 
						use configuration work.CFG_CSB;
			end for;
		end for;
	end for;
end CFG_CARRYSELECT;
