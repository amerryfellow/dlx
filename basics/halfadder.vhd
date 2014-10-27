library ieee;
use ieee.std_logic_1164.all;

entity halfadder is
port(
		A: in std_logic;
		B: in std_logic;
		S: out std_logic;
		C: out std_logic
		);
end halfadder;

architecture beh of halfadder is

begin
	C <= A and B;
	S <= A xor B;
end beh;
