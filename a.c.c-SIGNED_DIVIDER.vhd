library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity DIVIDER is
generic(N_div : INTEGER);
port
(
  CLK, START : in STD_LOGIC;
  DONE : buffer STD_LOGIC;
  DIVIDEND, DIVISOR : in integer;
  QUOTIENT, RESIDUAL : out integer 
);
end DIVIDER;

architecture asd of DIVIDER is
------------ internal signals -------------
signal DIVIDEND_slv, DIVISOR_slv : STD_LOGIC_VECTOR(N_div-1 downto 0);
signal QUOTIENT_slv, RESIDUAL_slv : STD_LOGIC_VECTOR(N_div-1 downto 0);
signal QUOTIENT_inter, ZERO: STD_LOGIC_VECTOR(N_div-1 downto 0);
signal RESI_ES : STD_LOGIC_VECTOR(2*N_div downto 0);
signal RESIDUAL_inter, DIVISOR_inter : STD_LOGIC_VECTOR(2*N_div-1 downto 0);
signal count : INTEGER;
------------------------------------------- 
begin
 
  prepare_proc:
  process(START, DIVIDEND, DIVISOR, QUOTIENT_slv, RESIDUAL_slv)
  begin  
    if (DIVIDEND > 0 and DIVISOR < 0) then
      DIVIDEND_slv <= conv_std_logic_vector(DIVIDEND, N_div);
      DIVISOR_slv  <= conv_std_logic_vector(-DIVISOR, N_div);
      QUOTIENT <= - conv_integer(signed(QUOTIENT_slv));
      RESIDUAL <= - conv_integer(signed(RESIDUAL_slv));
    elsif (DIVIDEND < 0 and DIVISOR > 0) then
      DIVIDEND_slv <= conv_std_logic_vector(-DIVIDEND, N_div);
      DIVISOR_slv  <= conv_std_logic_vector(DIVISOR, N_div);
      QUOTIENT <= - conv_integer(signed(QUOTIENT_slv));
      RESIDUAL <= - conv_integer(signed(RESIDUAL_slv));
    elsif (DIVIDEND < 0 and DIVISOR < 0) then
      DIVIDEND_slv <= conv_std_logic_vector(-DIVIDEND, N_div);
      DIVISOR_slv  <= conv_std_logic_vector(-DIVISOR, N_div);
      QUOTIENT <= conv_integer(signed(QUOTIENT_slv));
      RESIDUAL <= conv_integer(signed(RESIDUAL_slv));
    else
      DIVIDEND_slv <= conv_std_logic_vector(DIVIDEND, N_div);
      DIVISOR_slv  <= conv_std_logic_vector(DIVISOR, N_div);
      QUOTIENT <= conv_integer(signed(QUOTIENT_slv));
      RESIDUAL <= conv_integer(signed(RESIDUAL_slv));
    end if;
  end process;
  
  
  
  
  ZERO <= (others=>'0');
  DIVISOR_inter <= ( (not DIVISOR_slv) + 1 ) & ZERO;
  RESI_ES <= ('0' & RESIDUAL_inter) + ('0' & DIVISOR_inter);
  
  DIVcalcProcess : 
   process(CLK, START)--(CLK, START, DIVISOR, DIVIDEND)
   begin
     if rising_edge(START) then  
        RESIDUAL_inter <= ZERO(N_div-2 downto 0) & DIVIDEND_slv & '0';                      
        QUOTIENT_inter <= (others=>'0');
        QUOTIENT_slv <= (others=>'0');
        RESIDUAL_slv <= (others=>'0');
        count <= 0;
        DONE <= '0';
        
        
     elsif rising_edge(CLK) and (count /= N_div) then
        QUOTIENT_inter <= QUOTIENT_inter(N_div-2 downto 0) & (RESI_ES(2*N_div));
        count <= count + 1;
        
        case RESI_ES(2*N_div) is
          when '0' =>  RESIDUAL_inter <= (RESIDUAL_inter(2*N_div-2 downto 0) & '0');
          when '1' =>  RESIDUAL_inter <= (RESI_ES(2*N_div-2 downto 0) & '0');
          when others =>  null;
        end case;
  
     elsif rising_edge(CLK) and (count = N_div) then
        DONE <= '1';
        QUOTIENT_slv <= QUOTIENT_inter;
        RESIDUAL_slv <= '0' & RESIDUAL_inter(2*N_div-1 downto N_div+1); -- left shift in previous step, recover it in the end.
     end if; 
   end process;


end asd;



