library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use WORK.constants.all; -- libreria WORK user-defined

entity NAND1 is
	port (
		A:	In	std_logic;
		B:	In	std_logic;
		Y:	Out	std_logic;
	);
end NAND1;

-- Architectures

architecture STRUCTURAL of ND2 is
	begin
		Y <= not( A and B) after NAND_DELAY;
end STRUCTURAL;

architecture BEHAVIORAL of NAND1 is
	begin
		P1: process(A,B) -- tutti gli ingressi utilizzati devono essere nella sensitivity list
		begin
			if (A='1') and (B='1') then
				Y <='0' after NAND_DELAY;
			elsif (A='0') or (B='0') then 
				Y <='1' after NAND_DELAY;
			end if;
		end process;
end ARCH2;

-- Configurations

configuration CFG_NAND1_STRUCTURAL of NAND1 is
	for STRUCTURAL
	end for;
end CFG_NAND1_STRUCTURAL;

configuration CFG_NAND_BEHAVIORAL of NAND1 is
	for BEHAVIORAL
	end for;
end CFG_NAND1_BEHAVIORAL;

