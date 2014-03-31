library IEEE;
use IEEE.std_logic_1164.all; 
use WORK.constants.all;

-- Flipflop-based N-bit register

entity REGISTER_FD is
	generic (
		N: integer:= numBit;
		DELAY_MUX: Time:= tp_mux
	);
	port (
		DIN:	in	std_logic_vector(N-1 downto 0);		-- Data in
		CK:		in	std_logic;							-- Clock
		RESET:	in	std_logic;							-- Reset
		DOUT:	out	std_logic_vector(N-1 downto 0)		-- Data out
	);
end REGISTER_FD;

-- Architectures

architecture SYNCHRONOUS of REGISTER_FD is
	component FLIPFLOP
		port (
			D:		in	std_logic;
			CK:		in	std_logic;
			RESET:	in	std_logic;
			Q:		out	std_logic
		);
	end component;

	begin
		REG_GEN_S : for i in 0 to N-1 generate
			SYNC_REG : FLIPFLOP
				port map(DIN(i), CK, RESET, DOUT(i));
		end generate;
end SYNCHRONOUS;
	
architecture ASYNCHRONOUS of REGISTER_FD is
	component FLIPFLOP
		port (
			D:		in	std_logic;
			CK:		in	std_logic;
			RESET:	in	std_logic;
			Q:		out	std_logic
		);
	end component;

	begin
		REG_GEN_A : for i in 0 to N-1 generate
			ASYNC_REG : FLIPFLOP
				port map(DIN(i), CK, RESET, DOUT(i));
		end generate;
end ASYNCHRONOUS;	

configuration CFG_REGISTER_FD_SYNCHRONOUS of REGISTER_FD is
for SYNCHRONOUS
	for REG_GEN_S
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

