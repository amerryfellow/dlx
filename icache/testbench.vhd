library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use std.textio.all;
use work.cachepkg.all;

entity TBCACHE is
end TBCACHE;

architecture TB_1 of TBCACHE is

component IC_MEM 
	port(	
			clk            		: in std_logic;
			Reset						: in std_logic;  -- active high
			pc_addr					: in std_logic_vector(Instr_size - 1 downto 0);
			instr_from_mem			: in std_logic_vector(2*Instr_size - 1 downto 0);
			iram_ready				: in std_logic;
			enable					: in std_logic;
			stall_pipe				: out std_logic;
			read_mem					: out std_logic;
			addr_to_mem 			: out std_logic_vector(Instr_size - 1 downto 0);
			out_instr				: out std_logic_vector(Instr_size - 1 downto 0)
		 );
end component;

component IRAM 
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

end component;		


			
signal reset 												: std_logic;
signal CLK 													: std_logic := '1';
signal out_i,pc,Read_addr								: std_logic_vector(Instr_size-1 downto 0):=X"00000000" ;
signal addr_to_ir,instr_from_ir						: std_logic_vector(Instr_size-1 downto 0):=X"00000000" ;
signal mem_busy											: std_logic:= '0';
signal ST_PIPE												: std_logic := '1';
signal READ_M 												: std_logic:='0';
signal instr_from_m										: std_logic_vector(2*Instr_size - 1 downto 0);
signal ONE													: std_logic_vector(Instr_size-1 downto 0):=X"00000001";
signal IR_EN,en											: std_logic:= '0';
signal valid_out											: std_logic:= '0';

begin 
	reset <= '1' , '0' after 12 ns;
	
	
	--instr_from_m <= X"0001000F0001000A" after 25 ns;
	--mem_busy <= '1' after 20 ns, '0' after 30 ns;
	--pc <= X"00000002";--X"00000003" after 40 ns,X"00000004" after 60 ns,X"00000005" after 80 ns;
	en <= '1';--,'0' after 20 ns,'1' after 30 ns,'0' after 40 ns,'1' after 50 ns,'0' after 60 ns, '1' after 70 ns;
	
	p_clock: process (CLK)
		begin  -- process p_clock
			CLK <= not(CLK) after 10 ns;
 		end process p_clock;
	pc_ref:process
			begin
				pc <= X"00000002";
				wait until ST_PIPE = '0' and clk'event and clk='1';
				pc <= X"00000003";
				wait until ST_PIPE = '0' and clk'event and clk='1';
				pc <= X"00000004";
				wait until ST_PIPE = '0' and clk'event and clk='1';
				pc <= X"00000005";
				wait until ST_PIPE = '0' and clk'event and clk='1';
				pc <= X"00000006";
				wait until ST_PIPE = '0' and clk'event and clk='1';
				pc <= X"00000004";
				wait until ST_PIPE = '0' and clk'event and clk='1';
				pc <= X"00000002";
				wait for 20 ns;
		end process pc_ref;		
				
				
				
--	MMU_G			: MMU port map(CLK,reset,READ_M,read_addr,instr_from_ir,mem_busy,IR_EN,addr_to_ir,instr_from_m);
	IRAM_G		: IRAM port map(clk,reset,read_addr,READ_M,valid_out,instr_from_m);
	IC_MEM_G		: IC_MEM port map (CLK,reset,pc,instr_from_m,valid_out,en,ST_PIPE,READ_M,Read_addr,out_i);	
	
end TB_1;	
	