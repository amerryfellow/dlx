library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

entity first_tb is
end first_tb;

architecture test of first_tb is
signal A_i:std_logic_vector(31 downto 0);
signal B_i:std_logic_vector(31 downto 0);
signal C_generate:std_logic_vector(7 downto 0):=(others=>'0');

component TREE
	port(
		A:		in	std_logic_vector(31 downto 0);
		B:		in	std_logic_vector(31 downto 0);
		C:		out	std_logic_vector(7 downto 0)
	);
end component;

begin

A_i<=x"FFFFFFFF", x"0F0F0F0F" after 10 ns,x"EFEFEFEF" after 20 ns;
B_i<=x"00000001",x"00000101" after 10 ns;

LIFE:TREE port map (A_i,B_i,C_generate);








end test;