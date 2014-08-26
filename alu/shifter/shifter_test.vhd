library IEEE;
use IEEE.std_logic_1164.all;
use WORK.constants.all;

entity test_shifter is
end test_shifter;

architecture testbench of test_shifter is
component bshift
     port (
						direction : 	in  std_logic; -- '1' for left, '0' for right
            logical : 		in  std_logic; -- '1' for logical, '0' for arithmetic
            shift   :			in  std_logic_vector(4 downto 0);  -- shift count
            input   : 		in  std_logic_vector (31 downto 0);
            output  : 		out std_logic_vector (31 downto 0) 
		);
end component;

signal A,output	: 	std_logic_vector (31 downto 0);
signal B		: 	std_logic_vector(4 downto 0);
signal AL		:	std_logic;
signal LR		:	std_logic;


begin

	INIT: bshift port map(LR,AL,B,A,output);
	
	A <= x"0000000F",not x"0000000F" after 15 ns;
	B <= "00001", "00010" after 5 ns,"00011" after 10 ns,"00001" after 15 ns,"00010" after 20 ns,"00011" after 25 ns;
	LR <= '1', '0' after 15 ns,'1' after 35 ns;
	AL <= '1', '0' after 15 ns,'1' after 20 ns;
	
	
end testbench;	