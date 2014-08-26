library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use WORK.alu_types.all;

entity ALU is
	generic (
		N : integer := NSUMG
	);
	
	port (
		FUNC:					in std_logic_vector(alu_control_word - 1 downto 0);
		A, B:					in std_logic_vector(N-1 downto 0);
		CLK: 					in std_logic;
		RESET: 				in std_logic;
		EN:						in std_logic;
		OUTALU:				out std_logic_vector(N-1 downto 0)
	);
end ALU;

architecture DLX_ALU of ALU is
	
	component P4ADDER
		generic(N:integer:=NSUMG);
	
		port (
			A:		in 	std_logic_vector(N-1 downto 0);
			B:		in 	std_logic_vector(N-1 downto 0);
			Cin:	in 	std_logic;
			S:		out std_logic_vector(N-1 downto 0);
			Cout:	out std_logic
		);
	end component;
	
	component LATCH
		generic (
		N: integer:= NSUMG
	);
	port (
		DIN:	in	std_logic_vector(N-1 downto 0);		-- Data in
		EN:		in std_logic;
		DOUT:	out	std_logic_vector(N-1 downto 0)		-- Data out
	);
	end component;
	
	component COMPARATOR 
		generic(N:integer:=NSUMG);

		port(
			SUM:	in std_logic_vector(N-1 downto 0);
			Cout:	in std_logic;
			ALEB: out std_logic;
			ALB:	out std_logic;
			AGB:	out std_logic;
			AGEB: out std_logic;
			ANEB:	out std_logic;
			AEB:	out std_logic
		);
	end component;
	
	component T2logic 
		generic(N:integer:=NSUMG);
		
		port(
			R1 : 		in std_logic_vector(N-1 downto 0);
			R2 : 		in std_logic_vector(N-1 downto 0);
			S1	:		in std_logic;
			S2	: 	in std_logic;
			S3	: 	in std_logic;
			L_OUT : out std_logic_vector(N-1 downto 0)
		);
		end component;
	
	
	component bshift    -- barrel shifter
			generic(N:integer:=NSUMG);
      port (
				direction : 	in  std_logic; -- '1' for left, '0' for right
        logical : 		in  std_logic; -- '1' for logical, '0' for arithmetic
        shift   :			in  std_logic_vector(4 downto 0);  -- shift count
        input   : 		in  std_logic_vector (N-1 downto 0);
        output  : 		out std_logic_vector (N-1 downto 0) 
				);
	end component;
	
	
	
	component REGISTER_FD 
		generic (N: integer:= NSUMG);
	
		port (
			DIN:		in	std_logic_vector(N-1 downto 0);		-- Data in
			CLK:			in	std_logic;							-- Clock
			RESET:	in	std_logic;							-- Reset
			DOUT:		out	std_logic_vector(N-1 downto 0)		-- Data out
	);
	end component; 
	
	component BOOTHMUL 
	generic (
		N	: integer := NSUMG
	);
	port (
		A	: in	std_logic_vector(N-1 downto 0);
		B	: in	std_logic_vector(N-1 downto 0);
		P	: out	std_logic_vector(2*N-1 downto 0)
	);
	end component;
	
	component MUX5TO1 
	generic (
		N:			integer	:= NSUMG		-- Number of bits
	
	);
	
	port (
		A:		in	std_logic_vector(N-1 downto 0);
		B:		in	std_logic_vector(N-1 downto 0);
		C:		in	std_logic_vector(N-1 downto 0);
		D:		in	std_logic_vector(N-1 downto 0);
		F:		in	std_logic_vector(N-1 downto 0);
		SEL:	in	std_logic_vector(2 downto 0);
		Y:		out	std_logic_vector(N-1 downto 0)
	);
	end component;
	
	
	
	signal logical:					std_logic;
	signal s_depth:					std_logic_vector(4 downto 0);
	signal dir:							std_logic;
	signal MUL_A:						std_logic_vector(N-1 downto 0);
	signal MUL_B:						std_logic_vector(N-1 downto 0);
	signal logic_A:					std_logic_vector(N-1 downto 0);
	signal logic_B:					std_logic_vector(N-1 downto 0);
	signal int_A:						std_logic_vector(N-1 downto 0);
	signal shift_A:					std_logic_vector(N-1 downto 0);
	signal int_B:						std_logic_vector(N-1 downto 0);
	signal Cin : 						std_logic:='0';
	signal S1,S2,S3: 				std_logic:='0';
	signal cout: 						std_logic;
	signal flag_reg: 				std_logic_vector(N-1 downto 0);
	signal int_SUM: 				std_logic_vector(N-1 downto 0);
	signal MUL_LSB,L_OUT:		std_logic_vector(N-1 downto 0);
	signal shift_out:				std_logic_vector(N-1 downto 0);
	signal MUL_OUT:					std_logic_vector(2*N-1 downto 0);
	signal MUX_SEL:					std_logic_vector(2 downto 0);
	signal preout:					std_logic_vector(N-1 downto 0);
	
	begin
		P_ALU : process (FUNC, A, B)
		begin
			case FUNC is
				when ADD		=> int_A <= A;
											 int_B <= B;
											 Cin <= '0';
											 MUX_SEL <= "000";
											 
				when SUBB		=> int_A <= A;
											 int_B <= not B;
											 Cin <= '1';
											 MUX_SEL <= "000";
											 
				when MULT		=> MUL_A <= A;
											 MUL_B <= B;
											 MUX_SEL <= "100";
				-- Bitwise
				when BITAND		=> logic_A <= A;
												 logic_B <= B;
												 S1 <= '0';
												 S2 <= '0';
												 S3 <= '1';
												 MUX_SEL <= "001";
												 
				when BITOR		=> logic_A <= A;
												 logic_B <= B;
												 S1 <= '1';
												 S2 <= '1';
												 S3 <= '1';
												 MUX_SEL <= "001";
												 
				when BITXOR		=> logic_A <= A;
												 logic_B <= B;
												 S1 <= '1';
												 S2 <= '1';
												 S3 <= '0';
												 MUX_SEL <= "001";
												 
				when FUNCSLL	=>	shift_A <= A;
													s_depth <= B(4 downto 0);
													dir <= '1';
													logical <= '1';
													MUX_SEL <= "011";
													
				when FUNCSRL	=> 	shift_A <= A;
													s_depth <= B(4 downto 0);
													dir <= '0';
													logical <= '1';
													MUX_SEL <= "011";
													 
				when FUNCSRA	=>	shift_A <= A;
													s_depth <= B(4 downto 0);
													dir <= '0';
													logical <= '0';
													MUX_SEL <= "011";
													
				when COMP			=> 	int_A <= A;
													int_B <= not B;
													Cin <= '1';
													MUX_SEL <= "010";
													
				when others		=> null;
			end case; 
		end process;
	--	report integer'image(A) & string'(" - ") & integer'image(A_IN) & string'(" => ") & integer'image(result);
		ADDER: 			P4ADDER port map (int_A,int_B,cin,int_SUM,cout);
	--report integer'image(A) & string'(" - ") & integer'image(A_IN) & string'(" => ") & integer'image(int_SUM);
		LOGIC: 			t2logic port map (logic_A,logic_B,S1,S2,S3,L_OUT);
		COMPARE:		comparator port map	(int_SUM,cout,flag_reg(0),flag_reg(1),flag_reg(2),flag_reg(3),flag_reg(4),flag_reg(5));
		flag_reg(6) <= cout nand cin; --overflow flag
		flag_reg(N-1 downto 7) <= (others => '0');
		SHIFTER:		bshift port map (dir,logical,s_depth,shift_A,shift_out);
		MULTIPLIER:	BOOTHMUL port map	(MUL_A,MUL_B,MUL_OUT);
		MUL_LSB <= MUL_OUT(N-1 downto 0);
		MULTIPLEXER: MUX5TO1 port map(int_SUM,L_OUT,flag_reg,shift_out,MUL_LSB,MUX_SEL,preout);
		--OUTPUT: REGISTER_FD port map (preout,CLK,RESET,OUTALU);
		OUTPUT: LATCH port map (preout,EN,OUTALU);
		
end DLX_ALU; 


