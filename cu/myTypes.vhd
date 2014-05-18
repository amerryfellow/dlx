library ieee;
use ieee.std_logic_1164.all;

package myTypes is

-- Control unit input sizes
    constant OP_CODE_SIZE : integer :=  6;                                              -- OPCODE field size
    constant FUNC_SIZE    : integer :=  11;                                             -- FUNC field size

-- R-Type instruction -> FUNC field
    constant RTYPE_ADD : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000001";    -- ADD R1,R2,R3
    constant RTYPE_SUB : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000010";    -- SUB R1,R2,R3
	constant RTYPE_AND : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000011";	-- AND R1,R2,R3
	constant RTYPE_OR  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000100";	-- OR R1,R2,R3
    constant NOP 	   : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000000";	-- NO OPERATION

-- R-Type instruction -> OPCODE field
    constant RTYPE : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "000000";          -- for ADD, SUB, AND, OR register-to-register operation

-- I-Type instruction -> OPCODE field
    constant ITYPE: std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "000001";    -- ADDI1 RS1,RD,INP1

-- I-Type instruction -> FUNC field
	constant ITYPE_ADDI1 : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000000";
	constant ITYPE_SUBI1 : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000001";
	constant ITYPE_ANDI1 : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000010";
	constant ITYPE_ORI1  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000011";
	constant ITYPE_ADDI2 : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000100";
	constant ITYPE_SUBI2 : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000101";
	constant ITYPE_ANDI2 : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000110";
	constant ITYPE_ORI2  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000111";
	constant ITYPE_MOV	 : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000001000";
	constant ITYPE_S_REG1 : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000001001";
	constant ITYPE_S_REG2 : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000001010";
	constant ITYPE_S_MEM2 : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000001011";
	constant ITYPE_L_MEM1 : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000001100";
	constant ITYPE_L_MEM2 : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000001101";



end myTypes;

