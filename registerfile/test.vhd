library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.constants.all;

entity TEST is
	port(
		clk: in std_logic;
		rst: in std_logic;
		o: out std_logic
	);
end TEST;

architecture be of TEST 
	signal count: integer:=0;
	signal temp: std_logic;
begin
	process(rst,clk)
	begin
		if clk'event and clk='1' then
			if rst='1' then
				o<='0';
			else 
				if count = 0 then
					temp <= '1';
				else 
					count<= count + 1;
				end if;
			end if;
		end if;
	end process;
	o<= temp;
end be;	
