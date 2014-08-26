library ieee;
use ieee.std_logic_1164.all;

package cu is
	-- Control unit input sizes
	constant OPCODE_SIZE	: integer := 6;			-- OPCODE field size
	constant FUNC_SIZE		: integer := 11;		-- FUNC field size

	-- R-Type instruction -> OPCODE field
	constant RTYPE : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "000000";

	-- R-Type instruction -> FUNC field
	constant RTYPE_ADD	: std_logic_vector(FUNC_SIZE - 1 downto 0)		:= std_logic_vector(to_unsigned(0x20, FUNC_SIZE));
	constant RTYPE_AND	: std_logic_vector(FUNC_SIZE - 1 downto 0)		:= std_logic_vector(to_unsigned(0x24, FUNC_SIZE));
	constant RTYPE_OR	: std_logic_vector(FUNC_SIZE - 1 downto 0)		:= std_logic_vector(to_unsigned(0x25, FUNC_SIZE));
	constant RTYPE_SUB	: std_logic_vector(FUNC_SIZE - 1 downto 0)		:= std_logic_vector(to_unsigned(0x22, FUNC_SIZE));
	constant RTYPE_XOR	: std_logic_vector(FUNC_SIZE - 1 downto 0)		:= std_logic_vector(to_unsigned(0x26, FUNC_SIZE));
	constant RTYPE_SGE	: std_logic_vector(FUNC_SIZE - 1 downto 0)		:= std_logic_vector(to_unsigned(0x2d, FUNC_SIZE));
	constant RTYPE_SLE	: std_logic_vector(FUNC_SIZE - 1 downto 0)		:= std_logic_vector(to_unsigned(0x2c, FUNC_SIZE));
	constant RTYPE_SLL	: std_logic_vector(FUNC_SIZE - 1 downto 0)		:= std_logic_vector(to_unsigned(0x04, FUNC_SIZE));
	constant RTYPE_SRL	: std_logic_vector(FUNC_SIZE - 1 downto 0)		:= std_logic_vector(to_unsigned(0x06, FUNC_SIZE));
	constant RTYPE_SNE	: std_logic_vector(FUNC_SIZE - 1 downto 0)		:= std_logic_vector(to_unsigned(0x29, FUNC_SIZE));
	constant RTYPE_SGT	: std_logic_vector(FUNC_SIZE - 1 downto 0)		:= std_logic_vector(to_unsigned(0x2b, FUNC_SIZE));

	-- I-Type instructions
	constant ITYPE_ADD	: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x08, OPCODE_SIZE));
	constant ITYPE_AND	: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x0c, OPCODE_SIZE));
	constant ITYPE_OR	: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x0d, OPCODE_SIZE));
	constant ITYPE_SUB	: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x0a, OPCODE_SIZE));
	constant ITYPE_XOR	: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x0e, OPCODE_SIZE));
	constant ITYPE_SGE	: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x1d, OPCODE_SIZE));
	constant ITYPE_SLE	: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x1c, OPCODE_SIZE));
	constant ITYPE_SLL	: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x14, OPCODE_SIZE));
	constant ITYPE_SRL	: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x16, OPCODE_SIZE));
	constant ITYPE_SNE	: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x19, OPCODE_SIZE));
	constant ITYPE_SGT	: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x1b, OPCODE_SIZE));

	constant MULT		: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x01, OPCODE_SIZE));

		-- Jump [ OPCODE(6) - PCOFFSET(26) ]
	constant JTYPE_J		: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x02, OPCODE_SIZE));
	constant JTYPE_JAL		: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x03, OPCODE_SIZE));

		-- Branch [ OPCODE(6) - REG(5) - PCOFFSET(21) ]
	constant BTYPE_BEQZ		: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x04, OPCODE_SIZE));
	constant BTYPE_BNEZ		: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x05, OPCODE_SIZE));

		-- Memory [ OPCODE(6) - RDISPLACEMENT(5) - REG(5) - DISPLACEMENT(16) ]
	constant MTYPE_LW		: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x23, OPCODE_SIZE));
	constant MTYPE_SW		: std_logic_vector(OPCODE_SIZE - 1 downto 0)	:= std_logic_vector(to_unsigned(0x2b, OPCODE_SIZE));
end cuTypes;
