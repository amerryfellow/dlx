library IEEE;
use IEEE.std_logic_1164.all; 
use WORK.constants.all;

entity REGISTER_FD is
Generic (N: integer:= numBit;
		 DELAY_MUX: Time:= tp_mux);
	Port (	DIN:	In	std_logic_vector(N-1 downto 0) ;
		CK:	In	std_logic;
		RESET:	In	std_logic;
		DOUT:	Out	std_logic_vector(N-1 downto 0));
end REGISTER_FD;
architecture SYNC of REGISTER_FD is ---SYNC REGISTER

component FD
Port (	D:	In	std_logic;
		CK:	In	std_logic;
		RESET:	In	std_logic;
		Q:	Out	std_logic);
end component;

begin
REG_GEN:for i in 0 to N-1 generate
SYNC_REG: FD port map(DIN(i),CK,RESET,DOUT(i));
end generate;


end SYNC;
	
architecture ASYNC of REGISTER_FD is

component FD
Port (	D:	In	std_logic;
		CK:	In	std_logic;
		RESET:	In	std_logic;
		Q:	Out	std_logic);
end component;

begin
REG_GEN_A:for i in 0 to N-1 generate
ASYNC_REG: FD port map(DIN(i),CK,RESET,DOUT(i));
end generate;


end ASYNC;	

configuration CFG_REGISTER_FD_SYNC of REGISTER_FD is
for SYNC
	for REG_GEN
		for all: FD
			use configuration WORK.CFG_FD_PIPPO;
		end for;
	end for;
end for;
end CFG_REGISTER_FD_SYNC;
configuration CFG_REGISTER_FD_ASYNC of REGISTER_FD is
for ASYNC
	for REG_GEN_A
		for all: FD
			use configuration WORK.CFG_FD_PLUTO;
		end for;
	end for;
end for;
end CFG_REGISTER_FD_ASYNC;

		
