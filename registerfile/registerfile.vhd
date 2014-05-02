library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.constants.all;


entity RF is
	generic(
		NBIT:	integer	:= numBit;
		NREG:	natural	:= NREGISTER
	);

	port (
		 CLK:		IN std_logic;
		 RESET:		IN std_logic;
		 ENABLE:	IN std_logic;

		 RD1:		IN std_logic;									-- Read 1
		 RD2:		IN std_logic;									-- Read 2
		 WR:		IN std_logic;									-- Write

		 ADD_WR:	IN std_logic_vector(LOG(NREG)-1 downto 0);		-- Write Address
		 ADD_RD1:	IN std_logic_vector(LOG(NREG)-1 downto 0);		-- Read Address 1
		 ADD_RD2:	IN std_logic_vector(LOG(NREG)-1 downto 0);		-- Read Address 2

		 DATAIN:	IN std_logic_vector(NBIT-1 downto 0);			-- Write data
		 OUT1:		OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 1
		 OUT2:		OUT std_logic_vector(NBIT-1 downto 0)			-- Read data 2
	 );
end RF;

-- Architectures

architecture behavioral of RF is
	-- Suggested structures
	subtype REG_ADDR is natural range 0 to NREG-1; -- using natural type
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(NBIT-1 downto 0);

	-- Signal instantiation
	signal REGISTERS : REG_ARRAY;
	signal TEMP_RD1,TEMP_RD2: std_logic_vector(NBIT-1 downto 0);

begin

	-- Handle Read 1
	PROCESS_RD1: process(CLK, RD1, RESET, ENABLE, ADD_RD1)
	begin
		-- Synchronous
		if CLK'event and CLK = '1' then
			-- If 'reset'
			if (RESET = '1') then
				TEMP_RD1 <= (others=> '0');		-- Null

			-- Elsewise
			else
				-- If Read 1 and Enable
				if RD1 = '1' and ENABLE = '1' then
					TEMP_RD1 <= REGISTERS(conv_integer(ADD_RD1));
				end if;	
			end if;
		end if;
	end process PROCESS_RD1;

	-- Handle Read 2
	PROCESS_RD2: process(CLK,RD2,RESET,ENABLE,ADD_RD2)
	begin
		-- Synchronous
		if CLK'event and CLK='1' then
			-- If 'reset'
			if (RESET = '1') then 
				TEMP_RD2 <= (others => '0');
				
			-- Elsewise
			else
				-- If Read 2 and Enable
				if RD2 = '1' and ENABLE = '1' then
					TEMP_RD2 <= REGISTERS(conv_integer((ADD_RD2)));
				end if;
			end if;
		end if;
	end process PROCESS_RD2;

	-- Handle Write
	PROCESS_WR: process(CLK,WR,RESET,ENABLE,ADD_WR)
	begin
		-- Synchronous
		if CLK'event and CLK='1' then
			-- If 'reset'
			if (RESET = '1') then
				null;

			-- Elsewise
			else
				-- If Write and Enable
				if WR = '1' and ENABLE = '1' then
					REGISTERS(conv_integer(ADD_WR)) <= DATAIN;
				end if;
			end if;
		end if;
	end process PROCESS_WR;

	OUT1 <= TEMP_RD1;
	OUT2 <= TEMP_RD2;
end behavioral;

