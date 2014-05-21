library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

-- Entity

entity P4ADDER is
	generic(
		N:integer:=NSUMG
	);

	port (
		ENABLE:		in	std_logic;
		A:			in	std_logic_vector(N-1 downto 0);
		B:			in	std_logic_vector(N-1 downto 0);
		C0:			in	std_logic;
		S:			out	std_logic_vector(N-1 downto 0);
		OVERFLOW:	out	std_logic						-- In case we need it
	);
end P4ADDER;

-- Architectures

architecture structural of P4ADDER is
	signal CARRY, Ci:	std_logic_vector(N/4 - 1 downto 0);

	component TREE 
		generic(
			N:	integer	:= NSUMG;
			NC:	integer	:= LOG(NSUMG)
		);
		port(
			A:		in	std_logic_vector(N-1 downto 0);
			B:		in	std_logic_vector(N-1 downto 0);
			C:		out	std_logic_vector(NC-1 downto 0)
		);
	end component;

	component SUMGENERATOR
		generic(
			NBIT:integer:=NSUMG; --32
			NCSB:integer:=NCSUMG --8
		);
		port (
			A:	in	std_logic_vector(NBIT-1 downto 0);
			B:	in	std_logic_vector(NBIT-1 downto 0);
			Ci:	in	std_logic_vector(NCSB-1 downto 0);
			S:	out	std_logic_vector(NBIT-1 downto 0)
		);
	end component;
begin

	SPARSE_TREE: TREE port map(A, B, CARRY);
	
	-- As C32 is not needed/ '0' is the first carry in
	Ci			<= CARRY(NCSUMG-2 downto 0) & C0;
	OVERFLOW	<= CARRY(NCSUMG-1);
	
	SUM_GENERATOR: SUMGENERATOR port map(A,B,Ci,S);
end structural;
