library IEEE;
use WORK.constants.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.std_logic_1164.all;

entity TBWRF is
	generic(
			NBIT:	integer	:= numBit;
			M:		integer := numGlobals;
			F:		integer := numWindows;
			N:		integer := numRegsPerWin;
			NREG:	integer := numGlobals + 2*numWindows*numRegsPerWin;
			LOGN:	integer := LOG(numRegsPerWin)
		);
end TBWRF;

architecture TESTA of TBWRF is
	signal CLK: std_logic := '0';
	signal RESET: std_logic;
	signal ENABLE: std_logic;
	signal RD1: std_logic;
	signal RD2: std_logic;
	signal WR: std_logic;
	signal ADDR_WR: std_logic_vector(LOG(NREG)-1 downto 0);
	signal ADDR_RD1: std_logic_vector(LOG(NREG)-1 downto 0);
	signal ADDR_RD2: std_logic_vector(LOG(NREG)-1 downto 0);
	signal DATAIN: std_logic_vector(NBIT-1 downto 0);
	signal OUT1: std_logic_vector(NBIT-1 downto 0);
	signal OUT2: std_logic_vector(NBIT-1 downto 0);

	signal CALL:	std_logic := '0';					-- Call -> Next context
	signal RET: std_logic := '0';						-- Return -> Previous context

	signal MEMBUS:	std_logic_vector(NBIT-1 downto 0);	-- Memory Data Bus
	signal MEMCTR:	std_logic_vector(10 downto 0);		-- Memory Control Signals
	signal BUSY:	std_logic;

	component WRF
		port (
			CLK:			IN std_logic;
			RESET:			IN std_logic;
			ENABLE:			IN std_logic;

			CALL:			IN std_logic;									-- Call -> Next context
			RET:			IN std_logic;									-- Return -> Previous context

			RD1:			IN std_logic;									-- Read 1
			RD2:			IN std_logic;									-- Read 2
			WR:				IN std_logic;									-- Write

			ADDR_WR:		IN std_logic_vector(LOG(NREG)-1 downto 0);		-- Write Address
			ADDR_RD1:		IN std_logic_vector(LOG(NREG)-1 downto 0);		-- Read Address 1
			ADDR_RD2:		IN std_logic_vector(LOG(NREG)-1 downto 0);		-- Read Address 2

			DATAIN:			IN std_logic_vector(NBIT-1 downto 0);			-- Write data
			OUT1:			OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 1
			OUT2:			OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 2

			MEMBUS:			INOUT std_logic_vector(NBIT-1 downto 0);		-- Memory Data Bus
			MEMCTR:			OUT std_logic_vector(10 downto 0);				-- Memory Control Signals
			BUSY:			OUT std_logic									-- The register file is busy
		);
	end component;

begin 

	RG:WRF
	PORT MAP (CLK,RESET,ENABLE,CALL,RET,RD1,RD2,WR,ADDR_WR,ADDR_RD1,ADDR_RD2,DATAIN,OUT1,OUT2,MEMBUS,MEMCTR,BUSY);

	ENABLE <= '1';
	RESET <= '0';
	
	-- This testbench fills cells:
	-- 0-0 => 01
	-- 0-1 => 02
	-- 1-0 => 93
	-- 1-2 => 94
	-- and then should read:
	-- 0-1 => 02
	-- 0-2 => UU
	-- 1-0 => 93
	-- to do this we change context 3 times via CALL and RET.

	WR		<= '1';
	CALL	<= '0';
	ADDR_WR	<= "00000000";
	DATAIN	<= x"01";
	RET		<= '0';
	ADDR_RD1 <=	"00000010";


	-- First: write to 0-0, 0-1, 1-0, 1-2
	WR <=	'1', '0' after 3.2 ns, '1' after 9.2 ns, '0' after 12.2 ns, '1' after 16.2 ns, '0' after 19.2 ns;
	CALL <=	'0', '1' after 4.2 ns, '0' after 9.2 ns, '1' after 14.2 ns, '0' after 16.2 ns;

	ADDR_WR <=	"00000000",
				"00000001" after 1.2 ns,
				"00000011" after 2.2 ns,
				"00000000" after 9.2 ns,
				"00000010" after 10.2 ns,
				"00001010" after 11.2 ns,
				"00000000" after 16.2 ns,
				"00000001" after 17.2 ns,
				"00000010" after 18.2 ns;

	DATAIN <=   x"01",
				x"03" after 1.2 ns,
				x"05" after 2.2 ns,
				x"AA" after 9.2 ns,
				x"BB" after 10.2 ns,
				x"CC" after 11.2 ns,
				x"DD" after 16.2 ns,
				x"EE" after 17.2 ns,
				x"FF" after 18.2 ns;

	-- Now read 0-1, 0-2, 1-0
	RET <= '0', '1' after 22.2 ns, '0' after 29.2 ns;

	ADDR_RD1 <=	"00000010",
				"00001010" after 12.2 ns,
				"00000000" after 13.2 ns,
				"00000000" after 19.2 ns,
				"00000001" after 20.2 ns,
				"00000010" after 21.2 ns,
				"00000000" after 29.2 ns,
				"00000001" after 30.2 ns,
				"00000010" after 31.2 ns;

	RD1 <= '0',
		   '1' after 3.2 ns,
		   '0' after 4.2 ns,
		   '1' after 12.2 ns,
		   '0' after 14.2 ns,
		   '1' after 19.2 ns,
		   '0' after 22.2 ns,
		   '1' after 29.2 ns;

	RD2 <= '0';
	ADDR_RD2 <= (others => '0');

	PCLOCK : process(CLK)
	begin
		CLK <= not(CLK) after 0.5 ns;
	end process;

end TESTA;

