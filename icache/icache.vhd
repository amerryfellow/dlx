library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use work.cachepkg.all;

entity IC_MEM is
	port (
			clk						: in std_logic;
			Reset					: in std_logic;  -- active high
			pc_addr					: in std_logic_vector(Instr_size - 1 downto 0);
			instr_from_mem			: in std_logic_vector(2*Instr_size - 1 downto 0);
			iram_ready				: in std_logic;
--			we_instr				: in std_logic;
			enable					: in std_logic;
--			HIT						: out std_logic;
			stall_pipe				: out std_logic;
			read_mem				: out std_logic;
			addr_to_mem 			: out std_logic_vector(Instr_size - 1 downto 0);
			out_instr				: out std_logic_vector(Instr_size - 1 downto 0)
		);
end IC_MEM;

architecture IC_MEM_BEHAVE of IC_MEM is
signal ICACHE							: Cache;
signal state_reg						: state_type;
signal next_state						: state_type;
signal read_issue						: std_logic;
--signal HIT 								: std_logic;
signal int_out_instr					: std_logic_vector(Instr_size -1 downto 0) := (others => '0');
signal first_access,NOP_OUT		: std_logic;

begin
	--
	-- FSM
	--
	state_update: process(clk, reset, next_state)
	begin
		if Reset = '1' then
			state_reg <= STATE_FLUSH_MEM;
		elsif clk'event and clk = '1' then
			state_reg <= next_state;
		end if;
	end process;

	main: process(state_reg, pc_addr, iram_ready)
			variable HIT		 		: std_logic:='0';
			variable int_mem			: std_logic_vector(2*Instr_size - 1 downto 0);
			variable reference_line		: natural range 0 to 2**LFU_NUM_BIT;
			variable count_miss 		: natural range 0 to IC_num_lines;
			variable index				: natural range 0 to 2**INDEX_OFFSET - 1;
			variable test				: natural;
			begin
				case (state_reg) is
				when  STATE_FLUSH_MEM =>
--					PC_ADDR <= (others => '0');
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
					if iram_ready = '1' then
						reference_line := line_to_evict(PC_ADDR,ICACHE);
						ICACHE(conv_offset(PC_ADDR))(reference_line).tag_in <= PC_ADDR(instr_size - 1 downto TAG_OFFSET)& '1';
						ICACHE(conv_offset(PC_ADDR))(reference_line).LFU_COUNT
																	<= ICACHE(conv_offset(PC_ADDR))(reference_line).LFU_COUNT +1;
						for i in 0 to IC_Num_of_word - 1 loop
							ICACHE(conv_offset(PC_ADDR))(reference_line).memory_set(i)
								<= instr_from_mem (((i+1)*instr_size - 1) downto i*instr_size);
						end loop;
						index := conv_integer(unsigned(PC_ADDR(INDEX_OFFSET - 1 downto 0)));
						int_out_instr <= instr_from_mem (((index+1)*instr_size - 1) downto index*instr_size);
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
								PC_ADDR(instr_size - 1 downto TAG_OFFSET),
								ICACHE(conv_offset(PC_ADDR))(i).tag_in(IC_TAG_SIZE downto 1)
							);

							-- HIT!
							if (HIT = '1') then

								-- Is the entry valid?
								if(ICACHE(conv_offset(PC_ADDR))(i).tag_in(0) = '1') then
									INDEX := i;

									report string'("STATE: ") & integer'image(conv_integer(unsigned(state_reg))) & string'(" || PC: ") & integer'image(conv_integer(unsigned(PC_ADDR))) & string'(" || HIT: ") & integer'image(conv_integer(conv_integer(HIT))) & string'(" || i: ") & integer'image(i) & string'(" || offset: ") & integer'image(conv_offset(PC_ADDR)) & string'(" || count_miss = ") & integer'image(count_miss) & string'(" || test: ") & integer'image(test);	

									HIT := '0'; -- Reset HIT

									-- Print out the instruction
									int_out_instr <= ICACHE(
										conv_offset(PC_ADDR))(INDEX).memory_set(
											conv_integer(unsigned(PC_ADDR(INDEX_OFFSET - 1 downto 0))
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

	--			if(state_reg = STATE_MISS) then
	--				read_issue <= '1';
	--			else
	--				read_issue <= '0';
	--			end if;

			end process;
			stall_pipe <= nop_out;

			read_mem <= read_issue;
			addr_to_mem <= PC_ADDR(Instr_size - 1 downto 1) & '0' when read_issue = '1' else (others => 'Z');
		out_instr <=	int_out_instr when NOP_OUT = '0' else
--							instr_from_mem (((conv_integer(unsigned(PC_ADDR(INDEX_OFFSET - 1 downto 0)))+1)*instr_size - 1) downto conv_integer(unsigned(PC_ADDR(INDEX_OFFSET - 1 downto 0)))*instr_size) when IRAM_READY = '1' else
							(others =>'Z');
end IC_MEM_BEHAVE;
