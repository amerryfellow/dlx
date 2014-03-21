library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use WORK.constants.all; -- libreria WORK user-defined

entity NAND1 is
	port (
		A:	In	std_logic;
		B:	In	std_logic;
		Y:	Out	std_logic
	);
end NAND1;

-- Architectures

architecture STRUCTURAL of NAND1 is
	begin
		Y <= not( A and B) after NDDELAY;
end STRUCTURAL;

architecture BEHAVIORAL of NAND1 is
	begin
		P1: process(A,B) -- tutti gli ingressi utilizzati devono essere nella sensitivity list
		begin
			if (A='1') and (B='1') then
				Y <='0' after NDDELAY;
			elsif (A='0') or (B='0') then 
				Y <='1' after NDDELAY;
			end if;
		end process;
end BEHAVIORAL;

-- Configurations

configuration CFG_NAND1_STRUCTURAL of NAND1 is
	for STRUCTURAL
	end for;
end CFG_NAND1_STRUCTURAL;

configuration CFG_NAND1_BEHAVIORAL of NAND1 is
	for BEHAVIORAL
	end for;
end CFG_NAND1_BEHAVIORAL;

