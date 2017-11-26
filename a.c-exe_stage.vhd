library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.func_pkg.all;
use work.type_pkg.all;

entity execution_stage is
port(
 CLK : in std_logic; -- in from external world
 ALU_OP : in ALU_OP_type; -- in from CU
 oprand_1_execution :in integer; -- in from decode stage
 oprand_2_execution :in integer; -- in from decode stage
 DataMemStoreDataIn_pipe_D2E : in integer; -- from decode stage pipeline
 RF_RD_WriteBackAddr_pipe_D2E : in integer; -- from decode stage pipeline
 DIV_done : buffer std_logic;  -- out to CU
 ALU_Result_HisTable : buffer Data_history_table(1 downto 0); -- feed back to decode stage forwarding select
 ALU_New_Result : buffer integer;
 CurrentIsDivIns : in isDivIns_type;
 PreviousIsDivIns : in isDivIns_type;
 pipeline_enable_execution : in std_logic; -- from CU
 Output_exe_stage : out integer; -- to mem stage
 DataMemStoreDataIn_execution : buffer integer; -- to memory stage pipeline
 RF_RD_WriteBackAddr_execution : buffer integer
);
end execution_stage;


architecture asd of execution_stage is
--------------- component --------------
component BOOTHMUL is
generic(N_mul_operand : INTEGER);
port
(
  Ain, Bin : in integer;
  MUL_result : out integer
);
end component;

component DIVIDER is
generic(N_div : INTEGER);
port
(
  CLK, START : in STD_LOGIC;
  DONE : buffer STD_LOGIC;
  DIVIDEND, DIVISOR : in integer;
  QUOTIENT, RESIDUAL : out integer 
);
end component;
----------------------------------------

--------------- signals ----------------
signal DIV_START : std_logic; -- divider start control
signal DIV_quotient_inter : integer; -- to be selected by ALU OUT
signal DIV_residual_inter : integer; -- to be selected by ALU OUT
signal mul_result_inter : integer; -- mul unit result
signal Previous_ALU_op : ALU_OP_type;
--signal test : integer := 0;
----------------------------------------  
begin
  ---------------- Booth multiplier ------------------
  MUL_map: BOOTHMUL generic map(N_mul_operand=>RF_BIT_SIZE)
                    port map(
                     Ain=>oprand_1_execution
                    ,Bin=>oprand_2_execution
                    ,MUL_result=>mul_result_inter
                    );
  ---------------- Booth multiplier ------------------
  
  ---------------- Divider ------------------
  DIV_map: DIVIDER generic map(N_div=>RF_BIT_SIZE)
                    port map(
                     CLK=>CLK
                    ,START=>DIV_START
                    ,DONE=>DIV_done
                    ,DIVIDEND=>oprand_1_execution
                    ,DIVISOR=> oprand_2_execution
                    ,QUOTIENT=>DIV_quotient_inter
                    ,RESIDUAL=>DIV_residual_inter
                    );
  ---------------- Divider ------------------


  ---------------- ALU behavior ----------------------------
  ALU_proc: process(CLK, DIV_done, DIV_quotient_inter)
            variable oprand_1_slv : std_logic_vector(RF_BIT_SIZE-1 downto 0);
            variable oprand_2_slv : std_logic_vector(RF_BIT_SIZE-1 downto 0);
            variable oprand_1_MSB : std_logic;
            --variable ALU_out_countinue : std_logic;
            begin
              DIV_START <= '0';
              oprand_1_slv := std_logic_vector(to_signed(oprand_1_execution, RF_BIT_SIZE));
              oprand_2_slv := std_logic_vector(to_signed(oprand_2_execution, RF_BIT_SIZE));
              oprand_1_MSB := oprand_1_slv(RF_BIT_SIZE-1);
   
   if (DIV_done='1') and (PreviousIsDivIns = isDiv)then
      --test <= 1;
      ALU_New_Result <= DIV_quotient_inter;
   end if;        
   if rising_edge(CLK) then
      ---------------- ALU result history table-----------------------
      if (pipeline_enable_execution = '1') then
        ALU_Result_HisTable(0) <= ALU_New_Result;
        ALU_Result_HisTable(1) <= ALU_Result_HisTable(0);
		
			case ALU_OP is
			when add_op=>   
				DIV_START <= '0';
				ALU_New_Result <= oprand_1_execution + oprand_2_execution;
				
			when sub_op=>   
				DIV_START <= '0';
				ALU_New_Result <= oprand_1_execution - oprand_2_execution;
				
			when and_op=>   
				DIV_START <= '0';
				ALU_New_Result <= to_integer(signed(oprand_1_slv and oprand_2_slv));
				
			when or_op =>   
				DIV_START <= '0';
				ALU_New_Result <= to_integer(signed(oprand_1_slv or oprand_2_slv));  
			
			when xor_op =>
				DIV_START <= '0';
				ALU_New_Result <= to_integer(signed(oprand_1_slv xor oprand_2_slv));
			  
			when logic_L_shift_op=>
				DIV_START <= '0';
				llsh: for i in 1 to to_integer(unsigned(oprand_2_slv(4 downto 0))) loop
						  oprand_1_slv := oprand_1_slv(RF_BIT_SIZE-2 downto 0) & '0';
					  end loop;
					  ALU_New_Result <= to_integer(signed(oprand_1_slv));
					  
			when arith_L_shift_op=>
				DIV_START <= '0';
				alsh: for i in 1 to to_integer(unsigned(oprand_2_slv(4 downto 0))) loop
						  oprand_1_slv := oprand_1_slv(RF_BIT_SIZE-2 downto 0) & '0';
					  end loop;
					  ALU_New_Result <= to_integer(signed(oprand_1_slv));
					  
			when logic_R_shift_op=>
				DIV_START <= '0';
				lrsh: for i in 1 to to_integer(unsigned(oprand_2_slv(4 downto 0))) loop
						  oprand_1_slv := '0' & oprand_1_slv(RF_BIT_SIZE-1 downto 1);
					  end loop;
					  ALU_New_Result <= to_integer(signed(oprand_1_slv)); 
					  
			when arith_R_shift_op=>
				DIV_START <= '0';
				arsh: for i in 1 to to_integer(unsigned(oprand_2_slv(4 downto 0))) loop
						  oprand_1_slv := oprand_1_MSB & oprand_1_slv(RF_BIT_SIZE-1 downto 1);
					  end loop;
					  ALU_New_Result <= to_integer(signed(oprand_1_slv));
			
			when mul_op=> 
				DIV_START <= '0'; 
				ALU_New_Result <= mul_result_inter;
				
			when div_op=>
				ALU_New_Result <= DIV_quotient_inter;
				DIV_START <= '1';
				
			when rem_op=>   
				ALU_New_Result <= DIV_residual_inter;
				DIV_START <= '1';

			when set_op1EQop2=>
				DIV_START <= '0';
				if (oprand_1_execution = oprand_2_execution) then
				   ALU_New_Result <= 1;
				else
				   ALU_New_Result <= 0;
				end if;
			
			when set_op1NEop2=>
				DIV_START <= '0';
				if (oprand_1_execution /= oprand_2_execution) then
				   ALU_New_Result <= 1;
				else
				   ALU_New_Result <= 0;
				end if;
			
			when set_op1GTop2=>
				DIV_START <= '0';
				if (oprand_1_execution > oprand_2_execution) then
				   ALU_New_Result <= 1;
				else
				   ALU_New_Result <= 0;
				end if; 
				
			when set_op1LTop2=>
				DIV_START <= '0';
				if (oprand_1_execution < oprand_2_execution) then
				   ALU_New_Result <= 1;
				else
				   ALU_New_Result <= 0;
				end if;     
			
			when set_op1GEop2=>
				DIV_START <= '0';
				if (oprand_1_execution >= oprand_2_execution) then
				   ALU_New_Result <= 1;
				else
				   ALU_New_Result <= 0;
				end if;
			
			when set_op1LEop2=>
				DIV_START <= '0';
				if (oprand_1_execution <= oprand_2_execution) then
				   ALU_New_Result <= 1;
				else
				   ALU_New_Result <= 0;
				end if;
					   
			when nop_op=> 
				null;    
				
			when others=> null;
		    end case;
      end if;
      ---------------- ALU result history table-----------------------
  
  end if;
            end process;
  ---------------- ALU behavior ----------------------------
  
  
  
  ---------------- execution pipeline enable ----------------
  exe_pipeline_proc:
  process(CLK, pipeline_enable_execution)
      begin
        if falling_edge(CLK) and (pipeline_enable_execution = '1') then
          Output_exe_stage <= ALU_New_Result;
          DataMemStoreDataIn_execution <= DataMemStoreDataIn_pipe_D2E;
          RF_RD_WriteBackAddr_execution <= RF_RD_WriteBackAddr_pipe_D2E;
        end if;
      end process;
  ---------------- execution pipeline enable ----------------
  
  
end asd;
