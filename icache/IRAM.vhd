library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.cachepkg.all;


-- Instruction memory for DLX
-- Memory filled by a process which reads from a file
-- file name is "test.asm.mem"
entity IRAM is
	generic (
				RAM_DEPTH : integer := 48;
				I_SIZE : integer := 32);
	port (
			clk			: in std_logic;
			Rst  		: in  std_logic;
			Addr		   : in  std_logic_vector(I_SIZE - 1 downto 0);
			EN_IRAM		: in std_logic;
			Vout			: out std_logic;
			Dout 		: out std_logic_vector(2*I_SIZE - 1 downto 0)
		);

end IRAM;

architecture IRam_Bhe of IRAM is
	type RAMtype is array (0 to RAM_DEPTH - 1) of integer;	-- std_logic_vector(I_SIZE - 1 downto 0);
	signal IRAM_mem : RAMtype;
	signal valid : std_logic;
	signal idout : std_logic_vector(2*I_SIZE-1 downto 0);
begin  -- IRam_Bhe

	-- purpose: This process is in charge of filling the Instruction RAM with the firmware
	-- type   : combinational
	-- inputs : Rst
	-- outputs: IRAM_mem
	FILL_MEM_P: process (Rst)
		file mem_fp: text;
		variable file_line : line;
		variable index : integer := 0;
		variable tmp_data_u : std_logic_vector(I_SIZE-1 downto 0);
	begin  -- process FILL_MEM_P
		if (Rst = '1') then
			file_open(mem_fp,"/home/gandalf/Documents/Universita/Postgrad/Modules/Microelectronic/dlx/icache/hex.txt",READ_MODE);
			while (not endfile(mem_fp)) loop
				readline(mem_fp,file_line);
				hread(file_line,tmp_data_u);
				IRAM_mem(index) <= conv_integer(unsigned(tmp_data_u));
				index := index + 1;
			end loop;
		end if;
	end process FILL_MEM_P;

	state_updater : process
	begin
		wait until clk'event and clk = '1';
		valid <= '0';

		if rst = '1' then
			valid <= '0';
		elsif en_iram = '1' then
			wait until clk'event and clk = '1';
			wait until clk'event and clk = '1';
			valid <= '1';
			idout <=
				conv_std_logic_vector(IRAM_mem(conv_integer(unsigned(Addr))+1),I_SIZE) &
				conv_std_logic_vector(IRAM_mem(conv_integer(unsigned(Addr))),I_SIZE);
		end if;
	end process;

	Vout <= valid;
	Dout <= idout when valid = '1' else (others => 'Z');
end IRam_Bhe;
