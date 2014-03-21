library IEEE;
use IEEE.std_logic_1164.all; 
use WORK.constants.all;

entity REGISTER_FD is
	generic (
		N: integer:= numBit;
		DELAY_MUX: Time:= tp_mux
	);
	port (
		DIN:	In	std_logic_vector(N-1 downto 0) ;
		CK:	In	std_logic;
		RESET:	In	std_logic;
		DOUT:	Out	std_logic_vector(N-1 downto 0)
	);
end REGISTER_FD;

-- Architecture

architecture SYNCHRONOUS of REGISTER_FD is ---SYNC REGISTER
	component FLIPFLOP
		port (
			D:	In	std_logic;
			CK:	In	std_logic;
			RESET:	In	std_logic;
			Q:	Out	std_logic
		);
	end component;

	begin
		REG_GEN: for i in 0 to N-1 generate
			SYNC_REG : FLIPFLOP
				port map(DIN(i), CK, RESET, DOUT(i));
		end generate;
end SYNCHRONOUS;
	
architecture ASYNCHRONOUS of REGISTER_FD is
	component FLIPFLOP
		port (
			D:	In	std_logic;
			CK:	In	std_logic;
			RESET:	In	std_logic;
			Q:	Out	std_logic
		);
	end component;

	begin
		REG_GEN_A:for i in 0 to N-1 generate
			ASYNC_REG : FLIPFLOP
				port map(DIN(i), CK, RESET, DOUT(i));
		end generate;
end ASYNCHRONOUS;	

configuration CFG_REGISTER_FD_SYNCHRONOUS of REGISTER_FD is
for SYNCHRONOUS
	for REG_GEN
		for all: FLIPFLOP
			use configuration WORK.CFG_FLIPFLOP_SYNCHRONOUS;
		end for;
	end for;
end for;
end CFG_REGISTER_FD_SYNCHRONOUS;

configuration CFG_REGISTER_FD_ASYNCHRONOUS of REGISTER_FD is
for ASYNCHRONOUS
	for REG_GEN_A
		for all: FLIPFLOP
			use configuration WORK.CFG_FLIPFLOP_ASYNCHRONOUS;
		end for;
	end for;
end for;
end CFG_REGISTER_FD_ASYNCHRONOUS;

		
