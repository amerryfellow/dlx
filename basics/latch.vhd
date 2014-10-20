library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity LATCH is
	generic (
		N: integer := 1
	);
	port (
		DIN:	in	std_logic_vector(N-1 downto 0);		-- Data in
		EN:		in std_logic;
		RESET:	in std_logic;
		DOUT:	out	std_logic_vector(N-1 downto 0)		-- Data out
	);
end LATCH;

architecture behavioral of LATCH is
begin
	trasparent: process(EN,DIN,RESET)
			begin
				if RESET = '1' then
					DOUT <= (others => '0');
				elsif EN = '1' then
					DOUT <= DIN;
				end if;
			end process;
end behavioral;
