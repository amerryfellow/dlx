library ieee;
use ieee.std_logic_1164.all;

package alu_types is

	subtype TYPE_OP is std_logic_vector(4 downto 0);
	
	constant ALUADD		: TYPE_OP:="00001";
	constant ALUSUB		: TYPE_OP:="00010";
	constant ALUAND		: TYPE_OP:="00011";
	constant ALUOR		: TYPE_OP:="00100";
	constant ALUXOR		: TYPE_OP:="00101";
	constant ALUSLL		: TYPE_OP:="00110";
	constant ALUSRL		: TYPE_OP:="00111";
	constant ALUSRA		: TYPE_OP:="01000";
	constant ALUSEQ		: TYPE_OP:="01001";
	constant ALUSNE		: TYPE_OP:="01010";
	constant ALUSGEU	: TYPE_OP:="01011";
	constant ALUSGTU	: TYPE_OP:="01100";
	constant ALUSLEU	: TYPE_OP:="01101";
	constant ALUSLTU	: TYPE_OP:="01110";
	constant ALUSGE		: TYPE_OP:="01111";
	constant ALUSGT		: TYPE_OP:="10000";
	constant ALUSLE		: TYPE_OP:="10001";
	constant ALUSLT		: TYPE_OP:="10010";
	
	constant NSUMG 		: integer := 32;--Number of bit for the sum generator	
	constant NRCA 		: integer:= 4;--Number of bit for the RCA BLOCK
	constant NCSBLOCK 	: integer :=NRCA;--Number of bit for each carry select blocks
	constant NCSUMG		: integer := NSUMG/4;--Number of bit for the carry in for sum generator
	constant NMUX 		: integer := NRCA;--Number of bit for the MUX in the carry select block
	
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
