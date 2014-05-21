library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

-- Generic N-bit Ripple Carry Adder

entity RCA_GENERIC is 
	generic (
		NBIT	:	integer	:= numBit;
		DRCAS	:	time	:= DRCAS;
		DRCAC	:	time	:= DRCAC
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
		generic (
			DFAS: time := DFAS;
			DFAC: time := DFAC
		);
	
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
			generic map (DFAS => DRCAS, DFAC => DRCAC) 
			port map (A(I-1), B(I-1), CTMP(I-1), STMP(I-1), CTMP(I)); 
	end generate;
end STRUCTURAL;

-- Configurations

configuration CFG_RCA_STRUCTURAL of RCA_GENERIC is
  for STRUCTURAL 
    for ADDER1
      for all : FULLADDER
        use configuration WORK.CFG_FULLADDER_BEHAVIORAL;
      end for;
    end for;
  end for;
end CFG_RCA_STRUCTURAL;
