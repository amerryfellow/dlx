library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use WORK.alu_types.all;

-- Generic N-bit Ripple Carry Adder

entity RCA_GENERIC is 
	generic (
		NBIT	:	integer	:= NRCA
	);
	
	port (
		A:	in	std_logic_vector(NBIT-1 downto 0);
		B:	in	std_logic_vector(NBIT-1 downto 0);
		Ci:	in	std_logic;
		S:	out	std_logic_vector(NBIT-1 downto 0);
		Co:	out	std_logic
	);
end RCA_GENERIC; 

-- Architectures

architecture STRUCTURAL of RCA_GENERIC is
	signal STMP : std_logic_vector(NBIT-1 downto 0);
	signal CTMP : std_logic_vector(NBIT downto 0);

	component FULLADDER
	
		port (
			A:	in	std_logic;
			B:	in	std_logic;
			Ci:	in	std_logic;
			S:	out	std_logic;
			Co:	out	std_logic
		);
	end component;
		
	begin
		CTMP(0)	<= Ci;
		S		<= STMP;
		Co		<= CTMP(NBIT);

		-- Generate and concatenate the FAs
		ADDER1: for I in 1 to NBIT generate
			FAI : FULLADDER
			port map (A(I-1), B(I-1), CTMP(I-1), STMP(I-1), CTMP(I)); 
	end generate;
end STRUCTURAL;

-- Configurations deleted

