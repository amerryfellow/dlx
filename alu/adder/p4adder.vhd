library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use WORK.alu_types.all;

-- Entity

entity P4ADDER is
	generic(
		N: integer:= NSUMG
	);
	port (
		A:			in	std_logic_vector(N-1 downto 0);
		B:			in	std_logic_vector(N-1 downto 0);
		Cin:		in	std_logic;
		S:			out	std_logic_vector(N-1 downto 0);
		OVERFLOW: out std_logic;
		-- In case we need it,and it is only used for debugging the correct behaviour of the adder 
		Cout:		out	std_logic
	);
end P4ADDER;

-- 
-- This is the structural architecture of a generic P4 adder.
--
-- TREE is a generic sparse radix-2 carry-merge that generates 
-- every fourth carry in the adder.
--
-- SUMGENERATOR consists of (N/4 - 1) CSBs, each having
-- 2 4-bit Ripple Carry Adders. The carry select is thus
-- generic in terms of the number of carry select blocks.
-- 

architecture structural of P4ADDER is
	signal CARRY, Ci:	std_logic_vector(N/4 - 1 downto 0);

	component TREE 
		generic(
			N:		integer	:= NSUMG;
			LOGN:	integer := LOG(NSUMG) -- For the LOG function refers to the P4ADDER_constants
		);
		port(
			A:		in	std_logic_vector(N-1 downto 0);		-- N bit input
			B:		in	std_logic_vector(N-1 downto 0);		-- N bit input
			Cin: 	in std_logic;
			C:		out	std_logic_vector(N/4-1 downto 0)	-- Generate a carry every fourth bit
		);
	end component;

	component SUMGENERATOR
		generic(
			NBIT: integer := NSUMG; --32
			NCSB: integer := NCSUMG --8
		);
		port (
			A:	in	std_logic_vector(NBIT-1 downto 0);
			B:	in	std_logic_vector(NBIT-1 downto 0);
			Ci:	in	std_logic_vector(NCSB-1 downto 0);
			S:	out	std_logic_vector(NBIT-1 downto 0)
		);
	end component;
begin
	SPARSE_TREE: TREE
		generic map(N , LOG(N)) 
		port map(A, B, Cin ,CARRY);
	
	-- As C32 is not needed/ '0' is the first carry in (without propagate)
	Ci			<= CARRY((N/4)-2 downto 0) & Cin;
	Cout		<= CARRY((N/4)-1);
	OVERFLOW <= CARRY((N/4)-1) XOR  CARRY((N/4)-2);
	SUM_GENERATOR: SUMGENERATOR
		generic map(N , N/4)
		port map(A,B,Ci,S);
end structural;

