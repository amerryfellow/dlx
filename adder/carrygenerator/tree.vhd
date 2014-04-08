library ieee;
library std;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;
use std.textio.all;

-- Entity

entity TREE is
	generic(
		N: integer	:=	64;	--NSUMG;
		NC: integer	:=	6	--NCSUMG
	);
	port(
		A:		in	std_logic_vector(N-1 downto 0);
		B:		in	std_logic_vector(N-1 downto 0);
		C:		out	std_logic_vector(N/4-1 downto 0)
	);
end TREE;

architecture STRUCTURAL of TREE is
	type SignalVector is array ((4*N-1) downto 0) of std_logic_vector(1 downto 0);
	signal IC: SignalVector;	

	function GETINDEX(row : integer; col : integer) return integer is
		variable result : integer;

		begin
--			report integer'image(17*N);

			if row <= 2 then
--				report string'("case <= 3");
				result := 2*N - 2 ** ( NC+1 - row ) + col;
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
				PG:	out	std_logic_vector(1 downto 0) --PG(0) PROPAGATE PG(1) GENERATE
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
	for col in 0 to N-1 generate
		INIT_PGX: INIT_PG
		port map(A => A(col), B => B(col), PG => IC(col));
	end generate;

	-- Main Tree
	-- Reduces from 2^2+N to 2^2
	ROW_GEN:	for row in 1 to 2 generate
		COL_GEN: for col in 0 to N-1 generate
			-- Current element -> G(row, col)

			COLUMN_0 : if col = 0 generate
				TREE_GX: TREE_G
				port map(IC(GETINDEX(row-1, 1)), IC(GETINDEX(row-1, 0))(1), IC(GETINDEX(row, col))(1));
			end generate COLUMN_0;

			COLUMN_N : if col > 0 and col < (N/(2**row)) generate
				TREE_PGX: TREE_PG
				port map(IC(GETINDEX(row-1, (2*col+1))), IC(GETINDEX(row-1, 2*col)), IC(GETINDEX(row, col)));
			end generate COLUMN_N;
		end generate;
	end generate;

	-- Reducer

	RED_ROW:	for row in 0 to (NC-3) generate
		RED_COL:	for col in 0 to N/4-1 generate

			-- Buffer
			RED_BUF:	if ((col - ( col mod (2**row) ))/(2**row)) mod 2 = 0 generate
				IC(GETINDEX(row+3, col)) <= IC(GETINDEX(row+3-1, col));
			end generate RED_BUF;

			-- Generate
			RED_G:	if((col - ( col mod (2**row) ))/(2**row)) = 1 generate
				RED_G_GX: TREE_G
					port map(IC(GETINDEX(row+3-1, col)), IC(GETINDEX(row+3-1, (2**row)-1))(1), IC(GETINDEX(row+3, col))(1));
			end generate RED_G;

			-- Propagate / Generate
			RED_PG:	if ((col - ( col mod (2**row) ))/(2**row)) mod 2 /= 0 and ((col - ( col mod (2**row) ))/(2**row)) /= 1 generate
				RED_PG_GX: TREE_PG
					port map(IC(GETINDEX(row+3-1, col)), IC(GETINDEX(row+3-1, (col - col mod (2**row))-1)), IC(GETINDEX(row+3, col)));
			end generate RED_PG;
		end generate RED_COL;
	end generate RED_ROW;

	-- COUT
	-- C(15 downto 0) <= IC(GETINDEX(NC, N/4-1) downto GETINDEX(NC, 0))
	COUT_GEN:	for col in 0 to N/4-1 generate
		C(col) <= IC(GETINDEX(NC, col))(1);
	end generate COUT_GEN;


end STRUCTURAL;
