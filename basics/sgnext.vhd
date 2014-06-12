library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity SGNEXT is
	generic (
		INBITS:		integer;
		OUTBITS:	integer;
	);

	port(
		DIN :		in std_logic_vector (INBITS-1 downto 0);
		DOUT :		out std_logic_vector (OUTBITS-1 downto 0);
	);
end SGN_EXT;

architecture RTL of SGNEXT is
	signal addon : std_logic_vector(OUTBITS-INBITS-1 downto 0);
begin
	addon <= (others => '1') when ( DIN(INBITS-1) = "1" ) else (others => '0');
	DOUT <= addon & DIN;
end RTL;

