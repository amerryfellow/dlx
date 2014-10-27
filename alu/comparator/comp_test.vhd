library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

entity comp_tb is
end comp_tb;

architecture test of comp_tb is
signal A_i:std_logic_vector(NSUMG-1 downto 0);
signal B_i:std_logic_vector(NSUMG-1 downto 0);
signal S_generate:std_logic_vector(NSUMG-1 downto 0):=(others=>'0');
signal overflow:std_logic:= 'Z';
signal Cin:std_logic:='1'; 

signal ALEB, ALB, AGB, AGEB, ANEB, AEB:	std_logic;



component P4ADDER
generic(N:integer:=NSUMG);
	
port (
		A: in std_logic_vector(N-1 downto 0);
		B: in std_logic_vector(N-1 downto 0);
		Cin:in std_logic;
		S: out std_logic_vector(N-1 downto 0);
		Cout:out std_logic
		);
end component;
component COMPARATOR
port(
		
		SUM:	in std_logic_vector(31 downto 0);
		Cout:	in std_logic;
		ALEB: 	out std_logic;
		ALB:	out std_logic;
		AGB:	out std_logic;
		AGEB: 	out std_logic;
		ANEB:	out std_logic;
		AEB:	out std_logic
		);
end component;
begin

A_i<=x"00000030", x"00000500" after 10 ns,x"00000030" after 20 ns,x"FFFFFFFB" after 30 ns, x"0F0F0F0F" after 40 ns;
B_i<=not x"00000001",not x"01010101" after 10 ns,not x"00000030" after 20 ns,not x"FFFFFFFA" after 30 ns, not x"01010101" after 40 ns;





LIFE:P4ADDER port map (A_i,B_i,Cin,S_generate,overflow);

TEST_COMP: COMPARATOR port map(S_generate,overflow,ALEB,ALB,AGB,AGEB,ANEB,AEB);






end test;