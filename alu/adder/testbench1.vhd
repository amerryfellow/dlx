library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; -- we need a conversion to unsigned 

entity TB_P4ADDER is 
end TB_P4ADDER; 

architecture TEST of TB_P4ADDER is

  component LFSR16 
    port (CLK, RESET, LD, EN : in std_logic; 
          DIN : in std_logic_vector(15 downto 0); 
          PRN : out std_logic_vector(15 downto 0); 
          ZERO_D : out std_logic);
  end component;

  component P4ADDER
	port (
		A:	in	std_logic_vector(31 downto 0);
		B:	in	std_logic_vector(31 downto 0);
		C0: in std_logic;
		S:	out	std_logic_vector(31 downto 0);
		OVERFLOW: out std_logic
	
	);
  end component;
  

  constant Period: time := 20 ns; -- Clock period (1 GHz)
  signal CLK : std_logic :='0';
  signal RESET,LD,EN,ZERO_D : std_logic;
  signal DIN, PRN : std_logic_vector(15 downto 0);

  signal A, B, S1 : std_logic_vector(31 downto 0):=(others=>'0');
  signal C_out:std_logic;


Begin

-- Instanciate the ADDER without delay in the carry generation
  UADDER1: P4ADDER
	   port map (A, B,'0', S1,C_out);

-- Forcing adder input to LFSR output
  A <= x"001F" & PRN;
  B <= x"0000" & PRN;

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
    wait for (6560 * PERIOD);
  end process STIMULUS1;

end TEST;


