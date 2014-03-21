library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use WORK.constants.all; -- libreria WORK user-defined

entity INVERTER is
	port (
		A:	In	std_logic;
		Y:	Out	std_logic
	);
end INVERTER;

-- Architectures
architecture BEHAVIORAL of INVERTER is
begin
	Y <= not(A) after IVDELAY;
end BEHAVIORAL;

-- Configurations

configuration CFG_INVERTER_BEHAVIORAL of INVERTER is
	for BEHAVIORAL
	end for;
end CFG_INVERTER_BEHAVIORAL;

