library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use WORK.constants.all;

entity BOOTHMUL is
	generic (
		N	: integer := multiplierBits
	);
	port (
		ENABLE	: in	std_logic;
		A		: in	std_logic_vector(N-1 downto 0);
		B		: in	std_logic_vector(N-1 downto 0);
		P		: out	std_logic_vector(2*N-1 downto 0)
	);
end BOOTHMUL;

architecture mixed of BOOTHMUL is
	type SignalVector is array (N/2-1 downto 0) of std_logic_vector(2*N-1 downto 0);

	signal encoder:std_logic_vector(N downto 0);
	signal A_in:std_logic_vector(2*N - 1 downto 0):=(others => '0');

	-- Outputs of each MUX or ADDER block step
	signal mux_out:SignalVector;
	signal sum_internal:SignalVector;

	-- Allows signed multiplication by implementing 2's complement without an adder.
	signal Cin:std_logic_vector(N/2-1 downto 0);

	-- Sign extension wires
	signal signext:std_logic_vector(N-1 downto 0);

	-- Dummy fulladder cout connection
	signal cout:std_logic;

	component MUX3B
		generic(
			N:integer := multiplierBits;
			OFFSET:integer:=0
		);
		port (
			A		: in	std_logic_vector(N-1 downto 0);
			CTRL	: in	std_logic_vector(2 downto 0);
			Y		: out	std_logic_vector(N-1 downto 0);
			Cin		: out	std_logic
		);
	end component;

	component RCA_GENERIC
		generic (
			NBIT:integer := multiplierBits
		);
		port (
			A:	in	std_logic_vector(NBIT-1 downto 0);
			B:	in	std_logic_vector(NBIT-1 downto 0);
			Ci:	in	std_logic;
			S:	out	std_logic_vector(NBIT-1 downto 0);
			Co:	out	std_logic);
	end component;

begin

	-- The first bit of the encoder vector is a 0
	encoder <= B & '0';

	-- Sign extension: A_in is the sign extension representation of A
	signext <= (others => A(N-1));
	A_in <= signext & A;

	SUM_N: for i in 0 to N/2 - 1 generate
		-- Create the MUX/encoder coupled component
		N_MUX: MUX3B
			generic map(2*N,2*i)
			port map (A_in, encoder((2*i+2) downto 2*i), mux_out(i), Cin(i));

		-- Create the RCA blocks

		-- The first RCA has only a mux ( and its Cin ) as an input.
		SUM_0: if i = 0 generate
			S0:RCA_GENERIC
				generic map(2*N)
				port map(mux_out(i), (others =>'0'), Cin(i), sum_internal(i), cout);
			end generate;

		-- The other RCAs take the output of the mux, its Cin, and the output of the previous RCA block
		SUM: if i /= 0 generate
			SN:RCA_GENERIC
				generic map(2*N)
				port map(sum_internal(i-1), mux_out(i), Cin(i), sum_internal(i), cout);
			end generate;
	end generate;

	-- Output
	P <= sum_internal(N/2 - 1);

end mixed;

