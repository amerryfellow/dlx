library IEEE;
use IEEE.std_logic_1164.all; 

entity FLIPFLOP is
	port (
		D:	In	std_logic;
		CK:	In	std_logic;
		RESET:	In	std_logic;
		Q:	Out	std_logic;
	);
end FLIPFLOP;

-- Architectures

architecture BEHAVIORAL_SYNCHRONOUS of FLIPFLOP is
	begin
		PSYNCH: process(CK,RESET)
		begin
			if CK'event and CK='1' then -- positive edge triggered:
				if RESET='1' then -- active high reset 
					Q <= '0'; 
				else
					Q <= D; -- input is written on output
				end if;
			end if;
		end process;
end PIPPO;

architecture BEHAVIORAL_ASYNCHRONOUS of FLIPFLOP is
	begin
		PASYNCH: process(CK,RESET)
		begin
			if RESET='1' then
				Q <= '0';
			elsif CK'event and CK='1' then -- positive edge triggered:
				Q <= D; 
			end if;
		end process;
end PLUTO;

-- Configurations

configuration CFG_FLIPFLOP_SYNCHRONOUS of FLIPFLOP is
	for BEHAVIORAL_SYNCHRONOUS
	end for;
end CFG_FLIPFLOP_SYNCHRONOUS;

configuration CFG_FLIPFLOP_ASYNCHRONOUS of FLIPFLOP is
	for BEHAVIORAL_ASYNCHRONOUS
	end for;
end CFG_FLIPFLOP_ASYNCHRONOUS;

