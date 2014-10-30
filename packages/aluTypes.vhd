library ieee;
use ieee.std_logic_1164.all;

package alu_types is

	subtype TYPE_OP is std_logic_vector(3 downto 0);
	
	constant ALUADD		: TYPE_OP:="0001";
	constant ALUSUB		: TYPE_OP:="0010";
	constant ALUAND		: TYPE_OP:="0011";
	constant ALUOR			: TYPE_OP:="0100";
	constant ALUXOR		: TYPE_OP:="0101";
	constant ALUSLL		: TYPE_OP:="0110";
	constant ALUSRL		: TYPE_OP:="0111";
	constant ALUSRA		: TYPE_OP:="1000";
	constant ALUSEQ		: TYPE_OP:="1001";
	constant ALUSNE		: TYPE_OP:="1010";
	constant ALUSGE		: TYPE_OP:="1011";
	constant ALUSGT		: TYPE_OP:="1100";
	constant ALUSLE		: TYPE_OP:="1101";
	
	constant NSUMG 		: integer := 32;--Number of bit for the sum generator	
	constant NRCA 			: integer:= 4;--Number of bit for the RCA BLOCK
	constant NCSBLOCK 	: integer :=NRCA;--Number of bit for each carry select blocks
	constant NCSUMG		: integer := NSUMG/4;--Number of bit for the carry in for sum generator
	constant NMUX 			: integer := NRCA;--Number of bit for the MUX in the carry select block
	
	function LOG(x: integer) return integer;
	--constant adderBits : integer := 2*NSUMG;
end alu_types;
package body alu_types is
--Calculate the logarithm in base 2 of the number in input.
function LOG(x: integer) return integer is

	variable power: integer:=0;
	variable index: integer;

	begin
		index := x;
		while index > 1 loop
			power := power + 1;
			index := index/2;
		end loop;
	return power;
end LOG;



end package body;



