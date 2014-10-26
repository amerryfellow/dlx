library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.constants.all;

entity WRF is
	generic (
		NBIT:		integer;
		M:			integer;
		F:			integer;
		N:			integer;
		NREG:		integer;
		LOGNREG:	integer;
		LOGN:		integer
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

		ADDR_WR:		IN std_logic_vector(LOGNREG-1 downto 0);		-- Write Address
		ADDR_RD1:		IN std_logic_vector(LOGNREG-1 downto 0);		-- Read Address 1
		ADDR_RD2:		IN std_logic_vector(LOGNREG-1 downto 0);		-- Read Address 2

		DATAIN:			IN std_logic_vector(NBIT-1 downto 0);			-- Write data
		OUT1:			OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 1
		OUT2:			OUT std_logic_vector(NBIT-1 downto 0);			-- Read data 2

		MEMBUS:			INOUT std_logic_vector(NBIT-1 downto 0);		-- Memory Data Bus
		MEMCTR:			OUT std_logic_vector(10 downto 0);				-- Memory Control Signals
		BUSY:			OUT std_logic									-- The register file is busy
	);
end WRF;

-- Architectures

architecture behavioral of WRF is
	-- Suggested structures
	subtype REG_ADDR is natural range 0 to 2*F*N+M;		-- Number of cells
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(NBIT-1 downto 0);

	-- Signal instantiation
	signal REGISTERS : REG_ARRAY := ((others=> (others=>'0')));		-- Registers
	signal CWP: integer := 0;										-- Current Window Pointer ( up to number of windows )
	signal SWP: integer := 0;										-- Saved Window Pointer ( up to whatever we want )
	signal CANSAVE, CANRESTORE: std_logic;							-- Register File states

	signal SPILL: std_logic := '0';									-- Enable Memory Controller
	signal FILL: std_logic := '0';									-- Enable Memory Controller
	signal MEMBUSY: std_logic;
	signal MEMDONE: std_logic := '0';

	--
	-- Address translation routine
	--

	function ADDRESS_CONVERTER(CWP: natural; ADDR: std_logic_vector(LOGNREG-1 downto 0)) return natural is
		variable REAL_ADDR : natural;
		variable rCWP : natural;
		variable res: natural;
	begin
		if(conv_integer(ADDR) <= 3*N) then
			if( ADDR(LOGN+1) = '1' ) then	-- Current Window OUT -> Next Window In
				rCWP := CWP +1;
			else
				rCWP := CWP;
			end if;

			REAL_ADDR := conv_integer(ADDR(LOGN downto 0));

			res := (rCWP mod F)*2*N+REAL_ADDR;
		else
			res := 2*F*N + conv_integer(ADDR) - 3*N;
		end if;

		report "Address translation: CWP " & integer'image(CWP) & " ADDR " & integer'image(REAL_ADDR) & " => INDEX " & integer'image(res);
		
		return res;
	end ADDRESS_CONVERTER;

begin
	
	--
	-- Handle CALL and RETURN and WRITES
	--
	-- This process handles the three cases concurrently as they all need to drive the MEMBUS signal vector.
	-- Because VHDL creates a driver per process, it wouldn't be possible to create a different process per
	-- task as the drivers would conflict and force the vector to the undefined state. The solutions available
	-- were to instantiate REGISTERS as a shared variable, or to manage the three tasks with a single process.
	-- The latter is the choice we made.
	--

	PROCESS_CALLRETWR: process(CLK)
		variable index: integer := 0;
	begin
		-- Synchronous
		-- if CLK'event and CLK = '1' then

		-- Synchronous on double fronts
		if CLK'event then

			-- The memory is not busy! I may handle CALLs, RETs or WRs.
			if MEMBUSY = '0' then

				-- If 'reset'
				if(RESET = '1') then
					CWP <= 0;						-- Reset the CWP
					SWP <= 0;						-- Reset the SWP
					FILL <= '0';					-- Cancel any ongoing memory operation
					SPILL <= '0';					-- Cancel any ongoing memory operation

					REGISTERS <= (others =>(others =>'0'));
				else

					-- Is RETURN active?
					if(RET = '1') then
						if( CWP = 0 ) then
							report "ERROR: CWP IS ZERO! UNABLE TO RETURN";
						else
							CWP <= CWP-1;			-- Decrease the CWP

							-- If the Current Window Pointer is equal to the Saved Window Pointer, and the
							-- RET signal is High, it means that, in order to serve the proper registers, we
							-- first need to retrieve them from memory. Hence: fill.
							if(SWP = CWP) then
								report "Filling. CWP " & integer'image(CWP) & " SWP " & integer'image(SWP-1);

								FILL <= '1';		-- Activate the memory fill mechanism
							end if;
						end if;
					else
						-- Is CALL active?
						if(CALL = '1') then
							CWP <= CWP+1;			-- Increase the CWP

							-- If the Current Window register is equal to the sum of the maximum number of
							-- windows plus the Saved Window Pointer ( which is an index, truly ), minus two,
							-- it means that the output block of the next window will be overlapped with the
							-- input block of an in-use register, which therefore hasn't yet been spilled. This
							-- means that we need to spill it now.
							if(CWP >= F-2+SWP) then
								report "Spilling. CWP " & integer'image(CWP) & " SWP " & integer'image(SWP+1);

								SPILL <= '1';
							end if; -- SPILL
						end if; -- CALL
					end if; -- RET

					-- Is WRITE active?
					if WR = '1' then
						report "Im writing " & integer'image(conv_integer(DATAIN)) & " to " & integer'image(ADDRESS_CONVERTER(CWP, ADDR_WR));

						REGISTERS(ADDRESS_CONVERTER(CWP, ADDR_WR)) <= DATAIN;
					end if; -- WRITE
				end if; -- RESET

			-- If MEMBUSY is high, then there's something going on.
			else

				-- If MEMDONE is high, it means that we are done with the current memory operation: reset all the
				-- control signals and prepare the MEMBUS vector to receive data.
				if(MEMDONE = '1') then
					SPILL <= '0';
					FILL <= '0';
					MEMDONE <= '0';
					MEMBUS <= (others => 'Z');
					MEMCTR <= (others => '0');
				else

					-- Is SPILL active?
					if(SPILL = '1') then

						-- We use a variable index to keep track of which register has been spilled, and which is
						-- to spill next.
						report "SPILL! index: " & integer'image(index);

						MEMBUS <= REGISTERS(ADDRESS_CONVERTER(CWP+1, std_logic_vector(to_unsigned(index, LOGNREG))));
						MEMCTR <= (others => '1');
						index := index + 1;

						-- If we have reached twice the number of registers per window, it means that we have
						-- spilled two entire blocks ( I/O and LOCAL ): the spilling is then over. Notice that
						-- the check is done with 2*N and not 2*N-1 as index is a variable and is updated instantly.
						if( index = 2*N ) then
							report "Spilling over";
							index := 0;				-- Reset the index

							MEMDONE <= '1';			-- Memory operations are over

							SWP <= SWP+1;			-- Adjust the SWP
						end if; -- index
					else
						if(FILL = '1') then
							-- We use a variable index to keep track of which register has been spilled, and
							-- which is to spill next.
							report "FILL! index: " & integer'image(index);
							REGISTERS(ADDRESS_CONVERTER(CWP, std_logic_vector(to_unsigned(index, LOGNREG)))) <= MEMBUS;
							index := index + 1;

							-- If we have reached twice the number of registers per window, it means that we 
							-- have spilled two entire blocks ( I/O and LOCAL ): the spilling is then over.
							-- Notice that the check is done with 2*N and not 2*N-1 as index is a variable and
							-- is updated instantly.
							if( index = 2*N ) then
								report "Filling over";
								index := 0;			-- Reset the index

								MEMDONE <= '1';		-- Memory operations are over

								SWP <= SWP-1;		-- Adjust the SWP
							end if; -- index
						end if; -- FILL
					end if; -- SPILL
				end if; -- MEMDONE
			end if; -- MEMBUSY
		end if;
	end process;

	--
	-- Handle Read 1
	--
	-- This process is responsible for handling the first read port of the register file.
	--

	PROCESS_RD1: process(CLK)
	begin
		-- Synchronous
--		if CLK'event then

			-- Is RESET active?
			if (RESET = '1') then
				OUT1 <= (others=> '0');		-- Null
			else

				-- If the RF is enabled, the Read1 signal is active, and memory is not busy
				if RD1 = '1' and ENABLE = '1' and MEMBUSY = '0' then
					report "Im reading " & integer'image(conv_integer(ADDR_RD1(LOGN downto 0)));

					-- Fetch the data from the register
					OUT1 <= REGISTERS(ADDRESS_CONVERTER(CWP, ADDR_RD1));
				else
					OUT1 <= (others => 'Z');
				end if;
			end if;
--		end if;
	end process PROCESS_RD1;

	--
	-- Handle Read 2
	--
	-- This process is responsible for handling the second read port of the register file.
	--

	PROCESS_RD2: process(CLK)
	begin
		-- Synchronous
--		if CLK'event then

			-- Is RESET active?
			if (RESET = '1') then
				OUT2 <= (others => '0');

			else
				-- If the RF is enabled, the Read2 signal is active, and memory is not busy
				if RD2 = '1' and ENABLE = '1' and MEMBUSY = '0' then
					report "Im reading " & integer'image(conv_integer(ADDR_RD2(LOGN downto 0)));

					-- Fetch the data from the register
					OUT2 <= REGISTERS(ADDRESS_CONVERTER(CWP, ADDR_RD2));
				else
					OUT1 <= (others => 'Z');
				end if;
			end if;
--		end if;
	end process PROCESS_RD2;

	MEMBUSY <= FILL or SPILL;			-- The memory is busy when either FILL or SPILL are active
	BUSY <= MEMBUSY;					-- MEMBUSY, being an internal signal, can be both read and written.
end behavioral;

