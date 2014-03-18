library IEEE;
use IEEE.std_logic_1164.all;


entity FLIPFLOP_TB is
end FLIPFLOP_TB;

architecture TEST of FLIPFLOP_TB is
	signal	CK:			std_logic :='0';
	signal	RESET:		std_logic :='0';
	signal	D:			std_logic :='0';
	signal	QSYNCH:		std_logic;
	signal	QASYNCH:	std_logic;
	
	component FLIPFLOP_D
		port (
			CK:	In	std_logic;
			RESET:	In	std_logic;
			D:	In	std_logic;
			Q:	Out	std_logic
		);
	end component;

begin 
	UFD1 : FLIPFLOP_D
		port map ( CK, RESET, D, QSYNCH); -- sinc

	UFD2 : FLIPFLOP_D
		port map ( CK, RESET, D, QASYNCH); -- asinc
	
	RESET	<= '0', '1' after 0.6 ns, '0' after 1.1 ns, '1' after 2.2 ns, '0' after 3.2 ns;
	D		<= '0', '1' after 0.4 ns, '0' after 1.1 ns, '1' after 1.4 ns, '0' after 1.7 ns, '1' after 1.9 ns;

	PCLOCK : process(CK)
	begin
		CK <= not(CK) after 0.5 ns;	
	end process;

end TEST;

configuration FDTEST of FLIPFLOP_TB is
	for TEST
		for UFD1 : FLIPFLOP_D
			use configuration WORK.CFG_FLIPFLOP_D_SYNCHRONOUS; -- sincrono
		end for;
	
		for UFD2 : FLIPFLOP_D
			use configuration WORK.CFG_FLIPFLOP_D_ASYNCHRONOUS; -- asincrono
		end for;
	end for;
end FDTEST;

