library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use WORK.constants.all;
use WORK.alu_types.all;

entity COMPARATOR is
	generic (
		N : integer := numBit
	);

	port (
		ENABLE:		in	std_logic;
		I1, I2:	in std_logic_vector(N-1 downto 0);
		O:		out std_logic
	);
end COMPARATOR;

architecture GREATER_THAN of COMPARATOR is
	begin
		if( signed(I1) > signed(I2) ) then
			OUTALU <= '1';
		else
			OUTALU <= '0';
		end if;
	end process;
end GREATER_THAN;

architecture LOWER_THAN of COMPARATOR is
	begin
		if( signed(I1) < signed(I2) ) then
			OUTALU <= '1';
		else
			OUTALU <= '0';
		end if;
	end process;
end LOWER_THAN;

