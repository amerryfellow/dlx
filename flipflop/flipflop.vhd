library IEEE;
use IEEE.std_logic_1164.all; 

entity FLIPFLOP_D is
	port (
		D:	In	std_logic;
		CK:	In	std_logic;
		RESET:	In	std_logic;
		Q:	Out	std_logic
	);
end FLIPFLOP_D;

-- Architectures

architecture BEHAVIORAL_SYNCHRONOUS of FLIPFLOP_D is
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
end BEHAVIORAL_SYNCHRONOUS;

architecture BEHAVIORAL_ASYNCHRONOUS of FLIPFLOP_D is
	begin
		PASYNCH: process(CK,RESET)
		begin
			if RESET='1' then
				Q <= '0';
			elsif CK'event and CK='1' then -- positive edge triggered:
				Q <= D; 
			end if;
		end process;
end BEHAVIORAL_ASYNCHRONOUS;

-- Configurations

configuration CFG_FLIPFLOP_D_SYNCHRONOUS of FLIPFLOP_D is
	for BEHAVIORAL_SYNCHRONOUS
	end for;
end CFG_FLIPFLOP_D_SYNCHRONOUS;

configuration CFG_FLIPFLOP_D_ASYNCHRONOUS of FLIPFLOP_D is
	for BEHAVIORAL_ASYNCHRONOUS
	end for;
end CFG_FLIPFLOP_D_ASYNCHRONOUS;

