library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity INCREMENTER is
	generic (
		N : integer
	)
	port (
		A: in std_logic_vector (N-1 downto 0);
		Y: out std_logic_vector(N-1 downto 0)
	);
end INCREMENTER;

architecture structural of INCREMENTER is
	component halfadder  -- is an half adder.
		port (
			A: in std_logic;
			B: in std_logic;
			S: out std_logic;
			C: out std_logic
		);
	end component;

	signal cout,sum: std_logic_vector(N-1 downto 0);
begin

	sum(0) <= not A(0);		-- S = A(0) xor 1 = !A(0)
	cout(0) <= A(0);		-- cout = A(0) and 1= A(0)

	PROPAGATION: for X in 1 to N-1 generate
		INIT_HA: HA port map (A(X),cout(X - 1),sum(X),cout(X));
	end generate;

	Y <= sum;
end structural;
