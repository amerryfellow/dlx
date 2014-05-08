library IEEE;
use WORK.constants.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

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

	PCLOCK : process(CLK)
	begin
		CLK <= not(CLK) after 0.5 ns;
	end process;

	TB: process
	begin
		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 0

		WR			<= '1';
		CALL		<= '0';
		ADDR_WR		<= x"00";
		DATAIN		<= x"00";
		RET			<= '0';
		ADDR_RD1	<= x"00";
		RD1			<= '0';
		RD2 <= '0';
		ADDR_RD2 <= (others => '0');


		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 1

		WR			<= '1';
		CALL		<= '0';
		ADDR_WR		<= x"01";
		DATAIN		<= x"02";
		RET			<= '0';
		ADDR_RD1	<= x"00";
		RD1			<= '1';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 2

		WR			<= '1';
		CALL		<= '0';
		ADDR_WR		<= x"08";
		DATAIN		<= x"0A";
		RET			<= '0';
		ADDR_RD1	<= x"01";
		RD1			<= '1';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 2a ( GLOBALS WR )

		WR			<= '1';
		CALL		<= '0';
		ADDR_WR		<= x"61";
		DATAIN		<= x"90";
		RET			<= '0';
		ADDR_RD1	<= x"01";
		RD1			<= '1';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 2b ( GLOBALS WR )

		WR			<= '1';
		CALL		<= '0';
		ADDR_WR		<= x"64";
		DATAIN		<= x"94";
		RET			<= '0';
		ADDR_RD1	<= x"01";
		RD1			<= '1';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 3

		WR			<= '1';
		CALL		<= '0';
		ADDR_WR		<= x"45";
		DATAIN		<= x"FF";
		RET			<= '0';
		ADDR_RD1	<= x"08";
		RD1			<= '1';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 4

		WR			<= '0';
		CALL		<= '1';
		ADDR_WR		<= "00000000";
		DATAIN		<= x"02";
		RET			<= '0';
		ADDR_RD1	<= "00000000";
		RD1			<= '0';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 5 / CWP 1

		WR			<= '0';
		CALL		<= '1';
		ADDR_WR		<= "00000000";
		DATAIN		<= x"02";
		RET			<= '0';
		ADDR_RD1	<= x"05";
		RD1			<= '1';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 6 / CWP 2 ( GLOBALS RD )

		WR			<= '0';
		CALL		<= '1';
		ADDR_WR		<= "00000000";
		DATAIN		<= x"02";
		RET			<= '0';
		ADDR_RD1	<= "00000000";
		RD1			<= '0';
		RD2			<= '1';
		ADDR_RD2	<= x"64";

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 7 / CWP 3 ( GLOBALS RD )

		WR			<= '0';
		CALL		<= '1';
		ADDR_WR		<= "00000000";
		DATAIN		<= x"02";
		RET			<= '0';
		ADDR_RD1	<= "00000000";
		RD1			<= '0';
		ADDR_RD2	<= x"61";
		RD2			<= '1';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 8 / CWP 4

		WR			<= '0';
		CALL		<= '1';
		ADDR_WR		<= "00000000";
		DATAIN		<= x"02";
		RET			<= '0';
		ADDR_RD1	<= "00000000";
		RD1			<= '0';
		RD2			<= '0';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 9 / CWP 5

		WR			<= '0';
		CALL		<= '1';
		ADDR_WR		<= "00000000";
		DATAIN		<= x"02";
		RET			<= '0';
		ADDR_RD1	<= "00000000";
		RD1			<= '0';

		wait until CLK'event and CLK='1';					-- CLK 10 / CWP 6

		CALL		<= '0';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 10 / CWP 6

		WR			<= '0';
		CALL		<= '1';
		ADDR_WR		<= "00000000";
		DATAIN		<= x"02";
		RET			<= '0';
		ADDR_RD1	<= "00000000";
		RD1			<= '0';

		wait until CLK'event and CLK='1';					-- CLK 10 / CWP 6

		CALL		<= '0';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 11 / CWP 7

		WR			<= '1';
		CALL		<= '0';
		ADDR_WR		<= x"00";
		DATAIN		<= x"EE";
		RET			<= '0';
		ADDR_RD1	<= x"01";
		RD1			<= '1';
		ADDR_RD2	<= x"64";
		RD2			<= '1';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 12 / CWP 7

		WR			<= '0';
		CALL		<= '0';
		ADDR_WR		<= "00000000";
		DATAIN		<= x"02";
		RET			<= '1';
		ADDR_RD1	<= "00000000";
		RD1			<= '0';
		RD2			<= '0';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 13 / CWP 6

		WR			<= '0';
		CALL		<= '1';
		ADDR_WR		<= "00000000";
		DATAIN		<= x"02";
		RET			<= '0';
		ADDR_RD1	<= "00000000";
		RD1			<= '0';

		wait until CLK'event and CLK='1';					-- CLK 10 / CWP 6

		CALL		<= '0';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 14 / CWP 7

		WR			<= '0';
		CALL		<= '1';
		ADDR_WR		<= "00000000";
		DATAIN		<= x"02";
		RET			<= '0';
		ADDR_RD1	<= "00000000";
		RD1			<= '0';

		wait until CLK'event and CLK='1';					-- CLK 10 / CWP 6

		CALL		<= '0';

		wait until CLK'event and CLK='1' and BUSY='0';		-- CLK 13 / CWP 8

		WR			<= '0';
		CALL		<= '1';
		ADDR_WR		<= x"00";
		DATAIN		<= x"02";
		RET			<= '0';
		ADDR_RD1	<= x"05";
		RD1			<= '1';

		wait until CLK'event and CLK='1';					-- CLK 10 / CWP 6

		CALL		<= '0';

		wait for 8000000 ns;
end process;

end TESTA;

