library IEEE;
use IEEE.std_logic_1164.all; 
use WORK.constants.all;

entity REGISTER_FLIPFLOP_D is
	generic (
		N: integer:= numBit;
		DELAY_MUX: Time:= tp_mux
	);
	port (
		DIN:	in	std_logic_vector(N-1 downto 0) ;
		CK:		in	std_logic;
		RESET:	in	std_logic;
		DOUT:	out	std_logic_vector(N-1 downto 0)
	);
end REGISTER_FLIPFLOP_D;

-- Architectures

architecture STRUCTURAL_SYNCHRONOUS of REGISTER_FLIPFLOP_D is ---SYNC REGISTER
	component FLIPFLOP_D
		port(
			D:		in	std_logic;
			CK:		in	std_logic;
			RESET:	in	std_logic;
			Q:		out	std_logic
		);
	end component;

	begin
		REG_GEN:
			for i in 0 to N-1 generate
				SYNC_REG: FLIPFLOP_D port map(DIN(i),CK,RESET,DOUT(i));
			end generate;
end STRUCTURAL_SYNCHRONOUS;
	
architecture STRUCTURAL_ASYNCHRONOUS of REGISTER_FLIPFLOP_D is
	component FLIPFLOP_D
		port (
			D:	In	std_logic;
			CK:	In	std_logic;
			RESET:	In	std_logic;
			Q:	Out	std_logic
		);
	end component;

	begin
		REG_GEN_A:
			for i in 0 to N-1 generate
				ASYNC_REG: FLIPFLOP_D
					port map(DIN(i),CK,RESET,DOUT(i));
			end generate;
end STRUCTURAL_ASYNCHRONOUS;	

-- Configurations

configuration CFG_REGISTER_FLIPFLOP_D_SYNCHRONOUS of REGISTER_FLIPFLOP_D is
	for STRUCTURAL_SYNCHRONOUS
		for REG_GEN
			for all: FLIPFLOP_D
				use configuration WORK.CFG_FLIPFLOP_D_SYNCHRONOUS;
			end for;
		end for;
	end for;
end CFG_REGISTER_FLIPFLOP_D_SYNCHRONOUS;

configuration CFG_REGISTER_FLIPFLOP_D_ASYNCHRONOUS of REGISTER_FLIPFLOP_D is
	for STRUCTURAL_ASYNCHRONOUS
		for REG_GEN_A
			for all: FLIPFLOP_D
				use configuration WORK.CFG_FLIPFLOP_D_ASYNCHRONOUS;
			end for;
		end for;
	end for;
end CFG_REGISTER_FLIPFLOP_D_ASYNCHRONOUS;

