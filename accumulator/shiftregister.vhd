-- This is a 16 bit Linear Feedback Shift Register
library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity SHIFTREGISTER is 
	port( 
		CLK		: in std_logic; 
		RESET	: in std_logic; 
		LD		: in std_logic; 
		EN		: in std_logic; 
		DIN		: in std_logic_vector (0 to 15); 
		PRN		: out std_logic_vector (0 to 15); 
		ZERO_D	: out std_logic;
	);
end SHIFTREGISTER;

-- Architectures

architecture BEHAVIORAL of SHIFTREGISTER is 
	signal T_PRN : std_logic_vector(0 to 15);

	begin
		-- Continuous assignments :
		PRN <= T_PRN;
		ZERO_D <= '1' when (T_PRN = "0000000000000000") else '0';
		
		process(CLK,RESET) 
			begin 
				if RESET='1' then 
					T_PRN <= "0000000000000001"; -- load 1 at reset 
				elsif rising_edge (CLK) then 
					if (LD = '1') then -- load a new seed when ld is active 
						T_PRN <= DIN; 
					elsif (EN = '1') then -- shift when enabled 
						T_PRN(0) <= T_PRN(15) xor T_PRN(4) xor T_PRN(2) xor T_PRN(1);
						T_PRN(1 to 15) <= T_PRN(0 to 14); 
					end if; 
				end if;
		end process;
end BEHAVIORAL;

