library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.type_pkg.all;

package func_pkg is
function log2 (Arg : positive) return natural;
function hex_to_slv( hex : string ) return std_logic_vector; 
function AnalyzeIns (OPCODE : std_logic_vector(5 downto 0); FUNC : std_logic_vector(10 downto 0)) return INSTRUCTION_type;   
end package func_pkg;



package body func_pkg is 
 
 ----------- log based on 2 --------------   
function log2 (Arg : positive) return natural is
  variable temp    : integer := Arg;
  variable ret_val : integer := 0; --log2 of 0 should equal 1 because you still need 1 bit to represent 0
  begin     
  while temp > 0 loop
    ret_val := ret_val + 1;
    temp    := temp / 2;  
  end loop;
  return (ret_val-1);
end function log2;


 --------- convert hex to std_logic_vector ----------
function hex_to_slv( hex : string ) return std_logic_vector is
	variable r : std_logic_vector( hex'length * 4 - 1 downto 0);
	begin
		for i in 1 to hex'high loop
			case hex(i) is
			   when 'F'|'f'=> r(4*i-1 downto 4*i-4):="1111";
			   when 'E'|'e'=> r(4*i-1 downto 4*i-4):="1110";
			   when 'D'|'d'=> r(4*i-1 downto 4*i-4):="1101";
			   when 'C'|'c'=> r(4*i-1 downto 4*i-4):="1100";
			   when 'B'|'b'=> r(4*i-1 downto 4*i-4):="1011";
			   when 'A'|'a'=> r(4*i-1 downto 4*i-4):="1010";
			   when '9'=> r(4*i-1 downto 4*i-4):="1001";
			   when '8'=> r(4*i-1 downto 4*i-4):="1000";
			   when '7'=> r(4*i-1 downto 4*i-4):="0111";
			   when '6'=> r(4*i-1 downto 4*i-4):="0110";
			   when '5'=> r(4*i-1 downto 4*i-4):="0101";
			   when '4'=> r(4*i-1 downto 4*i-4):="0100";
			   when '3'=> r(4*i-1 downto 4*i-4):="0011";
			   when '2'=> r(4*i-1 downto 4*i-4):="0010";
			   when '1'=> r(4*i-1 downto 4*i-4):="0001";
			   when '0'=> r(4*i-1 downto 4*i-4):="0000";
			   when others=> NULL;
			end case;
		end loop ;
		return r ;
end function hex_to_slv;




 --------- analyze on OPCODE & FUNC ----------
function AnalyzeIns (OPCODE : std_logic_vector(5 downto 0); FUNC : std_logic_vector(10 downto 0)) return INSTRUCTION_type is

  variable instrction : INSTRUCTION_type;
  
  begin
  --**************************************************************--
  case OPCODE is
     ---------------------- R-type --------------------------
     when "000000" => 
         case FUNC is
            when "00000000100"=>   instrction := INS_sll;
            when "00000000110"=>   instrction := INS_srl;
            when "00000000111"=>   instrction := INS_sra; -- extra 
            when "00000100000"=>   instrction := INS_add;
            when "00000100010"=>   instrction := INS_sub;
            when "00000100100"=>   instrction := INS_and;
            when "00000100101"=>   instrction := INS_or; 
            when "00000100110"=>   instrction := INS_xor;            
            when "00000101000"=>   instrction := INS_seq; -- extra
            when "00000101001"=>   instrction := INS_sne;
            when "00000101100"=>   instrction := INS_sle;
            when "00000101101"=>   instrction := INS_sge;
            when "00000101011"=>   instrction := INS_sgt; -- extra
            when others=>          instrction := INS_nop;
         end case;
     ---------------------- R-type --------------------------  
     ---------------------- F-type --------------------------
     when "000001" => 
         case FUNC is
            when "00000001111"=>   instrction := INS_div;  --extra
            when "00000001110"=>   instrction := INS_mult; --extra
            when others=>          instrction := INS_nop;
         end case;
     ---------------------- F-type --------------------------
     ---------------------- I-type --------------------------
     when "001000" =>   instrction := INS_addi;
     when "001010" =>   instrction := INS_subi;
     when "001100" =>   instrction := INS_andi;
     when "001101" =>   instrction := INS_ori;
     when "001110" =>   instrction := INS_xori;
     when "010101" =>   instrction := INS_nop;
     when "010110" =>   instrction := INS_srli;
     when "010100" =>   instrction := INS_slli;
     when "010111" =>   instrction := INS_srai; --extra
     when "011000" =>   instrction := INS_seqi; --extra
     when "011001" =>   instrction := INS_snei; 
     when "011010" =>   instrction := INS_slti; --extra
     when "011011" =>   instrction := INS_sgti; --extra
     when "011100" =>   instrction := INS_slei; 
     when "011101" =>   instrction := INS_sgei; 
     when "100011" =>   instrction := INS_lw; 
     when "101011" =>   instrction := INS_sw; 
     ---------------------- I-type --------------------------
     ---------------------- branch-type --------------------------
     when "000100" =>   instrction := INS_beqz;
     when "000101" =>   instrction := INS_bnez; 
     when "000010" =>   instrction := INS_j;
     when "000011" =>   instrction := INS_jal;
     ---------------------- branch-type --------------------------
     when others   =>   instrction := INS_nop;
  end case;
  --**************************************************************--

  return instrction ;
end function AnalyzeIns;



end package body func_pkg;




















