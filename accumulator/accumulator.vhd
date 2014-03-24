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
		--- ACC_EN_n   : in  std_logic;  -- optional use of the enable
		Y          : out std_logic_vector(NBIT - 1 downto 0)
	);
end ACCUMULATOR;

-- Architectures

architecture STRUCTURAL of ACCUMULATOR is
	signal MUX_OUTPUT: std_logic_vector(NBIT-1 downto 0);
	signal OUT_ADD: std_logic_vector(NBIT-1 downto 0);
	signal FEEDBACK: std_logic_vector(NBIT-1 downto 0);
	signal CIN: std_logic:='0';
	signal COUT:std_logic;

	component RCA_GENERIC
		generic (
			NBIT:integer:=numBit;
			DRCAS : 	Time := 0 ns;
			DRCAC : 	Time := 0 ns
		);
		port (
			A:	In	std_logic_vector(NBIT-1 downto 0);
			B:	In	std_logic_vector(NBIT-1 downto 0);
			Ci:	In	std_logic;
			S:	Out	std_logic_vector(NBIT-1 downto 0);
			Co:	Out	std_logic
		);
	end component;	

	component REGISTER_FD 
		generic (
			N: integer:= numBit;
			DELAY_MUX: Time:= 0 ns
		);
		port (
			DIN:	In	std_logic_vector(N-1 downto 0);
			CK:	In	std_logic;
			RESET:	In	std_logic;
			DOUT:	Out	std_logic_vector(N-1 downto 0)
		);
	end component;

	component MUX
		generic (
			N: integer:= numBit;
			MUX_DELAY: Time:= tp_mux
		);
		port (
			A:	In	std_logic_vector(N-1 downto 0);
			B:	In	std_logic_vector(N-1 downto 0);
			SEL:	In	std_logic;
			Y:	Out	std_logic_vector(N-1 downto 0)
		);
	end component;	

	begin
		MUX_PART:MUX
			port map(B,FEEDBACK,ACCUMULATE,MUX_OUTPUT); -- MUX_OUTPUT <= B when ACCUMALATE ='1' ELSE FEEDBACK;

	ADDER:RCA_GENERIC
		port map(A,MUX_OUTPUT,CIN,OUT_ADD,COUT); --COUT WITHOUT OVERFLOW DETECTOR, INFORMATION LOST

	REG:REGISTER_FD
		port map(OUT_ADD,CLK,RST_n,FEEDBACK); -- RESET SYNC,EDGE TRIGGERED CLK

	Y<=FEEDBACK;
end STRUCTURAL;

architecture BEHAVIOURAL of ACCUMULATOR is
	signal BEH_MUX_OUTPUT: std_logic_vector(NBIT-1 downto 0);
	signal BEH_OUT_ADD: std_logic_vector(NBIT-1 downto 0);
	signal BEH_FEEDBACK: std_logic_vector(NBIT-1 downto 0);
	signal Y_TEMP: std_logic_vector(NBIT-1 downto 0);

	begin

	MUX_PROCESS : process(B, BEH_FEEDBACK)
	begin
		if ACCUMULATE='1' then
		   BEH_MUX_OUTPUT<=B;
		else
			BEH_MUX_OUTPUT<=BEH_FEEDBACK;
		end if;
	end process;

	ADD_PROCESS : process(A, BEH_MUX_OUTPUT)
	begin
		BEH_OUT_ADD <= A + BEH_MUX_OUTPUT;
	end process;

	OUTPUT : process(CLK, RST_N, BEH_OUT_ADD)
	begin
		if RST_N='1' then
			Y<=(others=>'Z');
		elsif CLK'event and CLK='1' then
			Y<= BEH_OUT_ADD;
			BEH_FEEDBACK <= BEH_OUT_ADD;
		end if;
	end process;
end BEHAVIOURAL;

-- Configurations

configuration CFG_ACCUMULATOR_STRUCTURAL of ACCUMULATOR is
	for STRUCTURAL
		for MUX_PART: MUX
			use configuration WORK.CFG_MUX_STRUCTURAL;
		end for;
		for ADDER: RCA_GENERIC 
			use configuration WORK.CFG_RCA_STRUCTURAL;
		end for;
		for REG: REGISTER_FD
			use configuration WORK.CFG_REGISTER_FD_SYNCHRONOUS;
		end for;
	end for;
end CFG_ACCUMULATOR_STRUCTURAL;

configuration CFG_ACCUMULATOR_BEHAVIORAL of ACCUMULATOR is
	for BEHAVIORAL
	end for;
end CFG_ACCUMULATOR_BEHAVIORAL;
