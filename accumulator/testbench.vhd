library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.constants.all;

entity ACC_tb is
end ACC_tb;

architecture TEST of ACC_tb is
	component ACCUMULATOR
		port (
			A          : in  std_logic_vector(numBit - 1 downto 0);
			B          : in  std_logic_vector(numBit - 1 downto 0);
			CLK        : in  std_logic;
			RST_n      : in  std_logic;
			ACCUMULATE : in  std_logic;
			--- ACC_EN_n   : in  std_logic;  -- optional use of the enable
			Y          : out std_logic_vector(numBit - 1 downto 0)
		);
	end component;

	signal A_i          : std_logic_vector(numBit - 1 downto 0);
	signal B_i          : std_logic_vector(numBit - 1 downto 0);
	signal CLK_i        : std_logic :='0' ;
	signal RST_n_i      : std_logic;
	signal ACCUMULATE_i : std_logic;
	--- signal ACC_EN_n_i   : std_logic; -- optional
	signal Y_i          : std_logic_vector(numBit - 1 downto 0);

	begin  -- TEST
		DUT: ACCUMULATOR
		port map (
			A          => A_i,
			B          => B_i,
			CLK        => CLK_i,
			RST_n      => RST_n_i,
			ACCUMULATE => ACCUMULATE_i,
			-- ACC_EN_n   => ACC_EN_n_i, -- optional
			Y          => Y_i
		);
		DUT_BEH:ACCUMULATOR
		port map (
			A          => A_i,
			B          => B_i,
			CLK        => CLK_i,
			RST_n      => RST_n_i,
			ACCUMULATE => ACCUMULATE_i,
			-- ACC_EN_n   => ACC_EN_n_i, -- optional
			Y          => Y_i
		);

		  
		p_clock: process (CLK_i)
		begin  -- process p_clock
			CLK_i <= not(CLK_i) after 0.5 ns;
 		end process p_clock;

		test: process
		begin  -- process test
			A_i          <= x"0000000000000001";
			B_i          <= x"0000000000000002";
			RST_n_i      <= '0';
		--	ACC_EN_i   <= '0';  -- optional
			ACCUMULATE_i <= '1';                  -- seleziona ingresso FEEDBACK del mux
			wait for 5 ns;

			-- Should obtain 0000000000000003

			A_i          <= x"0000000000000001";
			B_i          <= x"0000000000000009";
			RST_n_i      <= '0';
		--	ACC_EN_i   <= '0';  -- optional
			ACCUMULATE_i <= '1';                  -- seleziona ingresso FEEDBACK del mux
			wait for 5 ns;

			-- 000000000000000A

			A_i          <= x"00000000F1000002";
			B_i          <= x"000000000000000A";
			RST_n_i      <= '0';
		--	ACC_EN_i   <= '0';  -- optional
			ACCUMULATE_i <= '1';                  -- seleziona ingresso FEEDBACK del mux
			wait for 5 ns;

			-- 00000000F100000C

			A_i          <= x"E1E1E1E1E1E1E1E1";
			B_i          <= x"1E1E1E1E1E1E1E1E";
			RST_n_i      <= '0';
		--	ACC_EN_i   <= '0';  -- optional
			ACCUMULATE_i <= '1';                  -- seleziona ingresso FEEDBACK del mux
			wait for 5 ns;

			-- FFFFFFFFFFFFFFFF

			A_i          <= x"0000000000000010";
			B_i          <= x"1E1E1E1E1E1E1E1E";
			RST_n_i      <= '0';
		--	ACC_EN_i   <= '0';  -- optional
			ACCUMULATE_i <= '0';                  -- seleziona ingresso FEEDBACK del mux
			wait for 5 ns;

			-- 000000000000000F

			A_i          <= x"000000000F000010";
			B_i          <= x"1E1E1E1E1E1E1E1E";
			RST_n_i      <= '0';
		--	ACC_EN_i   <= '0';  -- optional
			ACCUMULATE_i <= '0';                  -- seleziona ingresso FEEDBACK del mux
			wait for 5 ns;

			A_i          <= x"0000000F00000010";
			B_i          <= x"1E1E1E1E1E1E1E1E";
			RST_n_i      <= '0';
		--	ACC_EN_i   <= '0';  -- optional
			ACCUMULATE_i <= '0';                  -- seleziona ingresso FEEDBACK del mux
			wait for 5 ns;

			A_i          <= x"0000F00000000010";
			B_i          <= x"1E1E1E1E1E1E1E1E";
			RST_n_i      <= '1';
		--	ACC_EN_i   <= '0';  -- optional
			ACCUMULATE_i <= '0';                  -- seleziona ingresso FEEDBACK del mux
			wait for 5 ns;
    
  end process test;

end TEST;

-------------------------------------------------------------------------------


configuration CFG_TESTACC of ACC_tb is
  for TEST
      for DUT : ACCUMULATOR
        use configuration WORK.CFG_ACCUMULATOR_STRUCTURAL;
	  	end for;
	  for DUT_BEH:ACCUMULATOR
        use configuration WORK.CFG_ACCUMULATOR_BEHAVIORAL;
	  end for;
end for;
end CFG_TESTACC;
