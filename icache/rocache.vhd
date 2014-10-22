library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use work.cachepkg.all;

entity ROCACHE is
	port (
		CLK						: in std_logic;
		RST						: in std_logic;  -- active high
		ENABLE					: in std_logic;
		ADDRESS					: in std_logic_vector(INSTR_SIZE - 1 downto 0);
		OUT_DATA				: out std_logic_vector(INSTR_SIZE - 1 downto 0);
		STALL					: out std_logic;
		RAM_ISSUE				: out std_logic;
		RAM_ADDRESS				: out std_logic_vector(INSTR_SIZE - 1 downto 0);
		RAM_DATA				: in std_logic_vector(2*INSTR_SIZE - 1 downto 0);
		RAM_READY				: in std_logic
	);
end ROCACHE;

architecture Behavioral of ROCACHE is
	signal ICACHE							: ROCACHE_TYPE;
	signal STATE_CURRENT					: state_type;
	signal STATE_NEXT						: state_type;
	signal INT_ISSUE_RAM_READ				: std_logic;
	signal INT_OUT_DATA						: std_logic_vector(INSTR_SIZE -1 downto 0) := (others => '0');
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
	main: process(STATE_CURRENT, ADDRESS, RAM_READY)
		variable HIT		 		: std_logic:='0';
		variable int_mem			: std_logic_vector(2*INSTR_SIZE - 1 downto 0);
		variable currentLine		: natural range 0 to 2**ROCACHE_COUNTERSIZE;
		variable count_miss 		: natural range 0 to ROCACHE_NUMLINES;
		variable index				: natural range 0 to 2**ROCACHE_INDEXOFFSET - 1;
		variable lineIndex				: natural range 0 to ROCACHE_NUMLINES;
		variable test				: natural;
		variable address_stall		: std_logic_vector(INSTR_SIZE - 1 downto 0);
	begin
		case (STATE_CURRENT) is

		when  STATE_FLUSH_MEM =>
--			ADDRESS <= (others => '0');
			for i in 0 to ROCACHE_NUMSETS - 1 loop
				for j in 0 to ROCACHE_NUMLINES - 1 loop

					ICACHE(i)(j).tag( ROCACHE_TAGSIZE - 1 downto 0 ) <= (others => '1');
					ICACHE(i)(j).valid <= '0'; -- dirty bit
					ICACHE(i)(j).counter <= 0;

					NOP_OUT <= '1';

					for k in 0 to ROCACHE_WORDS - 1 loop
						ICACHE(i)(j).words(k) <= (others => '1');
					end loop;

				end loop;
			end loop;

			HIT := '0';
			INT_ISSUE_RAM_READ <= '0';
			STATE_NEXT <= STATE_COMPARE_TAGS;

		-- IDLE STATE
		-- Do nothing, assume miss
		when STATE_IDLE =>
			STATE_NEXT <= STATE_MISS;

		-- MISS STATE
		-- Probe the RAM and wait until RAM_READY
		when STATE_MISS =>
			-- I gots the data
			if RAM_READY = '1' then

				-- Identify line to hold the new data
				currentLine := GET_REPLACEMENT_LINE(address_stall, ICACHE);

				report "----------------- Instr " & integer'image(conv_integer(unsigned(address_stall))) & "-> Writing TAG " & integer'image(conv_integer(unsigned(address_stall(INSTR_SIZE-1 downto ROCACHE_TAGOFFSET)))) & " in set " & integer'image(GET_SET(address_stall)) & " line " & integer'image(currentLine);

				-- Store TAG
				ICACHE(GET_SET(address_stall))(currentLine).tag <= address_stall(INSTR_SIZE - 1 downto ROCACHE_TAGOFFSET);

				-- Reset LFU counter
				ICACHE(GET_SET(address_stall))(currentLine).counter <= 0;

				-- Set valid bit
				ICACHE(GET_SET(address_stall))(currentLine).valid <= '1';

				-- Fetch the line from memory data bus and write it into the cache data
				for i in 0 to ROCACHE_WORDS - 1 loop
					ICACHE(GET_SET(address_stall))(currentLine).words(i)
						<= RAM_DATA(((i+1)*instr_size - 1) downto i*INSTR_SIZE);
				end loop;

				-- Write the DATA_OUT
				index := conv_integer(unsigned(address_stall(ROCACHE_INDEXOFFSET - 1 downto 0)));
				INT_OUT_DATA <= RAM_DATA(((index+1)*INSTR_SIZE - 1) downto index*INSTR_SIZE);

				STATE_NEXT <= STATE_COMPARE_TAGS;
				NOP_OUT <= '0';
				INT_ISSUE_RAM_READ <= '0';
			end if;

		-- Fetch instruction and print it if HIT
		when STATE_COMPARE_TAGS =>
			if(ENABLE = '1') then
				NOP_OUT <= '1';

				-- Look in the ICACHE
				for i in 0 to ROCACHE_NUMLINES - 1 loop

					-- Is it a HIT ?
					HIT := COMPARE_TAGS(
						ADDRESS(INSTR_SIZE - 1 downto ROCACHE_TAGOFFSET),
						ICACHE(GET_SET(ADDRESS))(i).tag(ROCACHE_TAGSIZE - 1 downto 0)
					);

					-- HIT!
					if (HIT = '1') then

						-- Is the entry valid?
						if(ICACHE(GET_SET(ADDRESS))(i).valid = '1') then
							lineIndex:= i;

--							report string'("STATE: ") & integer'image(conv_integer(unsigned(STATE_CURRENT))) & string'(" || ADDRESS: ") & integer'image(conv_integer(unsigned(ADDRESS))) & string'(" || HIT: ") & integer'image(conv_integer(conv_integer(HIT))) & string'(" || i: ") & integer'image(i) & string'(" || offset: ") & integer'image(GET_SET(ADDRESS)) & string'(" || count_miss = ") & integer'image(count_miss) & string'(" || test: ") & integer'image(test);

							HIT := '0'; -- Reset HIT

							-- Print out the instruction
							INT_OUT_DATA <= ICACHE(
								GET_SET(ADDRESS))(lineIndex).words(
									conv_integer(unsigned(ADDRESS(ROCACHE_INDEXOFFSET - 1 downto 0))
								)
							);

							NOP_OUT <= '0';

							-- Next state: the same
							STATE_NEXT <= STATE_COMPARE_TAGS;

							count_miss := 0;
							exit;

						-- The entry is not valid. Count as miss
						else
							count_miss := count_miss + 1;
						end if;

					-- Miss :(
					else
						count_miss := count_miss + 1;
					end if;

				end loop;

				-- Miss?
				if (count_miss = ROCACHE_NUMLINES) then
					address_stall := ADDRESS;
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

--		if(STATE_CURRENT = STATE_MISS) then
--			INT_ISSUE_RAM_READ <= '1';
--		else
--			INT_ISSUE_RAM_READ <= '0';
--		end if;

	end process;

	STALL			<= NOP_OUT;
	RAM_ISSUE		<= INT_ISSUE_RAM_READ;
	RAM_ADDRESS		<= ADDRESS(INSTR_SIZE - 1 downto 1) & '0' when INT_ISSUE_RAM_READ = '1' else (others => 'Z');
	OUT_DATA		<= INT_OUT_DATA when NOP_OUT = '0' else (others =>'Z');
end Behavioral;
