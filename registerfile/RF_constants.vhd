library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

package CONSTANTS is
   constant numBit : integer := 8;--Number of bit for Data
   constant numGlobals: natural := 32;
   constant numWindows: natural := 7;
   constant numRegsPerWin: natural :=32;
   
   function LOG(x: natural) return integer;
end CONSTANTS;

package body CONSTANTS is

function LOG(x: natural) return integer is

	variable power: integer:=0;
	variable index: natural;

	begin
		index := x;
		while index > 1 loop
			power := power + 1;
			index := index/2;
		end loop;
	return power;
end LOG;

end package body;

