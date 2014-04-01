library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

-- Entity

entity TREE is
	port(
		A:		in	std_logic_vector(31 downto 0);
		B:		in	std_logic_vector(31 downto 0);
		C:		out	std_logic_vector(7 downto 0)
	);
end TREE;

architecture STRUCTURAL of TREE is
	type  SignalVector is array (67 downto 0) of std_logic_vector(1 downto 0);
	signal IC: SignalVector;
	
function GETINDEX(row : integer; col : integer) return integer is
begin
--	return  64 * ( 1 - 2 ** ( - row ) ) + col;
	return  64 - 2 ** ( 6 - row ) + col;
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
		-- Evaluate Pi and Gi
		-- INIT_PG
		GEN_INIT_PG:
			for col in 0 to 31 generate
			INIT_PGX: INIT_PG
				port map(A => A(col), B => B(col), PG => IC(col));
		end generate;

		-- Main Tree
		-- Reduces from 2^2+N to 2^2
		
		ROW_GEN:	for row in 1 to 3 generate
			COL_GEN: for col in 0 to 31 generate
				-- Current element -> G(row, col)
				
				COLUMN_0 : if col = 0 generate
						TREE_GX: TREE_G
							port map(IC(GETINDEX(row-1, 1)), IC(GETINDEX(row-1, 0))(1), IC(GETINDEX(row, col))(1));
				end generate COL0;
	
				COLUMN_N : if col > 0 and col < (32/(2**row)) generate
						TREE_PGX: TREE_PG
							port map(IC(GETINDEX(row-1, (2*col+1))), IC(GETINDEX(row-1, 2*col)), IC(GETINDEX(row, col)));
				end generate COLN;
			end generate;
		end generate;

		-- PG part
--		row := row+1;
--		TREE_G	port map(IC(GETINDEX(row-2,2)), IC(GETINDEX(row-1, 0)), IC(row, 0));
--		TREE_G	port map(IC(GETINDEX(row-1,1)), IC(GETINDEX(row-1, 0)), IC(row, 1));
--		TREE_PG	port map(IC(GETINDEX(row-2,6)), IC(GETINDEX(row-1, 2)), IC(row, 2));
--		TREE_PG	port map(IC(GETINDEX(row-1,3)), IC(GETINDEX(row-1, 2)), IC(row, 3));

--		-- G part
--		row := row+1;
--		TREE_G	port map(IC(GETINDEX(row-3,4)), IC(GETINDEX(row-1, 1)), IC(row, 0));
--		TREE_G	port map(IC(GETINDEX(row-2,2)), IC(GETINDEX(row-1, 1)), IC(row, 1));
--		TREE_G	port map(IC(GETINDEX(row-1,2)), IC(GETINDEX(row-1, 1)), IC(row, 2));
--		TREE_G	port map(IC(GETINDEX(row-1,3)), IC(GETINDEX(row-1, 1)), IC(row, 3));

		-- The last 8 elements in IC are C(7 downto 0)
end STRUCTURAL;
