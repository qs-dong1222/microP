library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity CS_Block is 
generic(CSB_Nbr : INTEGER);
port
(
  A_Block : in STD_LOGIC_VECTOR(CSB_Nbr-1 downto 0);
  B_Block : in STD_LOGIC_VECTOR(CSB_Nbr-1 downto 0);
  Cin_Block : in STD_LOGIC;
  Sum_Block : out STD_LOGIC_VECTOR(CSB_Nbr-1 downto 0);
  Cout_Block : out STD_LOGIC
);
end CS_Block;



architecture STRUC of CS_Block is
-------------- internal components --------------
component RCA_generic is 
	generic (RCA_bits : INTEGER  -- generic number of bits of RCA_generic
	         );
	Port 
	(	
	  A:	In	std_logic_vector(RCA_bits-1 downto 0);
		B:	In	std_logic_vector(RCA_bits-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(RCA_bits-1 downto 0);
		Co:	Out	std_logic
	);
end component; 
-------------------------------------------------
---------------- internal signals ---------------
signal Sum_inter_1, Sum_inter_2 : STD_LOGIC_VECTOR(CSB_Nbr-1 downto 0);
signal Cout_inter_1, Cout_inter_2 : STD_LOGIC;
-------------------------------------------------

begin  

-------------- internal connection --------------
  CS_Block_Map1: RCA_generic generic map(RCA_bits=>CSB_Nbr)
  port map(A_Block, B_Block, '1', Sum_inter_1, Cout_inter_1);
    
  CS_Block_Map2: RCA_generic generic map(RCA_bits=>CSB_Nbr)
  port map(A_Block, B_Block, '0', Sum_inter_2, Cout_inter_2);
-------------------------------------------------  
  
  Sum_Block <= Sum_inter_1 when Cin_Block='1' else Sum_inter_2; 
  Cout_Block <= Cout_inter_1 when Cin_Block='1' else Cout_inter_2;
  
end STRUC;
