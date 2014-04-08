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

			if row <= 3 then
--				report string'("case >= 3");
				result := 2*N - 2 ** ( NC+1 - row ) + col;
			elsif row = 4 then
--				report string'("case = 4");
				result := 15*N/8 + col;
			else
--				report string'("case = 5");
				result := 17*N/8 - 4 + col;
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
	ROW_GEN:	for row in 1 to 3 generate
		COL_GEN: for col in 0 to N-1 generate
			-- Current element -> G(row, col)

			COLUMN_0 : if col = 0 generate
				TREE_GX: TREE_G
				port map(IC(GETINDEX(row-1, 1)), IC(GETINDEX(row-1, 0))(1), IC(GETINDEX(row, col))(1));
				C4_C8: if (row >= 2 ) generate
					C(row-2)<= IC(GETINDEX(row, col))(1);
				end generate C4_C8;

			end generate COLUMN_0;

			COLUMN_N : if col > 0 and col < (N/(2**row)) generate
				TREE_PGX: TREE_PG
				port map(IC(GETINDEX(row-1, (2*col+1))), IC(GETINDEX(row-1, 2*col)), IC(GETINDEX(row, col)));
			end generate COLUMN_N;
		end generate;
	end generate;

	-- PG Row ( Fourth row )

	-- First half
	ROW_PG_1_GEN:	for col in 0 to ((N/8)-3) generate
		ROW_PG_1_E: if (col mod 2) = 0 generate
			ROW_PG_E_GX: TREE_G
				port map(IC(GETINDEX(4-2, 2+col)), IC(GETINDEX(3, 0))(1), IC(GETINDEX(4, col))(1));
		end generate ROW_PG_1_E;

		ROW_PG_1_O: if (col mod 2) = 1 generate
			ROW_PG_O_GX: TREE_G
				port map(IC(GETINDEX(4-1, ((col-1)/2+1))), IC(GETINDEX(4-1, 0))(1), IC(GETINDEX(4, col))(1));
		end generate ROW_PG_1_O;

		-- Cout
		C(2+col) <= IC(GETINDEX(4, col))(1);	-- C12 -> C((N/2))
	end generate ROW_PG_1_GEN;

	-- Second half
	ROW_PG_2_GEN:	for col in ((N/8)-2) to ((N/4)-5) generate
		ROW_PG_2_E: if (col mod 2) = 0 generate
			ROW_PG_E_PGX: TREE_PG
				port map(IC(GETINDEX(4-2, 4+col)), IC(GETINDEX(4-1, N/16)), IC(GETINDEX(4, col)));
		end generate ROW_PG_2_E;

		ROW_PG_2_O: if (col mod 2) = 1 generate
			ROW_PG_O_PGX: TREE_PG
				port map(IC(GETINDEX(4-1, ((col-1)/2+2))), IC(GETINDEX(4-1, N/16)), IC(GETINDEX(4, col)));
		end generate ROW_PG_2_O;
	end generate ROW_PG_2_GEN;

--	ROW4_1: TREE_G port map(IC(GETINDEX(2,2)), IC(GETINDEX(3, 0))(1),IC(GETINDEX(4, 0))(1));--C12
--	ROW4_2: TREE_G port map(IC(GETINDEX(3,1)), IC(GETINDEX(3, 0))(1), IC(GETINDEX(4, 1))(1));--C16
--	ROW4_3: TREE_PG	port map(IC(GETINDEX(2,6)), IC(GETINDEX(3, 2)), IC(GETINDEX(4, 2)));
--	ROW4_4: TREE_PG	port map(IC(GETINDEX(3,3)), IC(GETINDEX(4, 2)), IC(GETINDEX(4, 3)));

	-- Only G part
	ROW_G_GX_0: TREE_G
		port map(IC(GETINDEX(2, N/8)), IC(GETINDEX(4, ((N/8)-3)))(1), IC(GETINDEX(5, 0))(1));
		C(N/8) <= IC(GETINDEX(5, 0))(1);

	ROW_G_GX_1: TREE_G
		port map(IC(GETINDEX(3, N/16)), IC(GETINDEX(4, ((N/8)-3)))(1), IC(GETINDEX(5, 1))(1));
		C(N/8 + 1) <= IC(GETINDEX(5, 1))(1);

	ROW_G_GEN:	for col in 2 to (N/8)-1 generate
		ROW_G_GX: TREE_G
			port map(IC(GETINDEX(4, ((N/4-4)/2+col-2))), IC(GETINDEX(4, ((N/8)-3)))(1), IC(GETINDEX(5, col))(1));

		-- Cout
		 C(N/8+col) <= IC(GETINDEX(5, col))(1);	-- C12 -> C((N/2))
	end generate ROW_G_GEN;

	--		row := 5;
	--ROW5_1: TREE_G port map(IC(GETINDEX(2,4)), IC(GETINDEX(4, 1))(1), C(N-4));
	--ROW5_2: TREE_G port map(IC(GETINDEX(3,2)), IC(GETINDEX(4, 1))(1), C(N-3));
	--ROW5_3: TREE_G port map(IC(GETINDEX(4,2)), IC(GETINDEX(4, 1))(1), C(N-2));
	--ROW5_4: TREE_G port map(IC(GETINDEX(4,3)), IC(GETINDEX(4, 1))(1), C(N-1));

	-- Manual remining COUT
	C(0) <= IC(GETINDEX(2, 0))(1);	-- C4
	C(1) <= IC(GETINDEX(3, 0))(1);	-- C8
end STRUCTURAL;
