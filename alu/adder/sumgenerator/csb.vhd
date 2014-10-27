library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use WORK.alu_types.all;

-- Entity

entity CSB is
		generic(
			N:	integer	:= NCSBLOCK -- 4
		);
		port (
			A:	in	std_logic_vector(N-1 downto 0);
			B:	in	std_logic_vector(N-1 downto 0);
			Ci:	in	std_logic;
			S:	out	std_logic_vector(N-1 downto 0)
		);
end CSB;

-- Architectures

-- This is the Carry Select Block that uses two generic
-- structural 4-bit RCAs and a parallel 4 bits mux.
architecture STRUCTURAL of CSB is
	signal sum_1:	std_logic_vector(NCSBLOCK-1 downto 0);
	signal sum_2:	std_logic_vector(NCSBLOCK-1 downto 0);
	signal co_1:	std_logic;
	signal co_2:	std_logic;

	component RCA_GENERIC
		generic (
			NBIT:integer:=NRCA
		);
	
		port (
			A:	in	std_logic_vector(NBIT-1 downto 0);
			B:	in	std_logic_vector(NBIT-1 downto 0);
			Ci:	in	std_logic;
			S:	out	std_logic_vector(NBIT-1 downto 0);
			Co:	out	std_logic
		);
	end component;

	component MUX 
		generic (
			N:			integer	:= NMUX
		);
		
		port (
			A:		in	std_logic_vector(N-1 downto 0);
			B:		in	std_logic_vector(N-1 downto 0);
			SEL:	in	std_logic;
			Y:		out	std_logic_vector(N-1 downto 0)
		);
	end component;
begin
	-- First RCA entity assuming carry in equal to 1
	RCA1: RCA_GENERIC port map(A,B,'1',sum_1,co_1);

	-- Second RCA entity assuming carry in equal to 0
	RCA2: RCA_GENERIC port map(A,B,'0',sum_2,co_2);

	-- MUX selects the output of one of the RCAs, depending on
	-- whether the carry in for the block is 1 ( sum_1 ) or 0 ( sum_2 )
	MUX_S: MUX port map(sum_1,sum_2,Ci,S);
end structural;

