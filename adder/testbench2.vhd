library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

entity second_tb is
end second_tb;

architecture test of second_tb is
signal A_i:std_logic_vector(31 downto 0);
signal B_i:std_logic_vector(31 downto 0);
signal S_generate:std_logic_vector(31 downto 0):=(others=>'0');
signal c0,overflow:std_logic:='0';
--signal period:time:=1 ns;


component P4ADDER
generic(N:integer:=NSUMG);
	
port (
		A: in std_logic_vector(N-1 downto 0);
		B: in std_logic_vector(N-1 downto 0);
		C0:in std_logic;
		S: out std_logic_vector(N-1 downto 0);
		OVERFLOW:out std_logic
		);
end component;

begin

A_i<=x"FFFFFFFF", x"0F0F0F0F" after 10 ns,x"EFEFEFEF" after 20 ns;
B_i<=x"00000001", x"01010101" after 10 ns,x"10101010" after 20 ns;

LIFE:P4ADDER port map (A_i,B_i,c0,S_generate,overflow);








end test;