library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

-- Entity

entity TREE is
	generic(
		N: integer:=NSUMG;
		NC: integer:=NCSUMG
	);
	port(
		A:		in	std_logic_vector(N-1 downto 0);
		B:		in	std_logic_vector(N-1 downto 0);
		C:		out	std_logic_vector(NC-1 downto 0)
	);
end TREE;

architecture STRUCTURAL of TREE is
	type SignalVector is array ((2*N-1) downto 0) of std_logic_vector(1 downto 0);
	signal IC: SignalVector;	

	function GETPOWER(count : integer) return integer is
		variable power		integer:=0;
		variable index		integer;

		begin
			index:=count;
			while index /=0 loop
				power:=power + 1;
				index:=index/2;
			end loop;
			return power;
		end GETPOWER;

	function GETINDEX(row : integer; col : integer) return integer is
		begin
			return  (2*N) - 2 ** ( GETPOWER(N) - row ) + col;
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
	ROW_GEN:	for row in 1 to GETPOWER(N)-3 generate
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

	--		row := 4;
	ROW4_1: TREE_G port map(IC(GETINDEX(2,2)), IC(GETINDEX(3, 0))(1),IC(GETINDEX(4, 0))(1));--C12
	ROW4_2: TREE_G port map(IC(GETINDEX(3,1)), IC(GETINDEX(3, 0))(1), IC(GETINDEX(4, 1))(1));--C16
	ROW4_3: TREE_PG	port map(IC(GETINDEX(2,6)), IC(GETINDEX(3, 2)), IC(GETINDEX(4, 2)));
	ROW4_4: TREE_PG	port map(IC(GETINDEX(3,3)), IC(GETINDEX(4, 2)), IC(GETINDEX(4, 3)));
	C(2)<=IC(GETINDEX(4, 0))(1);--C12
	C(3)<=IC(GETINDEX(4, 1))(1);--C16


	--		-- Only G part
	--		row := 5;
	ROW5_1: TREE_G port map(IC(GETINDEX(2,4)), IC(GETINDEX(4, 1))(1), C(N-4));
	ROW5_2: TREE_G port map(IC(GETINDEX(3,2)), IC(GETINDEX(4, 1))(1), C(N-3));
	ROW5_3: TREE_G port map(IC(GETINDEX(4,2)), IC(GETINDEX(4, 1))(1), C(N-2));
	ROW5_4: TREE_G port map(IC(GETINDEX(4,3)), IC(GETINDEX(4, 1))(1), C(N-1));

-- The last 8 elements in IC are C(7 downto 0)
end STRUCTURAL;
