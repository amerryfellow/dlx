library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use ieee.std_logic_misc.all;
package cachepkg is
constant IC_Num_Of_Ways          	: natural := 2; 
constant	IC_Num_Of_Sets          	: natural := 4;  --Depth of ICache
constant IC_Num_of_word					: natural := 2; 
constant	Instr_size 						: natural := 32;
constant	IC_SET_in_bits 				: natural := 2;  -- number of bits for offset  log2(IC_Num_Of_Ways)
constant	IC_Num_lines           		: natural := IC_Num_Of_Ways;
constant	IC_Index_in_Bits        	: natural := 1;  
constant	IC_Tag_Size             	: natural := Instr_Size-IC_Index_in_Bits-IC_SET_in_bits;
constant TAG_OFFSET						: natural := Instr_Size - IC_Tag_Size;
constant SET_OFFSET						: natural := TAG_OFFSET - IC_SET_in_bits;
constant INDEX_OFFSET					: natural := IC_Index_in_Bits;
constant	LFU_NUM_BIT						: natural := 8;

subtype LINES is natural range 0 to IC_Num_lines - 1;
subtype SETS is natural range 0 to 2**IC_SET_in_bits - 1;
subtype INDEX is natural range 0 to 2**IC_Index_in_bits - 1;

type Instr_words is array (INDEX) of std_logic_vector(Instr_size - 1 downto 0);
type icache_record is
	record
		tag_in		: std_logic_vector(IC_Tag_size downto 0); -- the last one is the valid bit 
		Memory_set	: Instr_words;
		LFU_Count 	: natural range 0 to 2**LFU_NUM_BIT;
end record;
type icache_line is array (LINES) of icache_record;
type cache is array (SETS) of icache_line;
subtype state_type is std_logic_vector(3 downto 0);
constant STATE_FLUSH_MEM			: state_type := "0000";
constant STATE_MISS 					: state_type := "0001";
constant STATE_COMP_TAG				: state_type := "0010";
constant STATE_IDLE					: state_type := "0011";
constant STATE_OUT					: state_type := "0100";
constant STATE_MISS_1				: state_type := "0101";
constant STATE_MISS_2				: state_type := "0110";
constant STATE_MISS_3				: state_type := "0111";
constant STATE_DATA_READY			: state_type := "1000";

function comp_tag(x:std_logic_vector(IC_Tag_Size-1 downto 0 ); y:std_logic_vector(IC_Tag_Size-1 downto 0 )) return std_logic;
function conv_offset(x:std_logic_vector(Instr_size - 1 downto 0)) return integer;
function line_to_evict(tmp_pc_addr:std_logic_vector(Instr_size - 1 downto 0); ICACHE: cache) return natural;
end cachepkg;
package body cachepkg is

function comp_tag(x:std_logic_vector(IC_Tag_Size-1 downto 0); y:std_logic_vector(IC_Tag_Size-1 downto 0)) return std_logic is
	begin
		return and_reduce(x xnor y);
end comp_tag;

function conv_offset(x:std_logic_vector(Instr_size - 1 downto 0)) return integer is
	variable ret	: integer :=0;
	variable y		: std_logic_vector(TAG_OFFSET-1 downto SET_OFFSET);
		begin
			y := x(TAG_OFFSET-1 downto SET_OFFSET);
			ret := conv_integer(unsigned (y));
			return ret;
end conv_offset;	

function line_to_evict(tmp_pc_addr:std_logic_vector(Instr_size - 1 downto 0); ICACHE: cache) return natural is
	variable count			: natural range 0 to 2**LFU_NUM_BIT;
	variable min_found	: std_logic;
	variable i				: natural :=0; 
	variable to_evict		: natural range 0 to 2**LFU_NUM_BIT;
		begin
			count := ICACHE(conv_offset(tmp_pc_addr))(i).LFU_Count;
			to_evict := i;
			while i < (IC_Num_lines - 2) loop
				if(ICACHE(conv_offset(tmp_pc_addr))(i+1).LFU_Count < count) then
					count := ICACHE(conv_offset(tmp_pc_addr))(i+1).LFU_Count;
					to_evict := i + 1;
				end if;	
			i := i + 1 ;
			end loop;
		
		return to_evict;
end line_to_evict;			
		
		 

end package body;