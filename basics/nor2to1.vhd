library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

entity nor2to1 is
	port (
				A: in std_logic;
				B: in std_logic;
				Z: out std_logic
			);
end nor2to1;	

	
architecture behavioral of nor2to1 is	

begin

	Z <= A nor B;


end behavioral;