library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity RCA_generic is 
	generic (RCA_bits : INTEGER);
	Port 
	(	
	  A:	In	std_logic_vector(RCA_bits-1 downto 0);
		B:	In	std_logic_vector(RCA_bits-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(RCA_bits-1 downto 0);
		Co:	Out	std_logic
	);
end RCA_generic; 



architecture STRUCTURAL of RCA_generic is

  signal STMP : std_logic_vector(RCA_bits-1 downto 0);
  signal CTMP : std_logic_vector(RCA_bits downto 0);

  component FA 
  Port ( A:	In	std_logic;
	 B:	In	std_logic;
	 Ci:	In	std_logic;
	 S:	Out	std_logic;
	 Co:	Out	std_logic);
  end component; 

begin

  CTMP(0) <= Ci;
  S <= STMP;
  Co <= CTMP(RCA_bits);
  
  ADDER1: for I in 1 to RCA_bits generate
    FAI : FA 
	  Port Map (A(I-1), B(I-1), CTMP(I-1), STMP(I-1), CTMP(I)); 
  end generate;

end STRUCTURAL;
