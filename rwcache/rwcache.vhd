library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use work.RWCACHE_PKG.all;

entity RWCACHE is
	port (
		CLK						: in std_logic;
		RST						: in std_logic;  -- active high
		ENABLE					: in std_logic;
		READNOTWRITE			: in std_logic;
		ADDRESS					: in std_logic_vector(DATA_SIZE - 1 downto 0);
		INOUT_DATA				: inout std_logic_vector(DATA_SIZE - 1 downto 0);
		STALL						: out std_logic;
		RAM_ISSUE				: out std_logic;
		RAM_READNOTWRITE		: out std_logic;
		RAM_ADDRESS				: out std_logic_vector(DATA_SIZE - 1 downto 0);
		RAM_DATA					: inout std_logic_vector(2*DATA_SIZE - 1 downto 0);
		RAM_READY				: in std_logic
	);
end RWCACHE;

architecture Behavioral of RWCACHE is
	signal CACHE							: RWCACHE_TYPE;
	signal STATE_CURRENT					: state_type;
	signal STATE_NEXT						: state_type;
	signal INT_ISSUE_RAM_READ				: std_logic;
	signal INT_INOUT_DATA					: std_logic_vector(DATA_SIZE -1 downto 0);
	signal INT_RAM_DATA						: std_logic_vector(2*DATA_SIZE -1 downto 0) := (others => 'Z');
	signal NOP_OUT							: std_logic;

begin
	--
	-- FSM Management
	--
	state_update: process(CLK, RST, STATE_NEXT)
	begin
		if RST = '1' then
			STATE_CURRENT <= STATE_FLUSH_MEM;
		elsif clk'event and clk = '1' then
			STATE_CURRENT <= STATE_NEXT;
		end if;
	end process;

	--
	-- The MONSTER
	--
	main: process(STATE_CURRENT, ADDRESS, RAM_READY,READNOTWRITE,INOUT_DATA)
		variable HIT		 		: std_logic:='0';
		variable int_mem			: std_logic_vector(2*DATA_SIZE - 1 downto 0);
		variable currentLine		: natural range 0 to 2**RWCACHE_COUNTERSIZE;
		variable count_miss 		: natural range 0 to RWCACHE_NUMLINES;
		variable index				: natural range 0 to 2**RWCACHE_INDEXOFFSET - 1;
		variable lineIndex			: natural range 0 to RWCACHE_NUMLINES;
		variable test				: natural;
		variable address_stall		: std_logic_vector(DATA_SIZE - 1 downto 0);
		variable data_stall			: std_logic_vector(DATA_SIZE - 1 downto 0);
		variable readnotwrite_stall	: std_logic := '0';
		variable alreadyWrote		: std_logic := '0';
	begin
		case (STATE_CURRENT) is

		when  STATE_FLUSH_MEM =>
--			ADDRESS <= (others => '0');
			INT_INOUT_DATA <= (others =>'0');
			for i in 0 to RWCACHE_NUMSETS - 1 loop
				for j in 0 to RWCACHE_NUMLINES - 1 loop

					CACHE(i)(j).tag( RWCACHE_TAGSIZE - 1 downto 0 ) <= (others => '1');
					CACHE(i)(j).valid <= '0'; -- dirty bit
					CACHE(i)(j).counter <= 0;

					NOP_OUT <= '1';

					for k in 0 to RWCACHE_WORDS - 1 loop
						CACHE(i)(j).words(k) <= (others => '1');
					end loop;

				end loop;
			end loop;

			HIT := '0';
			INT_ISSUE_RAM_READ <= '0';
			STATE_NEXT <= STATE_COMPARE_TAGS;

		-- IDLE STATE
		-- Do nothing, assume miss
		when STATE_PUSH =>
			STATE_NEXT <= STATE_MISS;

		-- MISS STATE
		-- Probe the RAM and wait until RAM_READY
		when STATE_MISS =>
			-- I gots the data
			if RAM_READY = '1' then

				-- Identify line to hold the new data
				currentLine := GET_REPLACEMENT_LINE(address_stall, CACHE);

				-- Identify word index inside the line

				report "----------------- Instr " & integer'image(conv_integer(unsigned(address_stall))) & "-> Writing TAG " & integer'image(conv_integer(unsigned(address_stall(DATA_SIZE-1 downto RWCACHE_TAGOFFSET)))) & " in set " & integer'image(GET_SET(address_stall)) & " line " & integer'image(currentLine);

				-- Store TAG
				CACHE(GET_SET(address_stall))(currentLine).tag <= address_stall(DATA_SIZE - 1 downto RWCACHE_TAGOFFSET);

				-- Reset LFU counter
				CACHE(GET_SET(address_stall))(currentLine).counter <= 0;

				-- Set valid bit
				CACHE(GET_SET(address_stall))(currentLine).valid <= '1';

				-- Fetch the line from memory data bus and write it into the cache data
				for i in 0 to RWCACHE_WORDS - 1 loop
					if( READNOTWRITE = '0' and i = conv_integer(unsigned(address_stall(RWCACHE_INDEXOFFSET - 1 downto 0)))) then
						CACHE(GET_SET(address_stall))(currentLine).words(i) <= data_stall;
					else
						CACHE(GET_SET(address_stall))(currentLine).words(i)
							<= RAM_DATA(((i+1)*DATA_SIZE - 1) downto i*DATA_SIZE);
					end if;
				end loop;

				-- Write the DATA_OUT
				if(readnotwrite_stall = '1') then
					INT_INOUT_DATA <= RAM_DATA(
						((conv_integer(unsigned(address_stall(RWCACHE_INDEXOFFSET - 1 downto 0)))+1)*DATA_SIZE - 1) 
						downto conv_integer(unsigned(address_stall(RWCACHE_INDEXOFFSET - 1 downto 0)))*DATA_SIZE);
				end if;

				STATE_NEXT <= STATE_COMPARE_TAGS;
				NOP_OUT <= '0';
				INT_ISSUE_RAM_READ <= '0';
			end if;

		-- Fetch instruction and print it if HIT
		when STATE_COMPARE_TAGS =>
			if(ENABLE = '1') then
				NOP_OUT <= '1';
				alreadyWrote := '0';

				-- Look in the CACHE
				for i in 0 to RWCACHE_NUMLINES - 1 loop

					-- Is it a HIT ?
					HIT := COMPARE_TAGS(
						ADDRESS(DATA_SIZE - 1 downto RWCACHE_TAGOFFSET),
						CACHE(GET_SET(ADDRESS))(i).tag(RWCACHE_TAGSIZE - 1 downto 0)
					);

					-- HIT!
					if (HIT = '1') then

						-- Is the entry valid?
						if(CACHE(GET_SET(ADDRESS))(i).valid = '1') then
							lineIndex:= i;

					--		report string'("STATE: ") & integer'image(conv_integer(unsigned(STATE_CURRENT))) & string'(" || ADDRESS: ") & integer'image(conv_integer(unsigned(ADDRESS))) & string'(" || HIT: ") & integer'image(conv_integer(conv_integer(HIT))) & string'(" || i: ") & integer'image(i) & string'(" || offset: ") & integer'image(GET_SET(ADDRESS)) & string'(" || count_miss = ") & integer'image(count_miss) & string'(" || test: ") & integer'image(test);

							HIT := '0'; -- Reset HIT

							if(READNOTWRITE = '1') then
								-- Print out the instruction
								INT_INOUT_DATA <= CACHE(
									GET_SET(ADDRESS))(lineIndex).words(
										conv_integer(unsigned(ADDRESS(RWCACHE_INDEXOFFSET - 1 downto 0))
									)
								);
							else
								CACHE(
									GET_SET(ADDRESS))(lineIndex).words(
										conv_integer(unsigned(ADDRESS(RWCACHE_INDEXOFFSET - 1 downto 0))
									)
								) <= INOUT_DATA;
								report string'("I'm here and inout_data is:") & integer'image(conv_integer(signed(inout_data))); 
								alreadyWrote := '1';
							end if;

							NOP_OUT <= '0';

							-- Next state: the same
							STATE_NEXT <= STATE_COMPARE_TAGS;

							count_miss := 0;
							exit;

						-- The entry is not valid. Count as miss, save its index
						else
							count_miss := count_miss + 1;
						end if;

					-- Miss :(
					else
						count_miss := count_miss + 1;
					end if;

				end loop;

				-- Miss?
				if(count_miss = RWCACHE_NUMLINES) then
					address_stall := ADDRESS;
					readnotwrite_stall := READNOTWRITE;
					data_stall := INOUT_DATA;
					INT_ISSUE_RAM_READ <= '1';
					STATE_NEXT <= STATE_MISS;
				end if;

				-- Reset the counter
				count_miss := 0;
			else
				STATE_NEXT <= STATE_COMPARE_TAGS;
			end if;
		when OTHERS => null;
		end case;

	end process;

	STALL			<= NOP_OUT;
	RAM_ISSUE		<= INT_ISSUE_RAM_READ;
	RAM_ADDRESS		<= ADDRESS(DATA_SIZE - 1 downto 1) & '0' when INT_ISSUE_RAM_READ = '1' else (others => 'Z');
	RAM_DATA			<= INT_RAM_DATA when NOP_OUT = '1' else (others =>'Z');
	INOUT_DATA		<= INT_INOUT_DATA when READNOTWRITE = '1' else (others =>'Z');
end Behavioral;
