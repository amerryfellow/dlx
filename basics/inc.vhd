library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity INCREMENTER is
	generic (
		N: integer
	);

	port (
		A: in std_logic_vector (N-1 downto 0);
		Y: out std_logic_vector(N-1 downto 0)
	);
end INCREMENTER;

architecture structural of INCREMENTER is
	component INIT_PG -- in roughly speaking is an half adder.
		port (
			A:		in	std_logic;
			B:		in	std_logic;
			PG:		out	std_logic_vector(1 downto 0)
		);
	end component;

	signal cout: std_logic_vector(N-1 downto 0);
	type SignalVector is array (N-2 downto 0) of std_logic_vector(1 downto 0);
	signal IC: SignalVector;

begin

	Y(0) <= not A(0);
	cout(0) <= A(0);

	PROPAGATION: for X in 1 to N-1 generate
		INIT_PGX: INIT_PG
			port map (A(X),cout(X - 1),IC(X - 1));

		WIRING_Co:	cout(X) <= IC((X - 1))(1);
		WIRING_OUT:	Y(X) <= IC(X - 1)(0);
	end generate;

end structural;
