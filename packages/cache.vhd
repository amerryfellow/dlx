library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use ieee.std_logic_misc.all;
package cachepkg is
--constant IC_Num_Of_Ways          	: natural := 2;
constant ROCACHE_WAYS				: natural := 2;
--constant	IC_Num_Of_Sets          	: natural := 4;  --Depth of ICache
constant ROCACHE_NUMSETS				: natural := 4;  --Depth of ICache
--constant IC_Num_of_word					: natural := 2; 
constant ROCACHE_WORDS			: natural := 2; 
--constant	Instr_size 						: natural := 32;
constant INSTR_SIZE 				: natural := 32;
--constant	IC_SET_in_bits 				: natural := 2;  -- number of bits for offset  log2(IC_Num_Of_Ways)
constant ROCACHE_SETINDEXSIZE			: natural := 2;  -- number of bits for offset  log2(IC_Num_Of_Ways)
--constant	IC_Num_lines           		: natural := IC_Num_Of_Ways;
constant ROCACHE_NUMLINES				: natural := ROCACHE_WAYS;
--constant	IC_Index_in_Bits        	: natural := 1;
constant ROCACHE_INDEXSIZE			: natural := 1;
--constant	IC_Tag_Size             	: natural := Instr_Size-IC_Index_in_Bits-IC_SET_in_bits;
constant ROCACHE_TAGSIZE			: natural := INSTR_SIZE - ROCACHE_INDEXSIZE - ROCACHE_SETINDEXSIZE;
--constant TAG_OFFSET						: natural := Instr_Size - IC_Tag_Size;
constant ROCACHE_TAGOFFSET			: natural := INSTR_SIZE - ROCACHE_TAGSIZE;
--constant SET_OFFSET						: natural := TAG_OFFSET - IC_SET_in_bits;
constant ROCACHE_SETOFFSET			: natural := ROCACHE_TAGOFFSET - ROCACHE_SETINDEXSIZE;
--constant INDEX_OFFSET					: natural := IC_Index_in_Bits;
constant ROCACHE_INDEXOFFSET		: natural := ROCACHE_INDEXSIZE;
--constant	LFU_NUM_BIT						: natural := 8;
constant ROCACHE_COUNTERSIZE		: natural := 8;

subtype ROCACHE_LINES is natural range 0 to ROCACHE_NUMLINES - 1;
subtype ROCACHE_SETS is natural range 0 to 2**ROCACHE_SETINDEXSIZE - 1;
subtype ROCACHE_INDEX is natural range 0 to 2**ROCACHE_INDEXSIZE - 1;

type INSTR_WORDS is array (ROCACHE_INDEX) of std_logic_vector(INSTR_SIZE - 1 downto 0);

type ROCACHE_RECORD is
	record
--		tag_in		: std_logic_vector(IC_Tag_size downto 0); -- the last one is the valid bit 
		tag : std_logic_vector(ROCACHE_TAGSIZE-1 downto 0);
--		Memory_set	: Instr_words;
		words : INSTR_WORDS;
--		LFU_Count 	: natural range 0 to 2**LFU_NUM_BIT;
		counter : natural range 0 to 2**ROCACHE_COUNTERSIZE;

		valid : std_logic;
end record;

type ROCACHE_LINE is array (ROCACHE_LINES) of ROCACHE_RECORD;
type ROCACHE_TYPE is array (ROCACHE_SETS) of ROCACHE_LINE;

subtype state_type is std_logic_vector(3 downto 0);
constant STATE_FLUSH_MEM			: state_type := "0000";
constant STATE_MISS 					: state_type := "0001";
constant STATE_COMPARE_TAGS				: state_type := "0010";
constant STATE_IDLE					: state_type := "0011";
constant STATE_OUT					: state_type := "0100";
constant STATE_MISS_1				: state_type := "0101";
constant STATE_MISS_2				: state_type := "0110";
constant STATE_MISS_3				: state_type := "0111";
constant STATE_DATA_READY			: state_type := "1000";

function COMPARE_TAGS(
	x : std_logic_vector(ROCACHE_TAGSIZE - 1 downto 0 );
	y : std_logic_vector(ROCACHE_TAGSIZE - 1 downto 0 )
) return std_logic;

function GET_OFFSET(
	x : std_logic_vector(INSTR_SIZE - 1 downto 0)
) return integer;

function GET_LFU_INDEX(
	tmp_pc_addr : std_logic_vector(INSTR_SIZE - 1 downto 0);
	cache: ROCACHE_TYPE
) return natural;

end cachepkg;

package body cachepkg is
	function COMPARE_TAGS(
			x : std_logic_vector(ROCACHE_TAGSIZE-1 downto 0);
			y : std_logic_vector(ROCACHE_TAGSIZE-1 downto 0)
		) return std_logic is

	begin
		return and_reduce(x xnor y);
end COMPARE_TAGS;

function GET_OFFSET(
		x : std_logic_vector(INSTR_SIZE - 1 downto 0)
	) return integer is

	variable ret	: integer :=0;
	variable y		: std_logic_vector(ROCACHE_TAGOFFSET-1 downto ROCACHE_SETOFFSET);

	begin
		y		:= x(ROCACHE_TAGOFFSET-1 downto ROCACHE_SETOFFSET);
		ret		:= conv_integer(unsigned (y));
		return ret;
end GET_OFFSET;

function GET_LFU_INDEX(
		tmp_pc_addr : std_logic_vector(INSTR_SIZE - 1 downto 0);
		cache: ROCACHE_TYPE
	) return natural is

	variable count			: natural range 0 to 2**ROCACHE_COUNTERSIZE;
	variable min_found		: std_logic;
	variable i				: natural :=0;
	variable to_evict		: natural range 0 to 2**ROCACHE_COUNTERSIZE;

	begin
		count := cache( GET_OFFSET(tmp_pc_addr) )(i).counter;
		to_evict := i;

		-- Iterate
		while i < (ROCACHE_NUMLINES - 2) loop
			-- Check counter value
			if(cache( GET_OFFSET(tmp_pc_addr) )(i+1).counter < count) then
				-- New least frequently used -> save its index and counter value
				count := cache( GET_OFFSET(tmp_pc_addr) )(i+1).counter;
				to_evict := i + 1;
			end if;

		i := i + 1 ;
		end loop;

	return to_evict;
end GET_LFU_INDEX;

end package body;
