library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.constants.all;

entity SRF is
	generic(
		NBIT:	integer	:= numBit;
		NREG:	natural	:= NREGISTER
	);

	port (
		CLK:		IN std_logic;
		RESET:		IN std_logic;
		ENABLE:		IN std_logic;

		RNOTW:		IN std_logic;								-- Read not Write
		ADDR:		IN std_logic_vector(LOG(NREG)-1 downto 0);		-- Read Address

		DIN:		IN std_logic_vector(NBIT-1 downto 0);			-- Write data
		DOUT:		OUT std_logic_vector(NBIT-1 downto 0);			-- Read data
	);
end SRF;

-- Architectures

architecture behavioral of SRF is
	-- Suggested structures
	subtype REG_ADDR is natural range 0 to NREG-1; -- using natural type
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(NBIT-1 downto 0);

	-- Signal instantiation
	signal REGISTERS : REG_ARRAY;

begin

	PROCESS_WORKER: process(CLK)
	begin
		-- Synchronous
		if CLK'event and CLK = '1' then
			-- If 'reset'
			if (RESET = '1') then
				DOUT <= (others=> '0');

			-- Elsewise
			else
				if (ENABLE = '1') then
					-- If Read
					if RNOTW = '1' then
						DOUT <= REGISTERS(conv_integer(ADDR));
					else
						REGISTERS(conv_integer(ADDR)) <= DIN;
					end if;
				end if;
			end if;
		end if;
	end process PROCESS_WORKER;
end behavioral;

