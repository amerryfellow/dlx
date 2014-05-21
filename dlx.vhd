library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use WORK.constants.all;
use WORK.alu_types.all;

entity DLX is
	generic (
		N : integer := numBit
	);

	port (
		FUNC:			in TYPE_OP;
		DATA1, DATA2:	in std_logic_vector(N-1 downto 0);
		OUTALU:			out std_logic_vector(N-1 downto 0)
	);
end DLX;

architecture GIANLUCA of DLX is
	component PIPEREG is
		generic (
			N		: integer;
			REGS	: integer;
		);

		port (
			CLK:		in	std_logic;							-- Clock
			RESET:		in	std_logic;							-- Reset
			I:			in array(0 to REGS) of std_logic_vector(N-1 downto 0);
			O:			out array(0 to REGS) of std_logic_vector(N-1 downto 0)
		);
	end component;

	signal PIPEREG_IF_ID:	PIPEREG;
	signal HALF_NBIT:	integer;

	begin
		-- First Pipeline register
		PIPEREG_IF_ID: PIPEREG
			generic map (N, 2)
			port map (CLK, RESET, (NPC_0, IR_0), (NPC_1, IR_1));

		-- Second Pipeline register
		PIPEREG_ID_EXE: PIPEREG
			generic map (N, 3)
			port map (CLK, RESET, (REG1_1, REG2_1, IM_1), (REG1_2, REG2_2, IM_2));

		-- Third Pipeline register
		PIPEREG_EXE_MEM: PIPEREG
			generic map (N, 2)
			port map (CLK, RESET, (ALUOUT_2, REG_2), (ALUOUT_3, REG2_3));

		-- Fourth Pipeline register
		PIPEREG_MEM_WB: PIPEREG
			generic map (N, 2)
			port map (CLK, RESET, (MEMOUT_3, ALUOUT_3), (MEMOUT_4, ALUOUT_4));


		ZERO_VECT	<= (others => '0');
		HALF_NBIT	<= N/2;
		POSITION	<= conv_integer(DATA2); -- Position must be lower than N-1
		IS_ZERO		<= not or_reduce(OUTALU);

		P_ALU : process (FUNC, DATA1, DATA2)
		begin
			end case;
		end process;
end BEHAVIORAL;

