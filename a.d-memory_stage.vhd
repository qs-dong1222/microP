library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.func_pkg.all;
use work.type_pkg.all;

entity MEM_stage is
port(
CLK : in std_logic;
nRST : in std_logic;
MEM_stage_pipe_enable : in std_logic; -- from CU
DATA_mem_RD_EN : in std_logic; -- from CU through buffer regs
DATA_mem_WR_EN : in std_logic; -- from CU through buffer regs
MEMstageOutValSel : in MEMstageOutValSel_type; -- from CU for choosing which kind of output is provided to write back stage
DATA_mem_Store_DataIn : in integer; -- from execution stage
RF_RD_WriteBackAddr_mem_in : in integer; -- from execution stage
Data_mem_inVal : in integer; -- from execution stage, either it's reading addr of DataMem or wrDataIn
DATA_mem_Read_Done : buffer std_logic; -- to CU for reactivating the pipelining from stall
MEMstageDataOut : buffer integer; -- to write back stage
MEM_ForwardingFeedBack : buffer  integer; -- feed back to decode stage forwarding value list Dist1
RF_RD_WriteBackAddr_mem_out : buffer integer
);
end MEM_stage;


architecture asd of MEM_stage is
---------- signals -----------
signal DataMemory : DataMemSpace;
signal DataMemoryReadOut : integer;
signal MEMstageDataOut_inter : integer;
------------------------------  
  
begin
  
  -------- Data memory process -----------
  Data_Mem_proc:
  process(CLK, DATA_mem_Store_DataIn, Data_mem_inVal)
  begin
    if (nRST = '0') then
       rst_loop:
       for i in 0 to DataMemory_ADDR_SIZE-1 loop
          DataMemory(i) <= 0;
       end loop;
       DATA_mem_Read_Done <= '0';
       
--     elsif (DATA_mem_RD_EN = '1') then
--        if (Data_mem_inVal >= 0) and (Data_mem_inVal < DataMemory_ADDR_SIZE) then
--          DataMemoryReadOut <= DataMemory(Data_mem_inVal);
--        end if;
--        if rising_edge(CLK) then
--          DATA_mem_Read_Done <= '1';
--        end if;
--    
--     elsif rising_edge(CLK) and (DATA_mem_WR_EN = '1') then
--        if (Data_mem_inVal >= 0) and (Data_mem_inVal < DataMemory_ADDR_SIZE) then
--          DataMemory(Data_mem_inVal) <= DATA_mem_Store_DataIn;
--          DATA_mem_Read_Done <= '0';
--        end if;
--     end if;
	elsif rising_edge(CLK) then
		if (DATA_mem_RD_EN = '1') then
			DATA_mem_Read_Done <= '1';
		elsif (DATA_mem_WR_EN = '1') and (Data_mem_inVal >= 0) and (Data_mem_inVal < DataMemory_ADDR_SIZE) then
			DataMemory(Data_mem_inVal) <= DATA_mem_Store_DataIn;
			DATA_mem_Read_Done <= '0';
		end if;
	end if;
	if (DATA_mem_RD_EN = '1') and (Data_mem_inVal >= 0) and (Data_mem_inVal < DataMemory_ADDR_SIZE) and (nRST /= '0') then
		DataMemoryReadOut <= DataMemory(Data_mem_inVal);
	end if;
  end process;
  -------- Data memory process -----------
  
  
  -------- MEM stage output selection ---------
  process(DataMemoryReadOut, CLK)--(MEMstageOutValSel, DataMemoryReadOut, Data_mem_inVal)
  begin
    if rising_edge(CLK) then
      case MEMstageOutValSel is
        when DataMemReadVal=>    MEMstageDataOut_inter <= DataMemoryReadOut;
        when ALUinVal=>          MEMstageDataOut_inter <= Data_mem_inVal;
        when void=>              MEMstageDataOut_inter <= 0;
        when others=>            MEMstageDataOut_inter <= 0;
      end case;
    end if;
  end process;
  -------- MEM stage output selection ---------
  
  
  
  -------- MEM stage output pipeline ---------
  process(CLK, MEM_stage_pipe_enable)
  begin
    if falling_edge(CLK) and (MEM_stage_pipe_enable = '1') then
       MEMstageDataOut <= MEMstageDataOut_inter;
       RF_RD_WriteBackAddr_mem_out <= RF_RD_WriteBackAddr_mem_in;
    end if;
  end process;
  
  MEM_ForwardingFeedBack <= MEMstageDataOut_inter;
  -------- MEM stage output pipeline ---------
end asd;
