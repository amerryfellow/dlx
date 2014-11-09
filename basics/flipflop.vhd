library IEEE;
use IEEE.std_logic_1164.all;

entity FLIPFLOP is
	port (
		D:	In	std_logic;
		ENABLE: in std_logic;
		CK:	In	std_logic;
		RESET:	In	std_logic;
		Q:	Out	std_logic
	);
end FLIPFLOP;

-- Architectures
architecture BEHAVIORAL_ASYNCHRONOUS of FLIPFLOP is
	begin
		PASYNCH: process(CK,RESET)
		begin
			-- The reset is asynchronous!
			if RESET='1' then
				Q <= '0';
			elsif CK'event and CK='1' then
				if (ENABLE = '1' ) then
					Q <= D;
				end if;
			end if;
		end process;
end BEHAVIORAL_ASYNCHRONOUS;


