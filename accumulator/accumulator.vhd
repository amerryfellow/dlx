library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.constants.all;

entity ACCUMULATOR is
	generic (
		NBIT:integer:=numbit
	);
	port (
			A          : in  std_logic_vector(NBIT - 1 downto 0);
			B          : in  std_logic_vector(NBIT - 1 downto 0);
			CLK        : in  std_logic;
			RST_n      : in  std_logic;
			ACCUMULATE : in  std_logic;
--			ACC_EN_n   : in  std_logic;  -- optional use of the enable
			Y          : out std_logic_vector(NBIT - 1 downto 0));
end ACCUMULATOR;

-- Architectures

architecture STRUCTURAL of ACCUMULATOR is
	signal MUX_OUTPUT:	std_logic_vector(NBIT-1 downto 0);
	signal OUT_ADD:		std_logic_vector(NBIT-1 downto 0);
	signal FEEDBACK:	std_logic_vector(NBIT-1 downto 0);
	signal CIN:			std_logic:='0';
	signal COUT:		std_logic;

	component RIPPLECARRYADDER
		generic (
			NBIT:integer:=numbit;
			DELAY_RIPPLECARRYADDER_S :	time := 0 ns;
			DELAY_RIPPLECARRYADDER_C :	time := 0 ns;
		);

		port (
			A:		in	std_logic_vector(NBIT-1 downto 0);
			B:		in	std_logic_vector(NBIT-1 downto 0);
			Ci:		in	std_logic;
			S:		out	std_logic_vector(NBIT-1 downto 0);
			Co:		out	std_logic;
		);
	end component;	

	component REGISTER_FLIPFLOP_D 
		generic (
			N:			integer:= numBit;
			DELAY_MUX:	time:= 0 ns;
		);
		
		port (
			DIN:	In	std_logic_vector(N-1 downto 0);
			CK:	In	std_logic;
			RESET:	In	std_logic;
			DOUT:	Out	std_logic_vector(N-1 downto 0);
		);
	end component;

	component MUX
		generic(
			N: integer:= numBit;
			DELAY_MUX: Time:= tp_mux;
		);
		
		port (
			A:	In	std_logic_vector(N-1 downto 0) ;
			B:	In	std_logic_vector(N-1 downto 0);
			SEL:	In	std_logic;
			Y:	Out	std_logic_vector(N-1 downto 0)
		);
	end component;	

	begin
		MUX_PART:MUX
			port map(B, FEEDBACK, ACCUMULATE, MUX_OUTPUT); -- MUX_OUTPUT <= B when ACCUMALATE ='1' ELSE FEEDBACK;
	
		ADDER:RIPPLECARRYADDER
			port map(A, MUX_OUTPUT, CIN, OUT_ADD, COUT); --COUT WITHOUT OVERFLOW DETECTOR, INFORMATION LOST
	
		REG:REGISTER_FLIPFLOP_D
			port map(OUT_ADD, CLK, RST_n, FEEDBACK); -- RESET SYNC,EDGE TRIGGERED CLK
	
		Y <= FEEDBACK;
end STRUCTURAL;

configuration CFG_ACCUMULATOR_STRUCTURAL of ACCUMULATOR is
	for STRUCTURAL
		for MUX_PART: MUX
			use configuration WORK.CFG_MUX_STRUCTURAL;
		end for;
		for ADDER: RCA_GENERIC 
			use configuration WORK.CFG_RIPPLECARRYADDER_STRUCTURAL;
		end for;
		for REG: REGISTER_FLIPFLOP_D
			use configuration WORK.CFG_REGISTER_FLIPFLOP_D_SYNCHRONOUS;
		end for;
	end for;
end CFG_ACCUMULATOR_STRUCTURAL;	

