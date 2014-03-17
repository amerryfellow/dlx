library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.constants.all;



entity ACC is
	generic (NBIT:integer:=numbit);
 port (
      A          : in  std_logic_vector(NBIT - 1 downto 0);
      B          : in  std_logic_vector(NBIT - 1 downto 0);
      CLK        : in  std_logic;
      RST_n      : in  std_logic;
      ACCUMULATE : in  std_logic;
      --- ACC_EN_n   : in  std_logic;  -- optional use of the enable
      Y          : out std_logic_vector(NBIT - 1 downto 0));
end ACC;
architecture STRUCTURAL of ACC is

signal MUX_OUTPUT: std_logic_vector(NBIT-1 downto 0);
signal OUT_ADD: std_logic_vector(NBIT-1 downto 0);
signal FEEDBACK: std_logic_vector(NBIT-1 downto 0);
signal CIN: std_logic:='0';
signal COUT:std_logic;


component RCA_GENERIC
generic (NBIT:integer:=numbit;
			 DRCAS : 	Time := 0 ns;
	         DRCAC : 	Time := 0 ns);
	Port (	A:	In	std_logic_vector(NBIT-1 downto 0);
		B:	In	std_logic_vector(NBIT-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(NBIT-1 downto 0);
		Co:	Out	std_logic);
end component;	

component REGISTER_FD 
Generic (N: integer:= numBit;
		 DELAY_MUX: Time:= 0 ns);
	Port (	DIN:	In	std_logic_vector(N-1 downto 0) ;
		CK:	In	std_logic;
		RESET:	In	std_logic;
		DOUT:	Out	std_logic_vector(N-1 downto 0));
end component;

component MUX21_GENERIC
Generic (N: integer:= numBit;
		 DELAY_MUX: Time:= tp_mux);
	Port (	A:	In	std_logic_vector(N-1 downto 0) ;
		B:	In	std_logic_vector(N-1 downto 0);
		SEL:	In	std_logic;
		Y:	Out	std_logic_vector(N-1 downto 0));
end component;	

begin

MUX_PART:MUX21_GENERIC port map(B,FEEDBACK,ACCUMULATE,MUX_OUTPUT); -- MUX_OUTPUT <= B when ACCUMALATE ='1' ELSE FEEDBACK;

ADDER:RCA_GENERIC port map(A,MUX_OUTPUT,CIN,OUT_ADD,COUT); --COUT WITHOUT OVERFLOW DETECTOR, INFORMATION LOST

REG: REGISTER_FD port map(OUT_ADD,CLK,RST_n,FEEDBACK); -- RESET SYNC,EDGE TRIGGERED CLK

Y<=FEEDBACK;


end STRUCTURAL;

configuration CFG_ACCUMULATOR_STRUCTURAL of ACC is
	for STRUCTURAL
		for MUX_PART: MUX21_GENERIC
				use configuration WORK.CFG_MUX21_GEN_STRUCTURAL;
		end for;
		for ADDER: RCA_GENERIC 
				use configuration WORK.CFG_RCA_STRUCTURAL;
		end for;
	for REG: REGISTER_FD
				use configuration WORK.CFG_REGISTER_FD_SYNC;
	end for;
		
	end for;
end CFG_ACCUMULATOR_STRUCTURAL;	


	  