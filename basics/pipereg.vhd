library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use WORK.constants.all;
use WORK.alu_types.all;

entity PIPEREG is
	generic (
		N		: integer;
		REGS	: integer;
	);

	port (
		CLK:		in	std_logic;							-- Clock
		RESET:		in	std_logic;							-- Reset
		I:			in	array(0 to REGS-1) of std_logic_vector(N-1 downto 0);
		O:			out	array(0 to REGS-1) of std_logic_vector(N-1 downto 0)
	);
end PIPEREG;

architecture DYN of PIPEREG is
	component REGISTER_FD is
		generic (
			N: integer:= numBit;
		);

	port (
			CLK:		in	std_logic;							-- Clock
			RESET:		in	std_logic;							-- Reset
			DIN:		in	std_logic_vector(N-1 downto 0);		-- Data in
			DOUT:		out	std_logic_vector(N-1 downto 0)		-- Data out
		);
	end component;

begin
	G : for j in 0 to REGS-1 generate
		REG : REGISTER_FD port map
			(CLK, RESET, I(j), O(j));
	end generate;
end DYN;

