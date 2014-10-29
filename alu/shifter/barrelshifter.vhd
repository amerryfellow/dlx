library IEEE;
use IEEE.std_logic_1164.all;
use WORK.alu_types.all;

Entity bshift is   -- barrel shifter
			generic(N:integer:=NSUMG);
      port (
				direction 	: 	in  std_logic; -- '1' for left, '0' for right
            logical 		:	in  std_logic; -- '1' for logical, '0' for arithmetic
            shift   		:	in  std_logic_vector(4 downto 0);  -- shift count
            input   		: 	in  std_logic_vector (N-1 downto 0);
            output  		: 	out std_logic_vector (N-1 downto 0) 
				);
end entity bshift;

architecture circuits of bshift is
  signal LRT	: std_logic_vector(N-1 downto 0);
  signal L1s  	: std_logic_vector(N-1 downto 0);
  signal L2s  	: std_logic_vector(N-1 downto 0);
  signal L4s  	: std_logic_vector(N-1 downto 0);
  signal L8s  	: std_logic_vector(N-1 downto 0);
  signal L16s 	: std_logic_vector(N-1 downto 0);
  signal L1   	: std_logic_vector(N-1 downto 0);
  signal L2   	: std_logic_vector(N-1 downto 0);
  signal L4   	: std_logic_vector(N-1 downto 0);
  signal L8   	: std_logic_vector(N-1 downto 0);
  signal L16  	: std_logic_vector(N-1 downto 0);
  signal R1s  	: std_logic_vector(N-1 downto 0);
  signal R2s  	: std_logic_vector(N-1 downto 0);
  signal R4s  	: std_logic_vector(N-1 downto 0);
  signal R8s  	: std_logic_vector(N-1 downto 0);
  signal R16s 	: std_logic_vector(N-1 downto 0);
  signal R1   	: std_logic_vector(N-1 downto 0);
  signal R2   	: std_logic_vector(N-1 downto 0);
  signal R4   	: std_logic_vector(N-1 downto 0);
  signal R8   	: std_logic_vector(N-1 downto 0);
  signal R16  	: std_logic_vector(N-1 downto 0);
  signal A1s  	: std_logic_vector(N-1 downto 0);
  signal A2s  	: std_logic_vector(N-1 downto 0);
  signal A4s  	: std_logic_vector(N-1 downto 0);
  signal A8s  	: std_logic_vector(N-1 downto 0);
  signal A16s 	: std_logic_vector(N-1 downto 0);
  signal A1   	: std_logic_vector(N-1 downto 0);
  signal A2   	: std_logic_vector(N-1 downto 0);
  signal A4   	: std_logic_vector(N-1 downto 0);
  signal A8   	: std_logic_vector(N-1 downto 0);
  signal A16  	: std_logic_vector(N-1 downto 0);
  signal input2s : std_logic_vector(1 downto 0);
  signal input4s : std_logic_vector(3 downto 0);
  signal input8s : std_logic_vector(7 downto 0);
  signal input16s : std_logic_vector(15 downto 0);

  component MUX
     generic (
		N:			integer	:= NSUMG -- Number of bits
	
	);
	
	port (
		A:		in	std_logic_vector(N-1 downto 0);
		B:		in	std_logic_vector(N-1 downto 0);
		SEL:	in	std_logic;
		Y:		out	std_logic_vector(N-1 downto 0)
	);
  end component;
begin  -- circuits
	---				SHIFT LEFT LOGICAL
  L1w:  L1s <= input(30 downto 0) & '0'; -- just wiring
  L1m:  MUX port map (A=>input, B=>L1s, SEL=> shift(0), Y=>L1);
  L2w:  L2s <= L1(29 downto 0) & "00"; -- just wiring
  L2m:  MUX port map (A=>L1, B=>L2S, SEL=>shift(1), Y=>L2);
  L4w:  L4s <= L2(27 downto 0) & "0000"; -- just wiring
  L4m:  MUX port map (A=>L2, B=>L4s, SEL=>shift(2), Y=>L4);
  L8w:  L8s <= L4(23 downto 0) & "00000000"; -- just wiring
  L8m:  MUX port map (A=>L4, B=>L8s, SEL=>shift(3), Y=>L8);
  L16w: L16s <= L8(15 downto 0) & "0000000000000000"; -- just wiring
  L16m: MUX port map (A=>L8, B=>L16s, SEL=>shift(4), Y=>L16);
  ---				SHIFT RIGHT LOGICAL
  R1w:  R1s <= '0' & input(N-1 downto 1); -- just wiring
  R1m:  MUX port map (A=>input, B=>R1s, SEL=>shift(0), Y=>R1);
  R2w:  R2s <= "00" & R1(N-1 downto 2); -- just wiring
  R2m:  MUX port map (A=>R1, B=>R2s, SEL=>shift(1), Y=>R2);
  R4w:  R4s <= "0000" & R2(N-1 downto 4); -- just wiring
  R4m:  MUX port map (A=>R2, B=>R4s, SEL=>shift(2), Y=>R4);
  R8w:  R8s <= "00000000" & R4(N-1 downto 8); -- just wiring
  R8m:  MUX port map (A=>R4, B=>R8s, SEL=>shift(3), Y=>R8);
  R16w: R16s <= "0000000000000000" & R8(N-1 downto 16); -- just wiring
  R16m: MUX port map (A=>R8, B=>R16s, SEL=>shift(4), Y=>R16);
  ---				SHIFT RIGHT ARTHIMETICAL
  A1w:  A1s <= input(N-1)&input(N-1 downto 1); -- just wiring
  A1m:  MUX port map (A=>input, B=>A1s, SEL=>shift(0), Y=>A1);
  A2w:  A2s <= input2s&A1(N-1 downto 2);    -- just wiring
  A2m:  MUX port map (A=>A1, B=>A2s, SEL=>shift(1), Y=>A2);
  A4w:  A4s <= input4s&A2(N-1 downto 4);    -- just wiring
  A4m:  MUX port map (A=>A2, B=>A4s, SEL=>shift(2), Y=>A4);
  A8w:  A8s <= input8s&A4(N-1 downto 8);    -- just wiring
  A8m:  MUX port map (A=>A4, B=>A8s, SEL=>shift(3), Y=>A8);
  A16w: A16s <= input16s&A8(N-1 downto 16); -- just wiring
  A16m: MUX port map (A=>A8, B=>A16s, SEL=>shift(4), Y=>A16);
  AS2:  input2s <= input(N-1) & input(N-1);  -- just wiring
  AS4:  input4s <= input2s & input2s;      -- just wiring
  AS8:  input8s <= input4s & input4s;      -- just wiring
  AS16: input16s <= input8s & input8s;     -- just wiring
	-- 					TO THE OUTPUT
  SLR:  MUX port map (A=>R16, B=>L16, SEL=>direction, Y=>LRT);
  LOG:  MUX port map (A=>A16, B=>LRT, SEL=>logical, Y=>output);
end architecture circuits;  -- of bshift
