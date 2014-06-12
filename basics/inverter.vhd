library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic

entity INVERTER is
	port (
		A:	in	std_logic;
		Y:	out	std_logic
	);
end INVERTER;

-- Architectures

architecture BEHAVIORAL of INVERTER is
begin
	Y <= not(A);
end BEHAVIORAL;
