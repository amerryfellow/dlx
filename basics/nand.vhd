library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use WORK.alu_types.all; -- libreria WORK user-defined

entity NAND1 is
	port (
		A:	in	std_logic;
		B:	in	std_logic;
		Y:	out	std_logic
	);
end NAND1;

-- Architectures

architecture STRUCTURAL of NAND1 is
	begin
		Y <= ( A nand B);
end STRUCTURAL;


