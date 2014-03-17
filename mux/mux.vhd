library IEEE;

use IEEE.std_logic_1164.all;
use WORK.constants.all;

entity MUX is
	generic (
		N:			integer	:= numBit;
		MUX_DELAY:	time	:= tp_mux;
	);
	
	port (
		A:		in	std_logic_vector(N-1 downto 0);
		B:		in	std_logic_vector(N-1 downto 0);
		SEL:	in	std_logic;
		Y:		out	std_logic_vector(N-1 downto 0);
	);
end MUX;

-- Architectures

architecture BEHAVIORAL of MUX is
	begin
		Y<= A when SEL='1' else B;
end BEHAVIORAL;

architecture STRUCTURAL of MUX is
	signal A_NAND: std_logic_vector(N-1 downto 0);--OUTPUT OF FIRST NAND A_NAND
	signal B_NAND: std_logic_vector(N-1 downto 0);
	signal SEL_NOT: std_logic;

	component INVERTER
		port (
			A:	in	std_logic;
			Y:	out	std_logic;
		);
	end component;

	component NAND1
		port (
			A:	in	std_logic;
			B:	in	std_logic;
			Y:	out	std_logic;
		);
	end component;

	begin
		INV_GEN:
			INVERTER port map(SEL, SEL_NOT);

		NAND_GEN:
			for i in 0 to N-1 generate
				NAND_A	:NAND1	port map(A(i),		SEL,		A_NAND(i));
				NAND_B	:NAND1	port map(B(i),		SEL_NOT,	B_NAND(i));
				Y_GEN	:NAND1	port map(A_NAND(i),	B_NAND(i),	Y(i));
			end generate;
end STRUCTURAL;

-- Configurations

configuration CFG_MUX_BEHAVIORAL of MUX is
	for BEHAVIORAL
	end for;
end CFG_MUX_BEHAVIORAL;

configuration CFG_MUX_STRUCTURAL of MUX is
	for STRUCTURAL
		for INV_GEN:INVERTER
			use configuration WORK.CFG_INVERTER_BEHAVIORAL;
		end for;  
		for NAND_GEN 
			for all:ND2
				use configuration WORK.CFG_NAND1_STRUCTURAL;
			end for;
		end for;
	end for;
end CFG_MUX_STRUCTURAL;

