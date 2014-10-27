library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use WORK.alu_types.all;

entity T2logic is
	generic(N:integer:=NSUMG);
	
	port(
		R1 : in std_logic_vector(N-1 downto 0);
		R2 : in std_logic_vector(N-1 downto 0);
		S1	: in std_logic;
		S2	: in std_logic;
		S3	: in std_logic;
		L_OUT : out std_logic_vector(N-1 downto 0)
		);
		
end T2logic;

architecture structural of T2logic is

signal NEG_R1:std_logic_vector(N-1 downto 0);
signal NEG_R2:std_logic_vector(N-1 downto 0);
signal L1,L2,L3:std_logic_vector(N-1 downto 0);
signal L_temp:std_logic_vector(N-1 downto 0);

component nand3to1 
	port(
		R1 : in std_logic_vector(N-1 downto 0);
		R2 : in std_logic_vector(N-1 downto 0);
		S  : in std_logic;
		L  : out std_logic_vector(N-1 downto 0)
		);
end component;

begin

-- LUT:	S1	S2	S3		OUT
--			0		0		1			R1 and R2
--			1		1		1			R1 or  R2
--			1		1		0 		R1 xor R2	

neg_R1 <= not R1;
neg_R2 <= not R2;

L1_GEN : nand3to1 port map (neg_R1,R2,S1,L1); 
L2_GEN : nand3to1 port map (R1,neg_R2,S2,L2);
L3_GEN : nand3to1 port map (R1,R2,S3,L3);

L_OUT_TEMP:  nand3to1 port map (L1,L2,'1',L_temp);

L_OUT_GEN: 
		for i in 0 to N-1 generate
			L_OUT(i) <= L_temp(i) or (not L3(i));
		end generate;



end structural;
	   