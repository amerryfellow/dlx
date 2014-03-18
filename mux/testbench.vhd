library IEEE;

use IEEE.std_logic_1164.all;
use WORK.constants.all;

entity TBMUX21_GENERIC is
end TBMUX21_GENERIC;

architecture TEST of TBMUX21_GENERIC is
	constant NBIT: integer := 16; 
	signal	A1:	std_logic_vector(NBIT-1 downto 0);
	signal	B1:	std_logic_vector(NBIT-1 downto 0);
	signal	S1:	std_logic;
	signal	output1:	std_logic_vector(NBIT-1 downto 0);
	signal	output2:	std_logic_vector(NBIT-1 downto 0);
	
	component MUX
		generic (
			N: integer:= numBit;
			DELAY_MUX: Time:= tp_mux
		);
		
		port (
			A:		in	std_logic_vector(NBIT-1 downto 0);
			B:		in	std_logic_vector(NBIT-1 downto 0);
			SEL:	in	std_logic;
			Y:		out	std_logic_vector(NBIT-1 downto 0)
		);
	end component;

	begin 
		U1 : MUX
			generic map (NBIT, 3 ns);
			port map ( A1, B1, S1, output1); 

		U2 : MUX
			generic map (NBIT)
			port map ( A1, B1, S1, output2); 

		A1<=(others=>'1');
		B1<=(others=>'0');
		--A1 <= "0000000100000001";
		--B1 <= "1000000000000001";
		S1 <= '0', '1' after 5 ns, '0' AFTER 10 ns;
end TEST;

configuration TEST of TBMUX21_GENERIC is
	for TEST
		for U1: MUX
			use configuration WORK.CFG_MUX_STRUCTURAL; 
		end for;

		for U2: MUX
			use configuration WORK.CFG_MUX_STRUCTURAL; 
		end for;
	end for;
end MUX21GENTEST;

