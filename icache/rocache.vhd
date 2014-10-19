library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use work.cachepkg.all;

entity ROCACHE is
	port (
		CLK						: in std_logic;
		RST						: in std_logic;  -- active high
		ENABLE					: in std_logic;
		ADDRESS					: in std_logic_vector(Instr_size - 1 downto 0);
		OUT_DATA				: out std_logic_vector(Instr_size - 1 downto 0);
		STALL					: out std_logic;
		RAM_ISSUE				: out std_logic;
		RAM_ADDRESS				: out std_logic_vector(Instr_size - 1 downto 0);
		RAM_DATA				: in std_logic_vector(2*Instr_size - 1 downto 0);
		RAM_READY				: in std_logic
	);
end ROCACHE;

architecture IC_MEM_BEHAVE of ROCACHE is
	signal ICACHE							: Cache;
	signal state_reg						: state_type;
	signal next_state						: state_type;
	signal read_issue						: std_logic;
	signal int_out_instr					: std_logic_vector(Instr_size -1 downto 0) := (others => '0');
	signal first_access						: std_logic;
	signal NOP_OUT							: std_logic;

begin
	--
	-- FSM Management
	--
	state_update: process(CLK, RST, next_state)
	begin
		if RST = '1' then
			state_reg <= STATE_FLUSH_MEM;
		elsif clk'event and clk = '1' then
			state_reg <= next_state;
		end if;
	end process;

	--
	-- The MONSTER
	--
	main: process(state_reg, ADDRESS, RAM_READY)
		variable HIT		 		: std_logic:='0';
		variable int_mem			: std_logic_vector(2*Instr_size - 1 downto 0);
		variable reference_line		: natural range 0 to 2**LFU_NUM_BIT;
		variable count_miss 		: natural range 0 to IC_num_lines;
		variable index				: natural range 0 to 2**INDEX_OFFSET - 1;
		variable test				: natural;
	begin
		case (state_reg) is
		when  STATE_FLUSH_MEM =>
--			ADDRESS <= (others => '0');
			for i in 0 to IC_Num_Of_Sets - 1 loop
				for j in 0 to IC_Num_lines - 1 loop
					ICACHE(i)(j).tag_in(IC_Tag_size downto 1) <= (others => '1');
					ICACHE(i)(j).tag_in(0) <= '0'; -- dirty bit
					ICACHE(i)(j).LFU_Count <= 0;
					NOP_OUT <= '1';
					for k in 0 to IC_Num_of_word - 1 loop
						ICACHE(i)(j).Memory_set(k)<= (others => '1');
					end loop;
					HIT := '0';
					read_issue <= '0';
					first_access <= '1';
				end loop;
			end loop;
			next_state <= STATE_COMP_TAG;

		when STATE_IDLE =>
			next_state <= STATE_MISS;

		when STATE_MISS =>
			-- I gots the data
			if RAM_READY = '1' then

				-- Identify line to hold the new data
				reference_line := line_to_evict(ADDRESS, ICACHE);

				-- Store TAG
				ICACHE(conv_offset(ADDRESS))(reference_line).tag_in <= ADDRESS(instr_size - 1 downto TAG_OFFSET)& '1';
				-- Reset LFU counter
				ICACHE(conv_offset(ADDRESS))(reference_line).LFU_COUNT <= 0;
--				ICACHE(conv_offset(ADDRESS))(reference_line).LFU_COUNT <= ICACHE(conv_offset(ADDRESS))(reference_line).LFU_COUNT +1;

				-- Fetch the line from memory data bus and write it into the cache data
				for i in 0 to IC_Num_of_word - 1 loop
					ICACHE(conv_offset(ADDRESS))(reference_line).memory_set(i)
						<= RAM_DATA(((i+1)*instr_size - 1) downto i*instr_size);
				end loop;

				-- Write the DATA_OUT
				index := conv_integer(unsigned(ADDRESS(INDEX_OFFSET - 1 downto 0)));
				int_out_instr <= RAM_DATA(((index+1)*instr_size - 1) downto index*instr_size);

				next_state <= STATE_COMP_TAG;
				nop_out <= '0';
				read_issue <= '0';
			end if;

		-- Fetch instruction and print it if HIT
		when STATE_COMP_TAG =>
			if(ENABLE = '1') then
				nop_out <= '1';

				-- Look in the ICACHE
				for i in 0 to IC_Num_lines - 1 loop
					HIT := comp_tag(
						ADDRESS(instr_size - 1 downto TAG_OFFSET),
						ICACHE(conv_offset(ADDRESS))(i).tag_in(IC_TAG_SIZE downto 1)
					);

					-- HIT!
					if (HIT = '1') then

						-- Is the entry valid?
						if(ICACHE(conv_offset(ADDRESS))(i).tag_in(0) = '1') then
							INDEX := i;

							report string'("STATE: ") & integer'image(conv_integer(unsigned(state_reg))) & string'(" || ADDRESS: ") & integer'image(conv_integer(unsigned(ADDRESS))) & string'(" || HIT: ") & integer'image(conv_integer(conv_integer(HIT))) & string'(" || i: ") & integer'image(i) & string'(" || offset: ") & integer'image(conv_offset(ADDRESS)) & string'(" || count_miss = ") & integer'image(count_miss) & string'(" || test: ") & integer'image(test);

							HIT := '0'; -- Reset HIT

							-- Print out the instruction
							int_out_instr <= ICACHE(
								conv_offset(ADDRESS))(INDEX).memory_set(
									conv_integer(unsigned(ADDRESS(INDEX_OFFSET - 1 downto 0))
								)
							);

							NOP_OUT <= '0';

							-- Next state: the same
							next_state <= STATE_COMP_TAG;

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
				if (count_miss = IC_Num_lines) then
					read_issue <= '1';
					next_state <= STATE_MISS;
				end if;

				-- Reset the counter
				count_miss := 0;
			else
				next_state <= STATE_COMP_TAG;
			end if;
		when OTHERS => null;
		end case;

--		if(state_reg = STATE_MISS) then
--			read_issue <= '1';
--		else
--			read_issue <= '0';
--		end if;

	end process;

	STALL			<= nop_out;
	RAM_ISSUE		<= read_issue;
	RAM_ADDRESS		<= ADDRESS(Instr_size - 1 downto 1) & '0' when read_issue = '1' else (others => 'Z');
	OUT_DATA		<= int_out_instr when NOP_OUT = '0' else (others =>'Z');
end IC_MEM_BEHAVE;
