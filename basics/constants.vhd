library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

package CONSTANTS is
   constant NSUMG : integer := 32;--Number of bit for the sum generator	
   constant NRCA: integer:=4;--Number of bit for the RCA BLOCK
   constant NCSBLOCK: integer :=NRCA;--Number of bit for each carry select blocks
   constant NCSUMG: integer := NSUMG/4;--Number of bit for the carry in for sum generator
   constant NMUX: integer := NRCA;--Number of bit for the MUX in the carry select block
   constant TP_MUX : time := 0.5 ps; 
   function LOG(count: integer) return integer;
end CONSTANTS;

package body CONSTANTS is

function LOG(count: integer) return integer is

	variable power: integer:=0;
	variable index:integer;

	begin
		index:=count;
		while index > 1 loop
			power:=power + 1;
			index:=index/2;
		end loop;
	return power;
end LOG;



end package body;

