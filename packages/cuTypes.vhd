library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package cu is
	-- Control unit input sizes
	constant OPCODE_SIZE	: integer := 6;			-- OPCODE field size
	constant FUNC_SIZE		: integer := 11;		-- FUNC field size

subtype OPCODE_TYPE is std_logic_vector(OPCODE_SIZE - 1 downto 0);
	-- I-Type instructions
	constant ITYPE_ADD	: OPCODE_TYPE	:= to_stdlogicvector(x"08")(5 downto 0);
	constant ITYPE_AND	: OPCODE_TYPE	:= to_stdlogicvector(x"0c")(5 downto 0);
	constant ITYPE_OR	: OPCODE_TYPE	:= to_stdlogicvector(x"0d")(5 downto 0);
	constant ITYPE_SUB	: OPCODE_TYPE	:= to_stdlogicvector(x"0a")(5 downto 0);
	constant ITYPE_XOR	: OPCODE_TYPE	:= to_stdlogicvector(x"0e")(5 downto 0);
	constant ITYPE_SGE	: OPCODE_TYPE	:= to_stdlogicvector(x"1d")(5 downto 0);
	constant ITYPE_SLE	: OPCODE_TYPE	:= to_stdlogicvector(x"1c")(5 downto 0);
	constant ITYPE_SLL	: OPCODE_TYPE	:= to_stdlogicvector(x"14")(5 downto 0);
	constant ITYPE_SRL	: OPCODE_TYPE	:= to_stdlogicvector(x"16")(5 downto 0);
	constant ITYPE_SNE	: OPCODE_TYPE	:= to_stdlogicvector(x"19")(5 downto 0);
	constant ITYPE_SGT	: OPCODE_TYPE	:= to_stdlogicvector(x"1b")(5 downto 0);

	constant MULT		: OPCODE_TYPE	:= to_stdlogicvector(x"01")(5 downto 0);

		-- Jump [ OPCODE(6) - PCOFFSET(26) ]
	constant JTYPE_J		: OPCODE_TYPE	:= to_stdlogicvector(x"02")(5 downto 0);
	constant JTYPE_JAL		: OPCODE_TYPE	:= to_stdlogicvector(x"03")(5 downto 0);

		-- Branch [ OPCODE(6) - REG(5) - PCOFFSET(21) ]
	constant BTYPE_BEQZ		: OPCODE_TYPE	:= to_stdlogicvector(x"04")(5 downto 0);
	constant BTYPE_BNEZ		: OPCODE_TYPE	:= to_stdlogicvector(x"05")(5 downto 0);

		-- Memory [ OPCODE(6) - RDISPLACEMENT(5) - REG(5) - DISPLACEMENT(16) ]
	constant MTYPE_LW		: OPCODE_TYPE	:= to_stdlogicvector(x"23")(5 downto 0);
	constant MTYPE_SW		: OPCODE_TYPE	:= to_stdlogicvector(x"2b")(5 downto 0);

	-- R-Type instruction -> OPCODE field
	constant RTYPE : OPCODE_TYPE :=  "000000";

subtype FUNC_TYPE is std_logic_vector(FUNC_SIZE - 1 downto 0);
	-- R-Type instruction -> FUNC field
	constant RTYPE_ADD	: FUNC_TYPE		:= "000" & to_stdlogicvector(x"20");
	constant RTYPE_AND	: FUNC_TYPE		:= "000" & to_stdlogicvector(x"24");
	constant RTYPE_OR	: FUNC_TYPE		:= "000" & to_stdlogicvector(x"25");
	constant RTYPE_SUB	: FUNC_TYPE		:= "000" & to_stdlogicvector(x"22");
	constant RTYPE_XOR	: FUNC_TYPE		:= "000" & to_stdlogicvector(x"26");
	constant RTYPE_SGE	: FUNC_TYPE		:= "000" & to_stdlogicvector(x"2d");
	constant RTYPE_SLE	: FUNC_TYPE		:= "000" & to_stdlogicvector(x"2c");
	constant RTYPE_SLL	: FUNC_TYPE		:= "000" & to_stdlogicvector(x"04");
	constant RTYPE_SRL	: FUNC_TYPE		:= "000" & to_stdlogicvector(x"06");
	constant RTYPE_SNE	: FUNC_TYPE		:= "000" & to_stdlogicvector(x"29");
	constant RTYPE_SGT	: FUNC_TYPE		:= "000" & to_stdlogicvector(x"2b");
	constant NOP		: FUNC_TYPE		:= "000" & to_stdlogicvector(x"00");

end cu;
