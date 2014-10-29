library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package cu is
	-- Control unit input sizes
	constant OPCODE_SIZE	: integer := 6;			-- OPCODE field size
	constant FUNC_SIZE		: integer := 11;		-- FUNC field size

subtype OPCODE_TYPE is std_logic_vector(OPCODE_SIZE - 1 downto 0);
	-- I-Type instructions
	constant ITYPE_ADD	: OPCODE_TYPE	:= "001000";
	constant ITYPE_AND	: OPCODE_TYPE	:= "001100";
	constant ITYPE_OR	: OPCODE_TYPE	:= "001101";
	constant ITYPE_SUB	: OPCODE_TYPE	:= "001010";
	constant ITYPE_XOR	: OPCODE_TYPE	:= "001110";
	constant ITYPE_SGE	: OPCODE_TYPE	:= "011101";
	constant ITYPE_SLE	: OPCODE_TYPE	:= "011100";
	constant ITYPE_SLL	: OPCODE_TYPE	:= "010100";
	constant ITYPE_SRL	: OPCODE_TYPE	:= "010110";
	constant ITYPE_SNE	: OPCODE_TYPE	:= "011001";
	constant ITYPE_SGT	: OPCODE_TYPE	:= "011011";

	constant NOP		: OPCODE_TYPE	:= "010101";

		-- Jump [ OPCODE(6) - PCOFFSET(26) ]
	constant JTYPE_J		: OPCODE_TYPE	:= "000010";
	constant JTYPE_JAL		: OPCODE_TYPE	:= "000011";

		-- Branch [ OPCODE(6) - REG(5) - PCOFFSET(21) ]
	constant BTYPE_BEQZ		: OPCODE_TYPE	:= "000100";
	constant BTYPE_BNEZ		: OPCODE_TYPE	:= "000101";

		-- Memory [ OPCODE(6) - RDISPLACEMENT(5) - REG(5) - DISPLACEMENT(16) ]
	constant MTYPE_LW		: OPCODE_TYPE	:= "100011";
	constant MTYPE_SW		: OPCODE_TYPE	:= "101011";

	-- R-Type instruction -> OPCODE field
	constant RTYPE : OPCODE_TYPE :=  "000000";

subtype FUNC_TYPE is std_logic_vector(FUNC_SIZE - 1 downto 0);
	-- R-Type instruction -> FUNC field
	constant RTYPE_ADD	: FUNC_TYPE		:= "00000100000";
	constant RTYPE_AND	: FUNC_TYPE		:= "00000100100";
	constant RTYPE_OR	: FUNC_TYPE		:= "00000100101";
	constant RTYPE_SUB	: FUNC_TYPE		:= "00000100010";
	constant RTYPE_XOR	: FUNC_TYPE		:= "00000100110";
	constant RTYPE_SGE	: FUNC_TYPE		:= "00000101101";
	constant RTYPE_SLE	: FUNC_TYPE		:= "00000101100";
	constant RTYPE_SLL	: FUNC_TYPE		:= "00000000100";
	constant RTYPE_SRL	: FUNC_TYPE		:= "00000000110";
	constant RTYPE_SNE	: FUNC_TYPE		:= "00000101001";
	constant RTYPE_SGT	: FUNC_TYPE		:= "00000101011";
	constant RTYPE_NOP	: FUNC_TYPE		:= "00000000000";

end cu;
