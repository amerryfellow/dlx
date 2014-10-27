library ieee;
library std;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use WORK.alu_types.all;
use std.textio.all;

-- Entity

entity TREE is
	generic(
		N:		integer	:= NSUMG;
		LOGN:	integer := LOG(NSUMG) -- The LOG function is in the P4ADDER_constants file
	);

	port(
		A:		in	std_logic_vector(N-1 downto 0);		-- N bit input
		B:		in	std_logic_vector(N-1 downto 0);		-- N bit input
		Cin: 	in 	std_logic;
		C:		out	std_logic_vector(N/4-1 downto 0)	-- Generate a carry every fourth bit
	);
end TREE;

-- Architectures

architecture STRUCTURAL of TREE is
	-- Every internal signal is stored into a SignalVector. To try to increase the density of the array,
	-- the first part of the matrix is contiguous in the rows: The first N elements are the members of the
	-- first row, the following N/2 elements are of the second row, the following N/4 are of the third row,
	-- and so on. In order to increase the understandability and lower the complexity of the code, however,
	-- the signals related to the G/PG part of the tree are stored in a fixed-length fashion, where any
	-- hole ( short-circuit ) in the matrix is saved as a direct connection.
	--
	-- The GETINDEX function handles the array, returning, given the element location ( row, column ), the
	-- corresponding index in the array.
	function GETINDEX(row : integer; col : integer) return integer is
		variable result : integer;
	
		begin
			if row <= 2 then
--				report string'("case <= 3");
				result := 2*N - 2 ** (LOGN + 1 - row ) + col;	-- This returns the number of the column 
			else												-- in which takes the input for the next row(PG or G group).
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
				PG:	out	std_logic_vector(1 downto 0) -- PG(0) = propagate; PG(1) = generate;
			);
	end component;

	component TREE_G -- Gi:j = Gi:k + Pi:k * Gk-1:j;
		port(
				PG:	in	std_logic_vector(1 downto 0);-- PG(1) = Gi:k ; PG(0) = Pi:k;
				GI:	in	std_logic; --GI = Gk-1:j;
				GO:	out	std_logic
			);
	end component;
	
	component TREE_PG -- Gi:j = Gi:k + Pi:k * Gk-1:j; Pi:j=Pi:k *Pk-1:j
		port(
				PG0:	in	std_logic_vector(1 downto 0); -- PG0(0) = Pi:k // PG0(1) = Gi:k
				PG1:	in	std_logic_vector(1 downto 0); -- PG1(0) = Pk-1:j // PG1(1) = Gk-1:j
				PGO:	out	std_logic_vector(1 downto 0) -- PGO(0) = Gi:j // PGO(1) = Pi:j
			);
	end component;
	
	-- IC is an array of PG signals, which in turn are a couple of signals ( one for the
	-- propagate bit ( index 0 ), and one for the generate one ( index 1 ).
	type SignalVector is array (GETINDEX(LOGN, N/4) downto 0) of std_logic_vector(1 downto 0);
	signal IC: SignalVector;
	signal propagate_cin: std_logic_vector(1 downto 0);

begin
	-- INIT_PG
	-- The first row generates the p_i and g_i bits for all the a_i and
	-- b_i bits. Their outputs are connected to the first N signals in IC.
	
	
	
	GEN_INIT_PG: for col in 1 to N-1 generate
		INIT_PGX: INIT_PG
		port map(A => A(col), B => B(col), PG => IC(col));
	end generate;
	
	INIT_Cin: INIT_PG port map(A(0),B(0),propagate_cin);
	CinPropagate: TREE_G port map(propagate_cin, Cin , IC(0)(1));

	-- Main Tree
	-- Being this a radix-2 sparse tree, this stage aggregates every four PG into a single signal.
	-- It thus reduces the number of columns from N to N/4.
	ROW_GEN:	for row in 1 to 2 generate
		COL_GEN: for col in 0 to N-1 generate
			-- Current element -> G(row, col)

			-- The first element is a TREE_G component.
			-- i.e row = 1 and col = 0 takes as input propagate, generate of a(0) b(0)
			-- generate of a(1),b(1) - output G1:0
			COLUMN_0 : if col = 0 generate
				TREE_GX: TREE_G
				port map(IC(GETINDEX(row-1, 1)), IC(GETINDEX(row-1, 0))(1), IC(GETINDEX(row, col))(1));
			end generate COLUMN_0;

			-- Elsewise it's a TREE_PG component.
			-- i.e row = 1 and col = 1	takes as input propagate,generate of a(3),b(3) generate
			-- of a(2),b(2) - output P3:2 G3:2.
			-- i.e row = 2 and col = 1 takes as input G1:0,P3:2 and G3:2 - output G3:0=carry4
			-- as shown in the text figure(instead of starting from 1 for a and b we start from 0).
			COLUMN_N : if col > 0 and col < (N/(2**row)) generate
				TREE_PGX: TREE_PG
				port map(IC(GETINDEX(row-1, (2*col+1))), IC(GETINDEX(row-1, 2*col)), IC(GETINDEX(row, col)));
			end generate COLUMN_N;
		end generate;
	end generate;

	-- G/PG Network
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

