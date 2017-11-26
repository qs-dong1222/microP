library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;


entity Encode_Select is
generic(N_mul_operand : INTEGER);
port
(
  Encode_in : in STD_LOGIC_VECTOR(2 downto 0);
  Din4, Din3, Din2, Din1, Din0: in STD_LOGIC_VECTOR(2*N_mul_operand-1 downto 0);
  Dout : out STD_LOGIC_VECTOR(2*N_mul_operand-1 downto 0)
);
end Encode_Select;


architecture ES_arc of Encode_Select is
type Channels_type is (CH_0, CH_1, CH_2, CH_3, CH_4);
------------- internal signals ----------------
signal CH_sel : Channels_type;
-----------------------------------------------
begin
  
  encode_process:
  process(Encode_in, Din4, Din3, Din2, Din1, Din0)
  begin
    case Encode_in is
        when "000" =>   CH_sel <= CH_4;
        when "001" =>   CH_sel <= CH_3;
        when "010" =>   CH_sel <= CH_3;
        when "011" =>   CH_sel <= CH_1;
        when "100" =>   CH_sel <= CH_0;
        when "101" =>   CH_sel <= CH_2;
        when "110" =>   CH_sel <= CH_2;
        when "111" =>   CH_sel <= CH_4;
        when others =>   null;
    end case;
  end process;
  
  
  output_process:
  process(Encode_in, Din4, Din3, Din2, Din1, Din0, CH_sel)
  begin
    case CH_sel is
        when CH_0 =>   Dout <= Din0;  
        when CH_1 =>   Dout <= Din1;  
        when CH_2 =>   Dout <= Din2;
        when CH_3 =>   Dout <= Din3;
        when CH_4 =>   Dout <= Din4;
        when others =>   null;
    end case;
  end process;
  
    
end ES_arc;

