library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.alu_types.all;

-- This entity has A in input and implements a behavioural 
-- representation of the table for RADIX-4 booth's algorithm.
-- As you can see this is not a standard multiplexer, altough
-- we left this name for simplicity.
-- The even multiplication ( left shift ) of A is performed in parallel by using OFFSET.

entity MUX3B is
	generic (
		N: 		integer := adderBits;
		OFFSET: integer := 0 -- It's the offset for the depth of shift left of A  
	);
	port (
		A		: in	std_logic_vector(N-1 downto 0);
		CTRL	: in	std_logic_vector(2 downto 0);
		Y		: out	std_logic_vector(N-1 downto 0);
		Cin		: out	std_logic -- It's used for implement the 2's complement.It goes at the input of the RCA blocks.
	);
end MUX3B;

architecture behavioral of MUX3B is
begin

	MUX: process(A,CTRL)
		 variable tempA, tempS: unsigned(N-1 downto 0);

	begin
		-- Implement the table
		case(CTRL) is
			when "000" | "111" 	=>
				Y <= (others=>'0'); 
				Cin <= '0';

			-- + A
			when "001" | "010" 	=>
				tempA := unsigned(A);
				tempS := tempA sll OFFSET;
				Y <= std_logic_vector(temps);
				Cin <= '0';

			-- +2A
			when "011" =>
				tempA := unsigned(A); 						-- i.e:  OFFSET = 2 => Y = 8*A
				tempS := tempA sll (OFFSET + 1);			-- Shift left +1
				Y <= std_logic_vector(tempS);
				Cin <= '0';

			-- -A
			when "101" | "110" 	=>
				tempA := unsigned(A);
				tempS := tempA sll OFFSET;
				Y	<= not std_logic_vector(tempS);		-- Negate now
				Cin	<= '1';								-- Add 1 in the adder to
														-- implement the 2's complement

			-- -2A
			when "100" =>
				tempA := unsigned(A);
				tempS := tempA sll (OFFSET + 1);		-- Shift left +1
				Y <= not std_logic_vector(tempS);		-- Negate now
				Cin	<= '1';								-- Add 1 in the adder to
														-- implement the 2's complement

			when others =>
				null;
		end case;
	end process;
end behavioral;
