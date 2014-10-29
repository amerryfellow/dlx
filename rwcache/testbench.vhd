library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use std.textio.all;
use work.RWCACHE_PKG.all;

entity TBCACHE is
end TBCACHE;

architecture TB_1 of TBCACHE is

component RWCACHE is
	port (
		CLK						: in std_logic;
		RST						: in std_logic;  -- active high
		ENABLE					: in std_logic;
		READNOTWRITE			: in std_logic;
		ADDRESS					: in std_logic_vector(DATA_SIZE - 1 downto 0);
		INOUT_DATA				: inout std_logic_vector(DATA_SIZE - 1 downto 0);
		STALL					: out std_logic;
		RAM_ISSUE				: out std_logic;
		RAM_READNOTWRITE		: out std_logic;
		RAM_ADDRESS				: out std_logic_vector(DATA_SIZE - 1 downto 0);
		RAM_DATA				: inout std_logic_vector(2*DATA_SIZE - 1 downto 0);
		RAM_READY				: in std_logic
	);
end component;

component ROMEM is
	generic (
		ENTRIES		: integer := 48;
		WORD_SIZE	: integer := 32
	);
	port (
		CLK					: in std_logic;
		RST					: in std_logic;
		ADDRESS				: in std_logic_vector(WORD_SIZE - 1 downto 0);
		ENABLE				: in std_logic;
		DATA_READY			: out std_logic;
		DATA				: inout std_logic_vector(2*WORD_SIZE - 1 downto 0)
	);
end component;

signal	CLK						: std_logic := '0';
signal	RST						: std_logic;  -- active high
signal	ENABLE					: std_logic;
signal	READNOTWRITE			: std_logic;
signal	ADDRESS					: std_logic_vector(DATA_SIZE - 1 downto 0);
signal	INOUT_DATA				: std_logic_vector(DATA_SIZE - 1 downto 0);
signal	STALL					: std_logic;
signal	RAM_ISSUE				: std_logic;
signal	RAM_READNOTWRITE		: std_logic;
signal	RAM_ADDRESS				: std_logic_vector(DATA_SIZE - 1 downto 0);
signal	RAM_DATA				: std_logic_vector(2*DATA_SIZE - 1 downto 0);
signal	RAM_READY				: std_logic;

begin
	RST <= '1' , '0' after 1 ns;
	--instr_from_m <= X"0001000F0001000A" after 25 ns;
	--mem_busy <= '1' after 20 ns, '0' after 30 ns;
	--pc <= X"00000002";--X"00000003" after 40 ns,X"00000004" after 60 ns,X"00000005" after 80 ns;
	ENABLE <= '1';--,'0' after 20 ns,'1' after 30 ns,'0' after 40 ns,'1' after 50 ns,'0' after 60 ns, '1' after 70 ns;

	p_clock: process (CLK)
		begin  -- process p_clock
			CLK <= not(CLK) after 10 ns;
	end process p_clock;

	pc_ref:process
			begin
--				READNOTWRITE <= '1';
--				ADDRESS <= X"00000002";
--				INOUT_DATA <= (others => 'Z');
--				wait until STALL = '0' and clk'event and clk='1';
--				ADDRESS <= X"00000003";
--				wait until STALL = '0' and clk'event and clk='1';
--				ADDRESS <= X"00000004";
--				wait until STALL = '0' and clk'event and clk='1';
--				ADDRESS <= X"00000005";

--				wait until STALL = '0' and clk'event and clk='1';
				READNOTWRITE <= '0';
				ADDRESS <= X"00000002";
				INOUT_DATA <= X"AABBCCDD";
				wait until STALL = '0' and clk'event and clk='1';
				INOUT_DATA <= (others => 'Z');
				READNOTWRITE <= '1';
				ADDRESS <= X"00000003";
				wait until STALL = '0' and clk'event and clk='1';
				ADDRESS <= X"00000002";
				wait until STALL = '0' and clk'event and clk='1';
				READNOTWRITE <= '0';
				ADDRESS <= X"00000003";
				INOUT_DATA <= X"FFEEFFEE";
				wait until STALL = '0' and clk'event and clk='1';
				INOUT_DATA <= (others => 'Z');
				READNOTWRITE <= '1';
				ADDRESS <= X"00000002";
				wait until STALL = '0' and clk'event and clk='1';
				ADDRESS <= X"00000003";
		end process pc_ref;

	IRAM_G		: ROMEM port map(CLK, RST, RAM_ADDRESS, RAM_ISSUE, RAM_READY, RAM_DATA);
	IC_MEM_G	: RWCACHE port map (CLK, RST, ENABLE, READNOTWRITE, ADDRESS, INOUT_DATA, STALL, RAM_ISSUE, RAM_READNOTWRITE, RAM_ADDRESS, RAM_DATA, RAM_READY);

end TB_1;

