library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.constants.all;

entity WRF is
	generic (
		NBIT:				integer;
		numWindows:			integer;
		numRegsPerWin:		integer;
		logNumWindows:		integer;
		logNumRegsPerWin:	integer
	);

	port (
		CLK:			IN std_logic;
		RESET:			IN std_logic;
		ENABLE:			IN std_logic;

		CALL:			IN std_logic;									-- Call -> Next context
		RET:			IN std_logic;									-- Return -> Previous context

		RD1:			IN std_logic;									-- Read 1
		RD2:			IN std_logic;									-- Read 2
		WR:				IN std_logic;									-- Write

		ADDR_RD1:		IN std_logic_vector(logNumRegsPerWin+1 downto 0);		-- Read Address 1
		ADDR_RD2:		IN std_logic_vector(logNumRegsPerWin+1 downto 0);		-- Read Address 2
		ADDR_WRC:		IN std_logic_vector(logNumRegsPerWin+1 downto 0);		-- Write Address
		ADDR_WR:		IN std_logic_vector(logNumWindows+logNumRegsPerWin+1 downto 0);		-- Write Address

		REAL_ADDR_RD1:	OUT std_logic_vector(logNumWindows+logNumRegsPerWin+1 downto 0);		-- Read Address 1
		REAL_ADDR_RD2:	OUT std_logic_vector(logNumWindows+logNumRegsPerWin+1 downto 0);		-- Read Address 2
		REAL_ADDR_WR:	OUT std_logic_vector(logNumWindows+logNumRegsPerWin+1 downto 0);		-- Write Address

		OUT1:			OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 1
		OUT2:			OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 2
		DATAIN:			IN std_logic_vector(NBIT-1 downto 0)			-- Write data
	);
end WRF;

-- Architectures

architecture behavioral of WRF is
	-- Suggested structures
	subtype REG_ADDR is natural range 0 to 2*numWindows*numRegsPerWin+numRegsPerWin;		-- Number of cells
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(NBIT-1 downto 0);

	-- Signal instantiation
	signal REGISTERS : REG_ARRAY := ((others=> (others=>'0')));		-- Registers
	signal CWP				: integer := 0;
	signal CWPPLUSONE		: integer := 1;
	signal INT_REAL_ADDR_RD1	: integer;
	signal INT_REAL_ADDR_RD2	: integer;
	signal INT_REAL_ADDR_WR		: integer;

begin

	ADDRESS_CONVERTER_RD1 : process(CWP, ADDR_RD1)
		variable baseAddr : std_logic_vector(logNumWindows+1 downto 0);
		variable rCWP : natural range 0 to numWindows;
		variable vCWP : std_logic_vector(logNumWindows-1 downto 0);
		variable vGlob : std_logic;
		variable INNOTLOCAL : std_logic;
		variable vRealAddress : std_logic_vector(2+logNumWindows+logNumRegsPerWin-1 downto 0);
	begin
		vGlob := '0';

--		report "Converted " & integer'image(conv_integer(ADDR_RD1));

		-- Either OUT or GLOBAL
		if ADDR_RD1(logNumRegsPerWin+1) = '1' then
			INNOTLOCAL := '0';

			-- Global
			if ADDR_RD1(logNumRegsPerWin) = '1' then
				rCWP := 0;
				vGlob := '1';

--				report "Global";
			-- Out
			else
				rCWP := CWPPLUSONE;

--				report "Out";
			end if;
		else
			rCWP := CWP;
			INNOTLOCAL := ADDR_RD1(logNumRegsPerWin);

--			report "Local";
		end if;

		vCWP := std_logic_vector(to_unsigned(rCWP, logNumWindows));
		baseAddr := vGlob & vCWP & INNOTLOCAL;

		vRealAddress := baseAddr & ADDR_RD1(logNumRegsPerWin-1 downto 0);
		REAL_ADDR_RD1 <= vRealAddress;
		INT_REAL_ADDR_RD1 <= conv_integer(vRealAddress);

--		report "to address " & integer'image(INT_REAL_ADDR_RD1);
	end process;

	ADDRESS_CONVERTER_RD2 : process(CWP, ADDR_RD2)
		variable baseAddr : std_logic_vector(logNumWindows+1 downto 0);
		variable rCWP : natural range 0 to numWindows;
		variable vCWP : std_logic_vector(logNumWindows-1 downto 0);
		variable vGlob : std_logic;
		variable INNOTLOCAL : std_logic;
		variable vRealAddress : std_logic_vector(2+logNumWindows+logNumRegsPerWin-1 downto 0);
	begin
		vGlob := '0';

		-- Either OUT or GLOBAL
		if ADDR_RD2(logNumRegsPerWin+1) = '1' then
			INNOTLOCAL := '0';

			-- Global
			if ADDR_RD2(logNumRegsPerWin) = '1' then
				rCWP := 0;
				vGlob := '1';
			-- Out
			else
				rCWP := CWPPLUSONE;
			end if;
		else
			rCWP := CWP;
			INNOTLOCAL := ADDR_RD2(logNumRegsPerWin);
		end if;

		vCWP := std_logic_vector(to_unsigned(rCWP, logNumWindows));
		baseAddr := vGlob & vCWP & INNOTLOCAL;

		vRealAddress := baseAddr & ADDR_RD2(logNumRegsPerWin-1 downto 0);
		REAL_ADDR_RD2 <= vRealAddress;
		INT_REAL_ADDR_RD2 <= conv_integer(vRealAddress);
	end process;

	ADDRESS_CONVERTER_WR : process(CWP, ADDR_WRC)
		variable baseAddr : std_logic_vector(logNumWindows+1 downto 0);
		variable rCWP : natural range 0 to numWindows;
		variable vCWP : std_logic_vector(logNumWindows-1 downto 0);
		variable vGlob : std_logic;
		variable INNOTLOCAL : std_logic;
		variable vRealAddress : std_logic_vector(2+logNumWindows+logNumRegsPerWin-1 downto 0);
	begin
		vGlob := '0';

		-- Either OUT or GLOBAL
		if ADDR_WRC(logNumRegsPerWin+1) = '1' then
			INNOTLOCAL := '0';

			-- Global
			if ADDR_WRC(logNumRegsPerWin) = '1' then
				rCWP := 0;
				vGlob := '1';
			-- Out
			else
				rCWP := CWPPLUSONE;
			end if;
		else
			rCWP := CWP;
			INNOTLOCAL := ADDR_WRC(logNumRegsPerWin);
		end if;

		vCWP := std_logic_vector(to_unsigned(rCWP, logNumWindows));
		baseAddr := vGlob & vCWP & INNOTLOCAL;

		vRealAddress := baseAddr & ADDR_WRC(logNumRegsPerWin-1 downto 0);
		REAL_ADDR_WR <= vRealAddress;
	end process;

	--
	-- Handle CALL and RETURN and WRITES
	--
	-- This process handles the three cases concurrently as they all need to drive the MEMBUS signal vector.
	-- Because VHDL creates a driver per process, it wouldn't be possible to create a different process per
	-- task as the drivers would conflict and force the vector to the undefined state. The solutions available
	-- were to instantiate REGISTERS as a shared variable, or to manage the three tasks with a single process.
	-- The latter is the choice we made.
	--

	PROCESS_CALLRETWR: process(CLK, RESET, RET, CALL, WR, DATAIN, ADDR_WR)
		variable index: integer := 0;
	begin
		-- Synchronous
		-- if CLK'event and CLK = '1' then

		-- Synchronous on double fronts
		if CLK'event and CLK = '0' then

			-- If 'reset'
			if(RESET = '1') then
				CWP <= 0;						-- Reset the CWP

				REGISTERS <= (others =>(others =>'0'));
			else
				-- Is RETURN active?
				if(RET = '1') then
					if( CWP = 0 ) then
--						report "ERROR: CWP IS ZERO! UNABLE TO RETURN";
					else
						CWPPLUSONE <= CWP;
						CWP <= CWP-1;			-- Decrease the CWP
					end if;
				else
					-- Is CALL active?
					if(CALL = '1') then
						CWP <= CWPPLUSONE;
						CWPPLUSONE <= CWPPLUSONE+1;			-- Increase the CWP
					end if; -- CALL

				end if; -- RET

				-- Is WRITE active?
				if WR = '1' then
--				report "Im writing " & integer'image(conv_integer(DATAIN)) & " to " & integer'image(conv_integer(ADDR_WR));
					REGISTERS(conv_integer(ADDR_WR)) <= DATAIN;
				end if; -- WRITE
			end if; -- RESET
		end if;
	end process;

	OUT1 <= REGISTERS(INT_REAL_ADDR_RD1) when ( RD1 = '1' and ENABLE = '1' ) else (others => '0');
	OUT2 <= REGISTERS(INT_REAL_ADDR_RD2) when ( RD2 = '1' and ENABLE = '1' ) else (others => '0');

end behavioral;

