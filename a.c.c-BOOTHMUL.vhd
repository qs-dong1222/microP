library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;


entity BOOTHMUL is
generic(N_mul_operand : INTEGER);
port
(
  Ain, Bin : in integer;
  MUL_result : out integer
);
end BOOTHMUL;


architecture BOOTH_arc of BOOTHMUL is
  
  type Dout_vec_type is array(INTEGER range <>) of STD_LOGIC_VECTOR(2*N_mul_operand-1 downto 0);
  
  ---------- internal component -------------
  component Encode_Select is
  generic(N_mul_operand : INTEGER);
  port
  (
    Encode_in : in STD_LOGIC_VECTOR(2 downto 0);
    Din4, Din3, Din2, Din1, Din0: in STD_LOGIC_VECTOR(2*N_mul_operand-1 downto 0);
    Dout : out STD_LOGIC_VECTOR(2*N_mul_operand-1 downto 0)
  );
  end component;
  
  
  component CS_Block is 
  generic(CSB_Nbr : INTEGER);
  port
  (
    A_Block : in STD_LOGIC_VECTOR(CSB_Nbr-1 downto 0);
    B_Block : in STD_LOGIC_VECTOR(CSB_Nbr-1 downto 0);
    Cin_Block : in STD_LOGIC;
    Sum_Block : out STD_LOGIC_VECTOR(CSB_Nbr-1 downto 0);
    Cout_Block : out STD_LOGIC
  );
  end component;
  -------------------------------------------
  --------- internal signals ----------------
  signal Dout_vec : Dout_vec_type(N_mul_operand/2-1 downto 0);
  signal Bin_ext0 : STD_LOGIC_VECTOR(N_mul_operand downto 0);
  signal Din : Dout_vec_type(5*(N_mul_operand/2)-1 downto 0);
  signal SumOut : Dout_vec_type(N_mul_operand/2-2 downto 0);
  signal CarryOut : STD_LOGIC_VECTOR(N_mul_operand/2-2 downto 0);
  -------------------------------------------
begin
  Bin_ext0 <= std_logic_vector(to_signed(Bin, N_mul_operand)) & '0';
  
  aaa: for i in 0 to N_mul_operand/2-1 generate  
          Din(5*i) <= std_logic_vector(to_signed(Ain*(-2)*(4**i), 2*N_mul_operand));
          Din(5*i+1) <= std_logic_vector(to_signed(Ain*(2)*(4**i), 2*N_mul_operand));
          Din(5*i+2) <= std_logic_vector(to_signed(Ain*(-1)*(4**i), 2*N_mul_operand));
          Din(5*i+3) <= std_logic_vector(to_signed(Ain*(1)*(4**i), 2*N_mul_operand));
          Din(5*i+4) <= (others=>'0');
       end generate aaa;
       
       
  gen: for i in 0 to N_mul_operand/2-1 generate        
          map_i: Encode_Select generic map(N_mul_operand=>N_mul_operand)
                 port map(Encode_in=>Bin_ext0(2*i+2 downto 2*i)
                        , Din4=>Din(5*i+4)                           
                        , Din3=>Din(5*i+3)
                        , Din2=>Din(5*i+2)
                        , Din1=>Din(5*i+1)
                        , Din0=>Din(5*i)
                        , Dout=>Dout_vec(i) );
       end generate gen;
       
  
  nnn: CS_Block generic map(CSB_Nbr=>(2*N_mul_operand)) 
       port map(A_Block=>Dout_vec(0)
              , B_Block=>Dout_vec(1)
              , Cin_Block=>'0'
              , Sum_Block=>SumOut(0)
              , Cout_Block=>CarryOut(0) ); 
         
         
  sum_i: for i in 1 to N_mul_operand/2-2 generate
         ccc: CS_Block generic map(CSB_Nbr=>(2*N_mul_operand)) 
              port map(A_Block=>SumOut(i-1)
                     , B_Block=>Dout_vec(i+1)
                     , Cin_Block=>'0'
                     , Sum_Block=>SumOut(i)
                     , Cout_Block=>CarryOut(i)
                     );
        end generate;   
        
     MUL_result <= to_integer(signed(SumOut(N_mul_operand/2-2)));        
  
end BOOTH_arc;
