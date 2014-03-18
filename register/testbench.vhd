library IEEE;

use IEEE.std_logic_1164.all;
use WORK.constants.all;

entity TB_REGISTER_FD is
	end TB_REGISTER_FD;

architecture TEST of TB_REGISTER_FD is

	constant NBIT: integer := 16; 
	signal	A1:	std_logic_vector(NBIT-1 downto 0):="0000111100001111";
	signal	CK:	std_logic:='0';
	signal	output1: std_logic_vector(NBIT-1 downto 0);
	signal output2:std_logic_vector(NBIT-1 downto 0);
	signal RESET: std_logic;

	component REGISTER_FLIPFLOP_D
		Generic (N: integer:= numBit;
		DELAY_MUX: Time:= tp_mux);
		Port (DIN:	In	std_logic_vector(NBIT-1 downto 0) ;
			   CK:	In	std_logic;
			   RESET:	In	std_logic;
			   DOUT:	Out	std_logic_vector(NBIT-1 downto 0));
	end component;
begin


	REGISTER_SYNC:REGISTER_FLIPFLOP_D generic map (NBIT)
	port map(A1,CK,RESET,output1);
	REGISTER_ASYNC:REGISTER_FLIPFLOP_D generic map (NBIT)
	port map(A1,CK,RESET,output2);


	RESET <= '1', '0' after 5 ns;
	--A1 <= "0000111100001111";

	CLK_GEN:process(CK)
	begin
		ck<= (not ck) after 0.5 ns;
		if ck'event and ck='1' then
			A1<= A1(NBIT-2 downto 0) & A1(NBIT-1);
		end if;
	end process;

end TEST;
configuration TB_REGISTER_TEST of TB_REGISTER_FD is
	for test	
		for REGISTER_SYNC : REGISTER_FLIPFLOP_D
			use configuration WORK.CFG_REGISTER_FLIPFLOP_D_SYNCHRONOUS;
		end for;
		for REGISTER_ASYNC: REGISTER_FLIPFLOP_D
			use configuration WORK.CFG_REGISTER_FLIPFLOP_D_ASYNCHRONOUS;
		end for;
	end for;
end TB_REGISTER_TEST;


