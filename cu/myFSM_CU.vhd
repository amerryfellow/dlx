library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use work.myTypes.all;

entity CU_FSM is
	port (
		-- FIRST PIPE STAGE OUTPUTS
		EN1    : out std_logic;               -- enables the register file and the pipeline registers
		RF1    : out std_logic;               -- enables the read port 1 of the register file
		RF2    : out std_logic;               -- enables the read port 2 of the register file
		WF1    : out std_logic;               -- enables the write port of the register file

		-- SECOND PIPE STAGE OUTPUTS
		EN2    : out std_logic;               -- enables the pipe registers
		S1     : out std_logic;               -- input selection of the first multiplexer
		S2     : out std_logic;               -- input selection of the second multiplexer
		ALU1   : out std_logic;               -- alu control bit
		ALU2   : out std_logic;               -- alu control bit

		-- THIRD PIPE STAGE OUTPUTS
		EN3    : out std_logic;               -- enables the memory and the pipeline registers
		RM     : out std_logic;               -- enables the read-out of the memory
		WM     : out std_logic;               -- enables the write-in of the memory
		S3     : out std_logic;               -- input selection of the multiplexer

		-- INPUTS
		OPCODE : in  std_logic_vector(OP_CODE_SIZE - 1 downto 0);
		FUNC   : in  std_logic_vector(FUNC_SIZE - 1 downto 0);
		Clk : in std_logic;
		Rst : in std_logic					  -- Active Low
	);
end CU_FSM;

---------------------------------------------

architecture behavioral of CU_FSM is
	type TYPE_STATE is (RESET, FD, EXE_RTYPE_ADD, EXE_RTYPE_SUB, EXE_RTYPE_AND, EXE_RTYPE_OR, EXE_RTYPE_NOP, EXE_ITYPE_ADDI1, EXE_ITYPE_SUBI1, EXE_ITYPE_ANDI1, EXE_ITYPE_ORI1, EXE_ITYPE_ADDI2, EXE_ITYPE_SUBI2, EXE_ITYPE_ANDI2, EXE_ITYPE_ORI2, EXE_ITYPE_MOV, EXE_ITYPE_S_REG1, EXE_ITYPE_S_REG2, EXE_ITYPE_S_MEM2, EXE_ITYPE_L_MEM1, EXE_ITYPE_L_MEM2, MEMWB_RTYPE_ADD, MEMWB_RTYPE_SUB, MEMWB_RTYPE_AND, MEMWB_RTYPE_OR, MEMWB_RTYPE_NOP, MEMWB_ITYPE_ADDI1, MEMWB_ITYPE_SUBI1, MEMWB_ITYPE_ANDI1, MEMWB_ITYPE_ORI1, MEMWB_ITYPE_ADDI2, MEMWB_ITYPE_SUBI2, MEMWB_ITYPE_ANDI2, MEMWB_ITYPE_ORI2, MEMWB_ITYPE_MOV, MEMWB_ITYPE_S_REG1, MEMWB_ITYPE_S_REG2, MEMWB_ITYPE_S_MEM2, MEMWB_ITYPE_L_MEM1, MEMWB_ITYPE_L_MEM2);

	signal CURRENT_STATE : TYPE_STATE;
	signal NEXT_STATE : TYPE_STATE;

begin

	--
	-- State updater
	--

 	P_FSM : process(Clk, Rst)
	begin
		if Rst='0' then
			CURRENT_STATE <= RESET;
		elsif (Clk'event and Clk = '1') then
			CURRENT_STATE <= NEXT_STATE;
		end if;
	end process P_FSM;

	--
	-- Next state updater
	--
	P_NEXT_STATE : process(CURRENT_STATE, OPCODE, FUNC)
	begin
		NEXT_STATE <= CURRENT_STATE;

		case CURRENT_STATE is
			when RESET => NEXT_STATE <= FD;

			when FD =>
				case (OPCODE) is
					when RTYPE =>
						case (FUNC) is
							when RTYPE_ADD	=> NEXT_STATE <= EXE_RTYPE_ADD;
							when RTYPE_SUB	=> NEXT_STATE <= EXE_RTYPE_SUB;
							when RTYPE_AND	=> NEXT_STATE <= EXE_RTYPE_AND;
							when RTYPE_OR	=> NEXT_STATE <= EXE_RTYPE_OR;
							when NOP		=> NEXT_STATE <= EXE_RTYPE_NOP;
							when others		=> report "I don't know how to handle this func!"; null;
						end case;
	
					when ITYPE =>
						case (FUNC) is
							when ITYPE_ADDI1	=> NEXT_STATE <= EXE_ITYPE_ADDI1;
							when ITYPE_SUBI1	=> NEXT_STATE <= EXE_ITYPE_SUBI1;
							when ITYPE_ANDI1	=> NEXT_STATE <= EXE_ITYPE_ANDI1;
							when ITYPE_ORI1		=> NEXT_STATE <= EXE_ITYPE_ORI1;
							when ITYPE_ADDI2	=> NEXT_STATE <= EXE_ITYPE_ADDI2;
							when ITYPE_SUBI2	=> NEXT_STATE <= EXE_ITYPE_SUBI2;
							when ITYPE_ANDI2	=> NEXT_STATE <= EXE_ITYPE_ANDI2;
							when ITYPE_ORI2		=> NEXT_STATE <= EXE_ITYPE_ORI2;
							when ITYPE_MOV		=> NEXT_STATE <= EXE_ITYPE_MOV;
							when ITYPE_S_REG1	=> NEXT_STATE <= EXE_ITYPE_S_REG1;
							when ITYPE_S_REG2	=> NEXT_STATE <= EXE_ITYPE_S_REG2;
							when ITYPE_S_MEM2	=> NEXT_STATE <= EXE_ITYPE_S_MEM2;
							when ITYPE_L_MEM1	=> NEXT_STATE <= EXE_ITYPE_L_MEM1;
							when ITYPE_L_MEM2	=> NEXT_STATE <= EXE_ITYPE_L_MEM2;
	
							when others		=> report "I don't know how to handle this func!"; null;
						end case;
	
					when others =>
						report "I don't know how to handle this opcode!";
						null;
				end case;

			-- EXECUTION

			when EXE_RTYPE_ADD		=> NEXT_STATE <= MEMWB_RTYPE_ADD;
			when EXE_RTYPE_SUB		=> NEXT_STATE <= MEMWB_RTYPE_SUB;
			when EXE_RTYPE_AND		=> NEXT_STATE <= MEMWB_RTYPE_AND;
			when EXE_RTYPE_OR		=> NEXT_STATE <= MEMWB_RTYPE_OR;
			when EXE_RTYPE_NOP		=> NEXT_STATE <= MEMWB_RTYPE_NOP;
			when EXE_ITYPE_ADDI1	=> NEXT_STATE <= MEMWB_ITYPE_ADDI1;
			when EXE_ITYPE_SUBI1	=> NEXT_STATE <= MEMWB_ITYPE_SUBI1;
			when EXE_ITYPE_ANDI1	=> NEXT_STATE <= MEMWB_ITYPE_ANDI1;
			when EXE_ITYPE_ORI1		=> NEXT_STATE <= MEMWB_ITYPE_ORI1;
			when EXE_ITYPE_ADDI2	=> NEXT_STATE <= MEMWB_ITYPE_ADDI2;
			when EXE_ITYPE_SUBI2	=> NEXT_STATE <= MEMWB_ITYPE_SUBI2;
			when EXE_ITYPE_ANDI2	=> NEXT_STATE <= MEMWB_ITYPE_ANDI2;
			when EXE_ITYPE_ORI2		=> NEXT_STATE <= MEMWB_ITYPE_ORI2;
			when EXE_ITYPE_MOV		=> NEXT_STATE <= MEMWB_ITYPE_MOV;
			when EXE_ITYPE_S_REG1	=> NEXT_STATE <= MEMWB_ITYPE_S_REG1;
			when EXE_ITYPE_S_REG2	=> NEXT_STATE <= MEMWB_ITYPE_S_REG2;
			when EXE_ITYPE_S_MEM2	=> NEXT_STATE <= MEMWB_ITYPE_S_MEM2;
			when EXE_ITYPE_L_MEM1	=> NEXT_STATE <= MEMWB_ITYPE_L_MEM1;
			when EXE_ITYPE_L_MEM2	=> NEXT_STATE <= MEMWB_ITYPE_L_MEM2;

			-- MEMORY / WRITE BACK
			when others				=> NEXT_STATE <= FD;
		end case;
	end process P_NEXT_STATE;

	--
	-- Output driver
	--
	P_OUTPUTS: process(CURRENT_STATE)
	begin
		--O <= '0';
EN1 <= '0'; RF1 <= '0'; RF2 <= '0'; EN2 <= '0'; S1 <= '0'; S2 <= '0'; ALU1 <= '0'; ALU2 <= '0'; EN3 <= '0'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '0';

		case CURRENT_STATE is
			when FD =>
				case (OPCODE) is
					when RTYPE =>
						case (FUNC) is
							when RTYPE_ADD	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '1';
							when RTYPE_SUB	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '1';
							when RTYPE_AND	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '1';
							when RTYPE_OR	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '1';
							when NOP		=> EN1 <= '0'; RF1 <= '0'; RF2 <= '0';
							when others		=> report "I don't know how to handle this func!"; null;
						end case;
	
					when ITYPE =>
						case (FUNC) is
							when ITYPE_ADDI1	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '0';
							when ITYPE_SUBI1	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '0';
							when ITYPE_ANDI1	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '0';
							when ITYPE_ORI1		=> EN1 <= '1'; RF1 <= '1'; RF2 <= '0';
							when ITYPE_ADDI2	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '0';
							when ITYPE_SUBI2	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '0';
							when ITYPE_ANDI2	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '0';
							when ITYPE_ORI2		=> EN1 <= '1'; RF1 <= '1'; RF2 <= '0';
							when ITYPE_MOV		=> EN1 <= '1'; RF1 <= '1'; RF2 <= '0';
							when ITYPE_S_REG1	=> EN1 <= '1'; RF1 <= '0'; RF2 <= '0';
							when ITYPE_S_REG2	=> EN1 <= '1'; RF1 <= '0'; RF2 <= '0';
							when ITYPE_S_MEM2	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '1';
							when ITYPE_L_MEM1	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '0';
							when ITYPE_L_MEM2	=> EN1 <= '1'; RF1 <= '1'; RF2 <= '0';
	
							when others		=> report "I don't know how to handle this func!"; null;
						end case;
	
					when others =>
						report "I don't know how to handle this opcode!";
						null;
				end case;

			-- EXECUTION

			when EXE_RTYPE_ADD		=> EN2 <= '1'; S1 <= '0'; S2 <= '1'; ALU1 <= '0'; ALU2 <= '0';
			when EXE_RTYPE_SUB		=> EN2 <= '1'; S1 <= '0'; S2 <= '1'; ALU1 <= '0'; ALU2 <= '1';
			when EXE_RTYPE_AND		=> EN2 <= '1'; S1 <= '0'; S2 <= '1'; ALU1 <= '1'; ALU2 <= '0';
			when EXE_RTYPE_OR		=> EN2 <= '1'; S1 <= '0'; S2 <= '1'; ALU1 <= '1'; ALU2 <= '1';
			when EXE_RTYPE_NOP		=> EN2 <= '0'; S1 <= '0'; S2 <= '0'; ALU1 <= '0'; ALU2 <= '0';
			when EXE_ITYPE_ADDI1	=> EN2 <= '1'; S1 <= '1'; S2 <= '1'; ALU1 <= '0'; ALU2 <= '0';
			when EXE_ITYPE_SUBI1	=> EN2 <= '1'; S1 <= '1'; S2 <= '1'; ALU1 <= '0'; ALU2 <= '1';
			when EXE_ITYPE_ANDI1	=> EN2 <= '1'; S1 <= '1'; S2 <= '1'; ALU1 <= '1'; ALU2 <= '0';
			when EXE_ITYPE_ORI1		=> EN2 <= '1'; S1 <= '1'; S2 <= '1'; ALU1 <= '1'; ALU2 <= '1';
			when EXE_ITYPE_ADDI2	=> EN2 <= '1'; S1 <= '0'; S2 <= '0'; ALU1 <= '0'; ALU2 <= '0';
			when EXE_ITYPE_SUBI2	=> EN2 <= '1'; S1 <= '0'; S2 <= '0'; ALU1 <= '0'; ALU2 <= '1';
			when EXE_ITYPE_ANDI2	=> EN2 <= '1'; S1 <= '0'; S2 <= '0'; ALU1 <= '1'; ALU2 <= '0';
			when EXE_ITYPE_ORI2		=> EN2 <= '1'; S1 <= '0'; S2 <= '0'; ALU1 <= '1'; ALU2 <= '1';
			when EXE_ITYPE_MOV		=> EN2 <= '1'; S1 <= '0'; S2 <= '0'; ALU1 <= '0'; ALU2 <= '0';
			when EXE_ITYPE_S_REG1	=> EN2 <= '1'; S1 <= '1'; S2 <= '0'; ALU1 <= '0'; ALU2 <= '0';
			when EXE_ITYPE_S_REG2	=> EN2 <= '1'; S1 <= '1'; S2 <= '0'; ALU1 <= '0'; ALU2 <= '0';
			when EXE_ITYPE_S_MEM2	=> EN2 <= '1'; S1 <= '0'; S2 <= '0'; ALU1 <= '0'; ALU2 <= '0';
			when EXE_ITYPE_L_MEM1	=> EN2 <= '1'; S1 <= '1'; S2 <= '1'; ALU1 <= '0'; ALU2 <= '0';
			when EXE_ITYPE_L_MEM2	=> EN2 <= '1'; S1 <= '0'; S2 <= '0'; ALU1 <= '0'; ALU2 <= '0';

			-- MEMORY

			when MEMWB_RTYPE_ADD	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_RTYPE_SUB	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_RTYPE_AND	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_RTYPE_OR		=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_RTYPE_NOP	=> EN3 <= '0'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '0';
			when MEMWB_ITYPE_ADDI1	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_ITYPE_SUBI1	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_ITYPE_ANDI1	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_ITYPE_ORI1	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_ITYPE_ADDI2	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_ITYPE_SUBI2	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_ITYPE_ANDI2	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_ITYPE_ORI2	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_ITYPE_MOV	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_ITYPE_S_REG1	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_ITYPE_S_REG2	=> EN3 <= '1'; RM <= '0'; WM <= '0'; S3 <= '0'; WF1 <= '1';
			when MEMWB_ITYPE_S_MEM2	=> EN3 <= '1'; RM <= '0'; WM <= '1'; S3 <= '1'; WF1 <= '0';
			when MEMWB_ITYPE_L_MEM1	=> EN3 <= '1'; RM <= '1'; WM <= '0'; S3 <= '1'; WF1 <= '1';
			when MEMWB_ITYPE_L_MEM2	=> EN3 <= '1'; RM <= '1'; WM <= '0'; S3 <= '1'; WF1 <= '1';
			when others => null;
		end case; 	
	end process P_OUTPUTS;
end behavioral;

