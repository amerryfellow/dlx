library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use work.myTypes.all;
use work.cu.all;
--use work.all;

entity BHT is
	generic (
		LSBITS		: integer := 8;	-- How many bits is the BHT addressed by?
		LINES		: integer := 2 ** LSBITS
	);

	port (
		Clk :				in std_logic;		-- Clock
		Rst :				in std_logic;		-- Reset:Active-Low

		PC :				out std_logic;
		NPC :				out std_logic;

		LAST :				in std_logic;
		ADDR :				in std_logic_vector(31 downto 0);
	);
end BHT;

architecture CORRELATING_PREDICTOR of BHT is
	type LOCAL_HISTORY is array (1 downto 0) of std_logic := '0';
	type ARRAY_LOCAL is array (0 to LINES-1) of LOCAL_HISTORY;
	variable HISTORY : ARRAY_LOCAL;

	variable INDEX0 : integer;
	variable INDEX1 : integer;

	variable GLOBAL_HISTORY :	std_logic_vector(1 downto 0) := (others => '0');
	variable PRED :				std_logic;
	variable LAST_PREDICTION :	std_logic;
	variable RIGHT_PREDICTION :	std_logic;

	signal IPC :	integer;
	signal INPC :	integer;

begin

	-- 0 : Not Taken ; 1 : Taken

	PREDICTOR: process(Clk, Rst)
	begin
		INDEX0 := to_integer(signed(ADDR));
		INDEX1 := to_integer(signed(GLOBAL_HISTORY));

		if Rst = '0' then
			PRED <= '0';
			GLOBAL_HISTORY <= (others => '0');

		elsif Clk'event and Clk = '1' then
			PRED <= HISTORY( INDEX0 )( INDEX1 )(1);

			GLOBAL_HISTORY := GLOBAL_HISTORY(0) & LAST;

			RIGHT_PREDICTION := not ( LAST xor LAST_PREDICTION );

			-- Wrong prediction, must stall and update PC
			if RIGHT_PREDICTION = '0' then
				
		end if;
	end process;
end
