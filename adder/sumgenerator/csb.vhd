library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

entity CSB is
	port (
		A:	in	std_logic_vector(3 downto 0);
		B:	in	std_logic_vector(3 downto 0);
		Ci:	in	std_logic;
		S:	out	std_logic_vector(3 downto 0)
	
	);
end CSB;  --Carry select block

architecture STRUCTURAL of CSB is
signal sum_1:std_logic_vector(3 downto 0);
signal sum_2:std_logic_vector(3 downto 0);
signal co_1:std_logic;
signal co_2:std_logic;



component RCA_GENERIC
generic (NBIT:integer:=4;
			 DRCAS : 	Time := DRCAS;
	         DRCAC : 	Time := DRCAC);
	Port (A:	In	std_logic_vector(NBIT-1 downto 0);
		B:	In	std_logic_vector(NBIT-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(NBIT-1 downto 0);
		Co:	Out	std_logic);
end component; 

component MUX 
	generic (
		N:			integer	:= 4;		-- Number of bits
		MUX_DELAY:	time	:= tp_mux		-- 
	);
	
	port (
		A:		in	std_logic_vector(N-1 downto 0);
		B:		in	std_logic_vector(N-1 downto 0);
		SEL:	in	std_logic;
		Y:		out	std_logic_vector(N-1 downto 0)
	);
end component;

begin
	RCA1: RCA_GENERIC port map(A,B,'0',sum_1,co_1);
	RCA2: RCA_GENERIC port map(A,B,'0',sum_2,co_2);
	MUX_S: MUX port map(sum_1,sum_2,Ci,S);


end structural;


configuration CFG_CSB of CSB is
	for STRUCTURAL 
		for RCA1: RCA_GENERIC
				use configuration WORK.CFG_RCA_STRUCTURAL;
		end for;
		for RCA2: RCA_GENERIC
				use configuration WORK.CFG_RCA_STRUCTURAL;
		end for;
		for MUX_S: MUX
				use configuration WORK.CFG_MUX_STRUCTURAL;
		end for;
	end for;
end CFG_CSB;

