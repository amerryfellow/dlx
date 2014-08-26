library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.generics.all;


entity MUX3B is
	generic(
		N:integer:=numBit;
		OFFSET:integer:=0
	);
	port(
		A		: in	std_logic_vector(N-1 downto 0);
		CTRL	: in	std_logic_vector(2 downto 0);
		Y		: out	std_logic_vector(N-1 downto 0);
		Cin		: out	std_logic
	);
end MUX3B;

architecture behavioral of MUX3B is
begin

	MUX: process(A,CTRL)
		variable tempA,tempS:unsigned(N-1 downto 0);

	begin
		case(CTRL) is
			when "000" | "111" 	=>
				Y <= (others=>'0'); Cin <= '0';

			-- + A
			when "001" | "010" 	=>
				tempA := unsigned(A);
				tempS := tempA sll OFFSET;
				Y <= std_logic_vector(temps);
				Cin <= '0';

			-- +2A
			when "011" =>
				tempA:=unsigned(A);
				tempS:=tempA sll (OFFSET + 1);			-- Shift left +1
				Y <= std_logic_vector(tempS);
				Cin <= '0';

			-- -A
			when "101" | "110" 	=>
				tempA:=unsigned(A);
				tempS:=tempA sll OFFSET
				Y	<= not std_logic_vector(tempS);		-- Negate now
				Cin	<= '1';								-- Add 1 in the adder to
														-- implement the full NEG

			-- -2A
			when "100" =>
				tempA:=unsigned(A);
				tempS:=tempA sll (OFFSET + 1);			-- Shift left +1
				Y <= not std_logic_vector(tempS);		-- Negate now
				Cin	<= '1';								-- Add 1 in the adder to
														-- implement the full NEG

			-- What the what?
			when others =>
				null;
		end case;
	end process;
end behavioral;
