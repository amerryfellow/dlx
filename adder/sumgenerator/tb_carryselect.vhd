library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; -- we need a conversion to unsigned 

entity TBCARRYSELECT is 
end TBCARRYSELECT; 

architecture TEST of TBCARRYSELECT is

  component LFSR16 
    port (CLK, RESET, LD, EN : in std_logic; 
          DIN : in std_logic_vector(15 downto 0); 
          PRN : out std_logic_vector(15 downto 0); 
          ZERO_D : out std_logic);
  end component;

  component CARRYSELECT
	generic(
		NBIT:integer:=32;
		NCSB:integer:=8
	);
	port (
		A:	in	std_logic_vector(NBIT-1 downto 0);
		B:	in	std_logic_vector(NBIT-1 downto 0);
		Ci:	in	std_logic_vector(NCSB-1 downto 0);
		S:	out	std_logic_vector(NBIT-1 downto 0)
	
	);
  end component;
  

  constant Period: time := 1 ns; -- Clock period (1 GHz)
  signal CLK : std_logic :='0';
  signal RESET,LD,EN,ZERO_D : std_logic;
  signal DIN, PRN : std_logic_vector(15 downto 0);

  signal A, B, S1 : std_logic_vector(31 downto 0);
  signal Ci: std_logic_vector(7 downto 0);

Begin

-- Instanciate the ADDER without delay in the carry generation
  UADDER1: CARRYSELECT
	   port map (A, B, Ci, S1);

-- Forcing adder input to LFSR output
  Ci <= x"F0";
  A <= PRN & PRN;
  B <= not(PRN) & PRN;

-- Instanciate the Unit Under Test (UUT)
  UUT: LFSR16 port map (CLK=>CLK, RESET=>RESET, LD=>LD, EN=>EN, 
                        DIN=>DIN,PRN=>PRN, ZERO_D=>ZERO_D);
-- Create the permanent Clock and the Reset pulse
  CLK <= not CLK after Period/2;
  RESET <= '1', '0' after Period;
-- Open file, make a load, and wait for a timeout in case of design error.
  STIMULUS1: process
  begin
    DIN <= "0000000000000001";
    EN <='1';
    LD <='1';
    wait for 2 * PERIOD;
    LD <='0';
    wait for (65600 * PERIOD);
  end process STIMULUS1;

end TEST;

configuration RCATEST of TBCARRYSELECT is
  for TEST
    for UADDER1: CARRYSELECT
      use configuration WORK.CFG_CARRYSELECT;
    end for;
  end for;
end RCATEST; 
