library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;


entity nor32to1 is
	port (
				A: in std_logic_vector(31 downto 0);
				Z: out std_logic
			);
end nor32to1;	

	
architecture behavioral of nor32to1 is			
signal stage1: std_logic_vector(15 downto 0);
signal stage2: std_logic_vector(7 downto 0);
signal stage3 : std_logic_vector(3 downto 0);
signal stage4: std_logic_vector(1 downto 0);

	component nor2to1
		port (
				A: in std_logic;
				B: in std_logic;
				Z: out std_logic
			);
	end component;
	
		component and2to1
		port (
				A: in std_logic;
				B: in std_logic;
				Z: out std_logic
			);
	end component;


begin

	FirstStage: 
		for i in 0 to 15 generate	
			NOR_STAGE: nor2to1 port map (A(2*i),A(2*i+1),stage1(i));
		end generate;
		
	SecondStage:
		for i in 0 to 7 generate	
			AND_STAGE: and2to1 port map (stage1(2*i),stage1(2*i+1),stage2(i));
		end generate;
		
	ThirdStage:
		for i in 0 to 3 generate	
			AND_STAGE: and2to1 port map (stage2(2*i),stage2(2*i+1),stage3(i));
		end generate;
	
	FourthStage:for i in 0 to 1 generate	
		AND_STAGE: and2to1 port map (stage3(2*i),stage3(2*i+1),stage4(i));
	end generate;
	
	OUTPUT: and2to1 port map (stage4(0), stage4(1), Z);
		
		
end behavioral;	