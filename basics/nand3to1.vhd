library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use WORK.alu_types.all;

entity nand3to1 is
	generic (
		N : integer := NSUMG
	);
	port(
		R1 : in std_logic_vector(N-1 downto 0);
		R2 : in std_logic_vector(N-1 downto 0);
		S  : in std_logic;
		L  : out std_logic_vector(N-1 downto 0)
		);
end nand3to1;

architecture bev of nand3to1 is
signal temp: std_logic_vector(N-1 downto 0);
signal s1: std_logic_vector(N-1 downto 0);
begin
s1 <= (others => S);

temp_out: 
		for i in 0 to N-1 generate
			temp(i) <= s1(i) nand R1(i);
		end generate;
		
OUT_GEN:
	for i in 0 to N-1 generate
			L(i) <= temp(i) or (not R2(i));
		end generate;

	

end bev;
	   
