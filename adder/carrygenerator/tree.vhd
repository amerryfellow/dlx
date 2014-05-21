library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.constants.all;
use std.textio.all;

-- Entity

entity TREE is
	generic(
		N:		integer	:= NSUMG;
		LOGN:	integer := LOG(NSUMG)
	);

	port(
		A:		in	std_logic_vector(N-1 downto 0);		-- N bit input
		B:		in	std_logic_vector(N-1 downto 0);		-- N bit input
		C:		out	std_logic_vector(N/4-1 downto 0)	-- Generate a carry every fourth bit
	);
end TREE;

-- Architectures

architecture STRUCTURAL of TREE is
	-- IC is an array of PG signals, which in turn are a couple of signals ( one for the
	-- propagate bit ( index 0 ), and one for the generate one ( index 1 ).
	type SignalVector is array (GETINDEX(LOGN, N/4) downto 0) of std_logic_vector(1 downto 0);
	signal IC: SignalVector;
	
	function GETINDEX(row : integer; col : integer) return integer is
		variable result : integer;
	
		begin
--			report integer'image(17*N);
			if row <= 2 then
--				report string'("case <= 3");
				result := 2*N - 2 ** (LOGN + 1 - row ) + col;
			else
--				report string'("case > 3");
				result := 7*N/4 + (row-3) * N/4 + col;
			end if;

--			report integer'image(row) & string'(" - ") & integer'image(col) & string'(" => ") & integer'image(result);
		return result;
	end GETINDEX;

	component INIT_PG
		port(
				A:	in	std_logic;
				B:	in	std_logic;
				PG:	out	std_logic_vector(1 downto 0)
			);
	end component;

	component TREE_G
		port(
				PG:	in	std_logic_vector(1 downto 0);
				GI:	in	std_logic;
				GO:	out	std_logic
			);
	end component;

	component TREE_PG
		port(
				PG0:	in	std_logic_vector(1 downto 0);
				PG1:	in	std_logic_vector(1 downto 0);
				PGO:	out	std_logic_vector(1 downto 0)
			);
	end component;

begin
	-- INIT_PG
	-- The first row generates the p_i and g_i bits for all the a_i and
	-- b_i bits. Their outputs are connected to the first N signals in IC.
	GEN_INIT_PG: for col in 0 to N-1 generate
		INIT_PGX: INIT_PG
		port map(A => A(col), B => B(col), PG => IC(col));
	end generate;

	-- Main Tree
	-- Being this a radix-4 sparse tree, this stage aggregates every four PG into a single signal.
	-- It thus reduces the number of columns from N to N/4.
	ROW_GEN:	for row in 1 to 2 generate
		COL_GEN: for col in 0 to N-1 generate
			-- Current element -> G(row, col)

			-- The first element is a TREE_G component.
			COLUMN_0 : if col = 0 generate
				TREE_GX: TREE_G
				port map(IC(GETINDEX(row-1, 1)), IC(GETINDEX(row-1, 0))(1), IC(GETINDEX(row, col))(1));
			end generate COLUMN_0;

			-- Elsewise it's a TREE_PG component.
			COLUMN_N : if col > 0 and col < (N/(2**row)) generate
				TREE_PGX: TREE_PG
				port map(IC(GETINDEX(row-1, (2*col+1))), IC(GETINDEX(row-1, 2*col)), IC(GETINDEX(row, col)));
			end generate COLUMN_N;
		end generate;
	end generate;

	-- GPG Network
	-- This represents the final stage of the tree, where the number of consecutive blocks increases,
	-- specifically in an exponential way ( 2^row ). This algorithm takes care of the proper generation
	-- of the blocks and the relative connections between its parts.
	--
	-- The term ((col - ( col mod (2**row) ))/(2**row)) evaluates the group number for a column in a row,
	-- being a group the consecutive instantiation of components of the same type. This is useful to know
	-- because it allows us to know the type of the component to generate by only knowing its position (
	-- row and column ) in the matrix/tree. Specifically: even groups are made of wires ( connection between
	-- vertically ( same column ) adjacent cells ), while odd groups are a TREE_G ( if the group number is
	-- 1 ) or a TREE_PG.
	RED_ROW:	for row in 0 to (LOGN-3) generate
		RED_COL:	for col in 0 to N/4-1 generate

			-- Group number is even ( X mod 2 = 0 ) -> Connection
			RED_BUF:	if ((col - ( col mod (2**row) ))/(2**row)) mod 2 = 0 generate
				IC(GETINDEX(row+3, col)) <= IC(GETINDEX(row+3-1, col));
			end generate RED_BUF;

			-- Group number is 1 ( X = 1 ) -> Generate
			RED_G:	if((col - ( col mod (2**row) ))/(2**row)) = 1 generate
				RED_G_GX: TREE_G
					port map(
						IC(GETINDEX(row+3-1, col)),
						IC(GETINDEX(row+3-1, (2**row)-1))(1),
						IC(GETINDEX(row+3, col))(1)
					);
			end generate RED_G;

			-- Group number is odd and different from 1 ( X mod 2 != 0 and X != 1) -> Propagate / Generate
			RED_PG:	if
				((col - ( col mod (2**row) ))/(2**row)) mod 2 /= 0 and
				((col - ( col mod (2**row) ))/(2**row)) /= 1
			generate
				RED_PG_GX: TREE_PG
					port map(
						IC(GETINDEX(row+3-1, col)),
						IC(GETINDEX(row+3-1, (col - col mod (2**row))-1)),
						IC(GETINDEX(row+3, col))
					);
			end generate RED_PG;
		end generate RED_COL;
	end generate RED_ROW;

	-- COUT
	-- The last row of the matrix/tree is made of TREE_G blocks, or connections leading to the corresponding
	-- TREE_G block. We can just attach its G bit ( index 1 ) to the output vector.
	COUT_GEN:	for col in 0 to N/4-1 generate
		C(col) <= IC(GETINDEX(LOGN, col))(1);
	end generate COUT_GEN;

end STRUCTURAL;
