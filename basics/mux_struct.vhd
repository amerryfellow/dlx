library IEEE;

use IEEE.std_logic_1164.all;
use WORK.alu_types.all;

--
-- Generic n-bit mux with two input vectors and one output vector
--

entity MUX is
	generic (
		N:			integer	:= NSUMG		-- Number of bits
	);

	port (
		A:		in	std_logic_vector(N-1 downto 0);
		B:		in	std_logic_vector(N-1 downto 0);
		SEL:	in	std_logic;
		Y:		out	std_logic_vector(N-1 downto 0)
	);
end MUX;

-- Architectures

architecture STRUCTURAL of MUX is
	signal A_NAND: std_logic_vector(N-1 downto 0); -- Output of first nand A_NAND
	signal B_NAND: std_logic_vector(N-1 downto 0); -- Output of first nand B_NAND
	signal SEL_NOT: std_logic;

	component INVERTER
		port (
			A:	in	std_logic;
			Y:	out	std_logic	-- Y <= not A;
		);
	end component;

	component NAND1
		port (
			A:	in	std_logic;
			B:	in	std_logic;
			Y:	out	std_logic	--Y <= A nand B;
		);
	end component;

	begin
		INV_GEN:
			INVERTER port map(SEL, SEL_NOT);

		-- Generates 3*N nand ports from the NAND1 compoment:
		-- N nands are used to evaluate A_NAND(i) = NOT( A(i) * SEL )
		-- N nands are used to evaluate B_NAND(i) = NOT( B(i) * SEL_NOT )
		-- Then these outputs are fed to other N nands to evaluate
		-- NOT( NOT( A(i) * SEL ) * NOT( B(i) * SEL_NOT ) ) = A * SEL + B * SEL_NOT
		-- which is the classic n-bit mux behavior

		NAND_GEN:
			for i in 0 to N-1 generate
				NAND_A	:NAND1	port map(A(i),		SEL,		A_NAND(i));
				NAND_B	:NAND1	port map(B(i),		SEL_NOT,	B_NAND(i));
				Y_GEN	:NAND1	port map(A_NAND(i),	B_NAND(i),	Y(i));
			end generate;
end STRUCTURAL;
