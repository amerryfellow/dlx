library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use WORK.constants.all;
use WORK.alu_types.all;

entity ALU is
	generic (
		N : integer := numBit
	);

	port (
		FUNC:			in TYPE_OP;
		DATA1, DATA2:	in std_logic_vector(N-1 downto 0);
		OUTALU:			out std_logic_vector(N-1 downto 0)
	);
end ALU;

architecture BEHAVIORAL of ALU is
	component P4ADDER
		generic(
			N:			integer:=NSUMG
		);

		port (
			ENABLE:		in	std_logic;
			A:			in	std_logic_vector(N-1 downto 0);
			B:			in	std_logic_vector(N-1 downto 0);
			C0:			in	std_logic;
			S:			out	std_logic_vector(N-1 downto 0);
			OVERFLOW:	out	std_logic
		);
	end component;

	component BOOTHMUL
		generic(
			N:			integer:=NBIT
		);

		port(
			ENABLE:		in	std_logic;
			A:			in	std_logic_vector(N-1 downto 0);
			B:			in	std_logic_vector(N-1 downto 0);
			P:			out	std_logic_vector(2*N-1 downto 0)
		);
	end component;

	component COMPARATOR
		generic (
			N : integer := numBit
		);

		port (
			ENABLE:		in	std_logic;
			I1, I2:		in std_logic_vector(N-1 downto 0);
			O:			out std_logic
		);
	end component;

	signal HALF_NBIT:	integer;
	signal ZERO_VECT:	std_logic_vector(N-1 downto 0);
	signal IS_ZERO:		std_logic_vector(N-1 downto 0);
	signal POSITION:	integer; -- # of position that a signal has to be shifted/rotated

	-- Adder
	signal ADDER_ENABLE:		std_logic;
	signal ADDER_DATA1:			std_logic_vector(N-1 downto 0);
	signal ADDER_DATA2:			std_logic_vector(N-1 downto 0);
	signal ADDER_CIN:			std_logic;
	signal ADDER_COUT:			std_logic;
	signal ADDER_OUT:			std_logic_vector(N-1 downto 0);

	-- Multiplier
	signal MULTIPLIER_ENABLE:	std_logic;
	signal MULTIPLIER_DATA1:	std_logic_vector(N-1 downto 0);
	signal MULTIPLIER_DATA2:	std_logic_vector(N-1 downto 0);
	signal MULTIPLIER_OUT:		std_logic_vector(2*N-1 downto 0);

	-- Comparators
	for COMPG : COMPARATOR use entity work.COMPARATOR(GREATER_THAN);
	signal COMPG_ENABLE:	std_logic;
	signal COMPG_DATA1:		std_logic_vector(N-1 downto 0);
	signal COMPG_DATA2:		std_logic_vector(N-1 downto 0);
	signal COMPG_OUT:		std_logic;

	for COMPL : COMPARATOR use entity work.COMPARATOR(LOWER_THAN);
	signal COMPL_ENABLE:	std_logic;
	signal COMPL_DATA1:		std_logic_vector(N-1 downto 0);
	signal COMPL_DATA2:		std_logic_vector(N-1 downto 0);
	signal COMPL_OUT:		std_logic;

	begin
		-- Pentium 4 adder
		ADDER: P4ADDER
			generic map (N)
			port map (ADDER_ENABLE, ADDER_DATA1, ADDER_DATA2, ADDER_CIN, ADDER_COUT, ADDER_OUT);

		-- Booth Multiplier
		MULTIPLIER: BOOTHMUL
			generic map (N)
			port map (MULTIPLIER_ENABLE, MULTIPLIER_DATA1, MULTIPLIER_DATA2, MULTIPLIER_OUT);

		-- Comparator - Greater Than
		COMPG: COMPARATOR
			generic map (N)
			port map (COMPG_ENABLE, COMPG_DATA1, COMPG_DATA2, COMPG_OUT);

		-- Comparator - Lower Than
		COMPL: COMPARATOR
			generic map (N)
			port map (COMPL_ENABLE, COMPL_DATA1, COMPL_DATA2, COMPL_OUT);

		-- Assignments

		ZERO_VECT	<= (others => '0');
		HALF_NBIT	<= N/2;
		POSITION	<= conv_integer(DATA2); -- Position must be lower than N-1
		IS_ZERO		<= not or_reduce(OUTALU);

		P_ALU : process (FUNC, DATA1, DATA2)
		begin
			case FUNC is
				when ADD =>
					-- Use Pentium 4 adder
					ADDER_ENABLE		<= '1';
					ADDER_DATA1			<= DATA1;
					ADDER_DATA2			<= DATA2;
					ADDER_CIN			<= '0';
					OUTALU				<= ADDER_OUT;

				when SUB =>
					-- Use Pentium 4 adder
					ADDER_ENABLE		<= '1';
					ADDER_DATA1			<= DATA1;
					ADDER_DATA2			<= NOT DATA2;	-- Embed 2s complement
					ADDER_CIN			<= '1';			--
					OUTALU				<= ADDER_OUT;

				when MULT =>
					-- Use Booth's multiplier
					MULTIPLIER_ENABLE	<= '1';
					MULTIPLIER_DATA1	<= DATA1(N/2-1 downto 0);
					MULTIPLIER_DATA2	<= DATA2(N/2-1 downto 0);
					OUTALU				<= MULTIPLIER_OUT;

				-- Bitwise Ops

				when BITAND		=> OUTALU <= DATA1 and DATA2;
				when BITOR		=> OUTALU <= DATA1 or DATA2;
				when BITXOR		=> OUTALU <= DATA1 xor DATA2;

				-- Shift / Rotate

				when BITSHL		=> OUTALU <= DATA1(N-POSITION-1 downto 0) & ZERO_VECT(POSITION-1 downto 0);
				when BITSHR		=> OUTALU <= ZERO_VECT(POSITION-1 downto 0) & DATA1(N-1 downto POSITION);
				when BITROL		=> OUTALU <= DATA1(N-POSITION-1 downto 0) & DATA1(N-1 downto N-POSITION);
				when BITROR		=> OUTALU <= DATA1(POSITION downto 0) & DATA1(N-1 downto POSITION+1);

				-- Comparisons

				when GT =>
					COMPG_ENABLE	<= '1';
					COMPG_DATA1		<= DATA1;
					COMPG_DATA2		<= DATA2;
					OUTALU			<= COMPG_OUT;

				when LE =>
					COMPG_ENABLE	<= '1';
					COMPG_DATA1		<= DATA1;
					COMPG_DATA2		<= DATA2;
					OUTALU			<= not COMPG_OUT;

				when LT =>
					COMPL_ENABLE	<= '1';
					COMPL_DATA1		<= DATA1;
					COMPL_DATA2		<= DATA2;
					OUTALU			<= COMPL_OUT;

				when GE =>
					COMPL_ENABLE	<= '1';
					COMPL_DATA1		<= DATA1;
					COMPL_DATA2		<= DATA2;
					OUTALU			<= not COMPL_OUT;

				-- Others
				when others		=> null;

			end case;
		end process;
end BEHAVIORAL;

