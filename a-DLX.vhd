library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.func_pkg.all;
use work.type_pkg.all;

entity DLX is
port(
CLK : in std_logic;
nRST : in std_logic;
filePath : in string -- from external world
);
end DLX;


architecture asd of DLX is
-------------- components -------------
component CU is
port(
 CLK : in std_logic;
 OPCODE_CU : in std_logic_vector(insOPCODE_SIZE-1 downto 0);
 FUNC_CU : in std_logic_vector(insFUNC_SIZE-1 downto 0);
 nRST : in std_logic; -- from external world
 PC_op_CU : buffer PC_OP_type;
 pipe_enable_fetch_CU : buffer std_logic;
 pipe_enable_decode_CU : buffer std_logic;
 RF_ENABLE_decode_CU : buffer std_logic;
 RF_READ1_decode_CU : buffer std_logic; 
 RF_READ2_decode_CU : buffer std_logic; 
 RF_WRITE_decode_CU : buffer std_logic; --///
 RFout1_SEL_CU : buffer RF_OUT_SEL_type; -- RF output_1 1st level output select
 RFout2_SEL_CU : buffer RF_OUT_SEL_type; -- RF output_2 1st level output select
 ADDR1_ALLCATE_OP_CU : buffer RF_ADDR_ALLCATE_OP_type; -- RF read_1_addr sel
 ADDR2_ALLCATE_OP_CU : buffer RF_ADDR_ALLCATE_OP_type; -- RF read_2_addr sel
 BranchRequest_CU : buffer BRANCH_REQ_type; -- from CU
 Branch_Taken_Result_CU : in BRANCH_TAKEN_RESULT_type; -- CU flush part sel CTRL
 Branch_Src_CU : buffer BRANCH_OFFSET_SRC_type; -- branch offset source select control
 --Forward_SEL_1 : in FORWARD_SEL_type; -- from decode stage for determining load ins forwarding
 --Forward_SEL_2 : in FORWARD_SEL_type; -- from decode stage for determining load ins forwarding
 isLoadInsHistoryTable : buffer isLoadInsHistory_Table_type(2 downto 0); -- to decode stage for determining load ins forwarding
 CurrentIsDivIns : buffer isDivIns_type;
 PreviousIsDivIns : buffer isDivIns_type;
 DIVIDER_DONE_CU : in std_logic;
 pipe_enable_execution_CU : buffer std_logic;
 ALU_OP_CU_real : buffer ALU_OP_type;
 pipe_enable_memory_CU : buffer std_logic;
 DataMemRead_EN_CU : buffer std_logic;
 DataMemWrite_EN_CU : buffer std_logic;
 DataMemReadDone_CU : in std_logic;
 MEMstageOutValSel_CU : buffer MEMstageOutValSel_type
);
end component;

component FETCH_STAGE is
port(
  CLK : in std_logic;
  pipe_enable_fetch : in std_logic; -- from CU
  OPCODE_fetch : out std_logic_vector(insOPCODE_SIZE-1 downto 0); -- to CU 
  FUNC_fetch : out std_logic_vector(insFUNC_SIZE-1 downto 0); -- to CU
  IMME_fetch : out integer; -- immediate info in instruction
  RS1_fetch : out integer; -- resource addr_1 info in instruction
  RS2_fetch : out integer; -- resource addr_1 info in instruction
  RD_fetch : out integer; -- destination addr_1 info in instruction
  OFFSET_fetch : out integer;  -- jump offset
  NPC_fetch : out integer; -- next PC
  Jmp_PC : in integer; -- from D stage
  PC_op : in PC_OP_type; -- from CU
  nRST : in std_logic; -- from CU
  filePath : in string -- from external world
);
end component;

component decode_stage is
port(
  CLK : in std_logic;
  pipe_enable_decode_in : in std_logic; -- from CU
  IMME_decode_in : in integer; -- from fetch stage
  OFFSET_decode_in : in integer; -- from fetch stage, jump offset
  NPC_decode_in : in integer; -- from fetch stage
  nRST : in std_logic; -- from CU
  RF_RS1_decode_in : in integer; -- from fetch stage
  RF_RS2_decode_in : in integer; -- from fetch stage
  RF_RD_decode_in : in integer; -- from fetch stage, RD field
  RF_RD_WriteBack_in : in integer; -- from write back stage
  RF_ENABLE_decode_in : in std_logic; -- from CU
  RF_READ1_decode_in : in std_logic; -- from CU
  RF_READ2_decode_in : in std_logic; -- from CU
  RF_WRITE_decode_in : in std_logic; -- from CU
  RF_DATAIN_decode_in : in integer; -- from fetch stage
  RFout1_SEL_in : in RF_OUT_SEL_type; -- from CU, RF output_1 1st level output select
  RFout2_SEL_in : in RF_OUT_SEL_type; -- from CU, RF output_2 1st level output select
  ADDR1_ALLCATE_OP_in : in RF_ADDR_ALLCATE_OP_type; -- from CU
  ADDR2_ALLCATE_OP_in : in RF_ADDR_ALLCATE_OP_type; -- from CU
  ForwardVal_dist1_in : in integer; -- from forward record value table
  ForwardVal_dist2_in : in integer; -- from forward record value table
  ForwardVal_dist3_in : in integer; -- from forward record value table
  MEM_LoadForward_dist1_in : in integer; -- from data memory output forward
  WB_LoadForward_dist2_in : in integer; -- from write back output forward
  FORWARD1_SEL : buffer FORWARD_SEL_type; -- from forwarding logic FF to CU
  FORWARD2_SEL : buffer FORWARD_SEL_type; -- from forwarding logic FF to CU
  isLoadInsHistoryTable : in isLoadInsHistory_Table_type(2 downto 0);
  CurrentIsDivIns : in isDivIns_type;
  PreviousIsDivIns : in isDivIns_type;
  BranchRequest : in BRANCH_REQ_type; -- from CU
  Branch_Taken_Result : buffer BRANCH_TAKEN_RESULT_type; -- to CU flush part
  Branch_Src : in BRANCH_OFFSET_SRC_type; -- from CU
  FeedBackPC : buffer integer; -- Next Processed insADDR, feed back to fetch stage PC
  Oprand1_decode : buffer integer; -- to EXE stage
  Oprand2_decode : buffer integer; -- to EXE stage
  DataMemStoreDataIn_Decode : buffer integer; -- to EXE stage
  RF_RD_WriteBack_Decode : buffer integer
);
end component;


component execution_stage is
port(
 CLK : in std_logic; -- in from external world
 ALU_OP : in ALU_OP_type; -- in from CU
 oprand_1_execution :in integer; -- in from decode stage
 oprand_2_execution :in integer; -- in from decode stage
 DataMemStoreDataIn_pipe_D2E : in integer; -- from decode stage pipeline
 RF_RD_WriteBackAddr_pipe_D2E : in integer;
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
end component;


component MEM_stage is
port(
CLK : in std_logic;
nRST : in std_logic;
MEM_stage_pipe_enable : in std_logic; -- from CU
DATA_mem_RD_EN : in std_logic; -- from CU through 2 buffer regs
DATA_mem_WR_EN : in std_logic; -- from CU through 2 buffer regs
MEMstageOutValSel : in MEMstageOutValSel_type; -- from CU for choosing which kind of output is provided to write back stage
DATA_mem_Store_DataIn : in integer; -- from execution stage
RF_RD_WriteBackAddr_mem_in : in integer; -- from execution stage
Data_mem_inVal : in integer; -- from execution stage, either it's reading addr of DataMem or wrDataIn
DATA_mem_Read_Done : buffer std_logic; -- to CU for reactivating the pipelining from stall
MEMstageDataOut : buffer integer; -- to write back stage
MEM_ForwardingFeedBack : buffer integer; -- feed back to decode stage forwarding value list Dist1
RF_RD_WriteBackAddr_mem_out : buffer integer
);
end component;


-- component WriteBack_stage is
-- use signals to implement
-- end component
---------------------------------------

-------------- signals ---------------
-- fetch stage
signal CU_to_F_pipe_enable : std_logic;
signal F_to_CU_OPCODE : std_logic_vector(insOPCODE_SIZE-1 downto 0);
signal F_to_CU_FUNC : std_logic_vector(insFUNC_SIZE-1 downto 0);
signal F_to_D_IMME : integer;
signal F_to_D_RS1 : integer;
signal F_to_D_RS2 : integer;
signal F_to_D_RD : integer;
signal F_to_D_OFFSET : integer;
signal F_to_D_NPC : integer;
signal D_to_F_FeedbackPC : integer;
signal CU_to_F_PCop : PC_OP_type;
-- decode stage
signal CU_to_D_pipe_enable : std_logic;
signal CU_to_D_RF_enable : std_logic;
signal CU_to_D_RF_read1 : std_logic;
signal CU_to_D_RF_read2 : std_logic;
signal CU_to_D_RF_write : std_logic;
signal CU_to_D_RF_Rout1_sel : RF_OUT_SEL_type;
signal CU_to_D_RF_Rout2_sel : RF_OUT_SEL_type;
signal CU_to_D_RF_ADDR1_sel : RF_ADDR_ALLCATE_OP_type;
signal CU_to_D_RF_ADDR2_sel : RF_ADDR_ALLCATE_OP_type;
signal CU_to_D_ifRecordRD : std_logic;
signal E_to_D_ForwardVal_dist1 : integer;
signal E_to_D_ForwardVal_dist2 : integer;
signal E_to_D_ForwardVal_dist3 : integer;
signal M_to_D_MEM_LoadForward_dist1 : integer;
signal W_to_D_LoadForward_dist2 : integer;
signal D_to_CU_Forward_SEL_1 : FORWARD_SEL_type;
signal D_to_CU_Forward_SEL_2 : FORWARD_SEL_type;
signal CU_to_D_isLoadInsHistoryTable : isLoadInsHistory_Table_type(2 downto 0);
signal CU_to_DandE_CurrentIsDivIns : isDivIns_type;
signal CU_to_DandE_PreviousIsDivIns : isDivIns_type;
signal CU_to_D_BranchReq : BRANCH_REQ_type;
signal D_to_CU_BranchTakenResult : BRANCH_TAKEN_RESULT_type;
signal CU_to_D_Branch_Src : BRANCH_OFFSET_SRC_type;
signal D_to_E_oprand1 : integer;
signal D_to_E_oprand2 : integer;
signal D_to_E_DataMemStoreDataIn: integer;
signal D_to_E_RF_RD_Addr : integer;
-- execution stage
signal CU_to_E_ALUop : ALU_OP_type;
signal E_to_CU_DivDone : std_logic;
signal CU_to_E_pipe_enable : std_logic;
signal E_to_M_oprand : integer;
signal E_to_M_DataMemStoreDataIn : integer;
signal E_to_M_RF_RD_Addr : integer;
signal CU_to_E_CurrentIsDivIns : isDivIns_type;
-- memory stage
signal CU_to_M_pipe_enable : std_logic;
signal CU_to_M_DataMemRead_EN : std_logic;
signal CU_to_M_DataMemWrite_EN : std_logic;
signal M_to_CU_DataMemReadDone : std_logic;
signal CU_to_M_MEMstageOutValSel : MEMstageOutValSel_type;
signal M_to_W_data : integer;
-- write back stage
signal W_to_D_RF_datain : integer;
signal M_to_D_RF_RD_Addr : integer;
--------------------------------------  
  
begin
  
  CU_map: CU
          port map(
           CLK=>CLK
          ,OPCODE_CU=>F_to_CU_OPCODE
          ,FUNC_CU=>F_to_CU_FUNC
          ,nRST=>nRST
          ,PC_op_CU =>CU_to_F_PCop
          ,pipe_enable_fetch_CU=>CU_to_F_pipe_enable
          ,pipe_enable_decode_CU=>CU_to_D_pipe_enable
          ,RF_ENABLE_decode_CU=>CU_to_D_RF_enable
          ,RF_READ1_decode_CU=>CU_to_D_RF_read1
          ,RF_READ2_decode_CU=>CU_to_D_RF_read2
          ,RF_WRITE_decode_CU=>CU_to_D_RF_write 
          ,RFout1_SEL_CU=>CU_to_D_RF_Rout1_sel
          ,RFout2_SEL_CU=>CU_to_D_RF_Rout2_sel
          ,ADDR1_ALLCATE_OP_CU=>CU_to_D_RF_ADDR1_sel
          ,ADDR2_ALLCATE_OP_CU=>CU_to_D_RF_ADDR2_sel
          ,BranchRequest_CU=>CU_to_D_BranchReq
          ,Branch_Taken_Result_CU=>D_to_CU_BranchTakenResult
          ,Branch_Src_CU=>CU_to_D_Branch_Src
          --,Forward_SEL_1=>D_to_CU_Forward_SEL_1
          --,Forward_SEL_2=>D_to_CU_Forward_SEL_2
          ,isLoadInsHistoryTable(0)=>CU_to_D_isLoadInsHistoryTable(0)
          ,isLoadInsHistoryTable(1)=>CU_to_D_isLoadInsHistoryTable(1)
          ,isLoadInsHistoryTable(2)=>CU_to_D_isLoadInsHistoryTable(2)
          ,CurrentIsDivIns=>CU_to_DandE_CurrentIsDivIns
          ,PreviousIsDivIns=>CU_to_DandE_PreviousIsDivIns
          ,DIVIDER_DONE_CU=>E_to_CU_DivDone
          ,pipe_enable_execution_CU=>CU_to_E_pipe_enable
          ,ALU_OP_CU_real=>CU_to_E_ALUop
          ,pipe_enable_memory_CU=>CU_to_M_pipe_enable
          ,DataMemRead_EN_CU=>CU_to_M_DataMemRead_EN
          ,DataMemWrite_EN_CU=>CU_to_m_DataMemWrite_EN 
          ,DataMemReadDone_CU=>M_to_CU_DataMemReadDone
          ,MEMstageOutValSel_CU=>CU_to_M_MEMstageOutValSel
          );

  
  fetch_map: FETCH_STAGE
             port map(
              CLK=>CLK
             ,pipe_enable_fetch=>CU_to_F_pipe_enable
             ,OPCODE_fetch=>F_to_CU_OPCODE
             ,FUNC_fetch=>F_to_CU_FUNC
             ,IMME_fetch=>F_to_D_IMME
             ,RS1_fetch=>F_to_D_RS1
             ,RS2_fetch=>F_to_D_RS2
             ,RD_fetch=>F_to_D_RD
             ,OFFSET_fetch=>F_to_D_OFFSET
             ,NPC_fetch=>F_to_D_NPC
             ,Jmp_PC=>D_to_F_FeedbackPC
             ,PC_op=>CU_to_F_PCop
             ,nRST=>nRST
             ,filePath=>filePath 
             );
  
  decode_map: decode_stage
              port map(
              CLK=>CLK
             ,pipe_enable_decode_in=>CU_to_D_pipe_enable
             ,IMME_decode_in=>F_to_D_IMME
             ,OFFSET_decode_in=>F_to_D_OFFSET
             ,NPC_decode_in=>F_to_D_NPC
             ,RF_RS1_decode_in=>F_to_D_RS1
             ,RF_RS2_decode_in=>F_to_D_RS2
             ,RF_RD_decode_in=>F_to_D_RD
             ,RF_RD_WriteBack_in=>M_to_D_RF_RD_Addr
             ,RF_ENABLE_decode_in=>CU_to_D_RF_enable
             ,RF_READ1_decode_in=>CU_to_D_RF_read1
             ,RF_READ2_decode_in=>CU_to_D_RF_read2
             ,RF_WRITE_decode_in=>CU_to_D_RF_write
             ,RF_DATAIN_decode_in=>W_to_D_RF_datain
             ,RFout1_SEL_in=>CU_to_D_RF_Rout1_sel
             ,RFout2_SEL_in=>CU_to_D_RF_Rout2_sel
             ,ADDR1_ALLCATE_OP_in=>CU_to_D_RF_ADDR1_sel
             ,ADDR2_ALLCATE_OP_in=>CU_to_D_RF_ADDR2_sel
             ,ForwardVal_dist1_in=>E_to_D_ForwardVal_dist1
             ,ForwardVal_dist2_in=>E_to_D_ForwardVal_dist2
             ,ForwardVal_dist3_in=>E_to_D_ForwardVal_dist3
             ,MEM_LoadForward_dist1_in=>M_to_D_MEM_LoadForward_dist1
             ,WB_LoadForward_dist2_in=>W_to_D_LoadForward_dist2
             ,FORWARD1_SEL=>D_to_CU_Forward_SEL_1
             ,FORWARD2_SEL=>D_to_CU_Forward_SEL_2
             ,isLoadInsHistoryTable(0)=>CU_to_D_isLoadInsHistoryTable(0)
             ,isLoadInsHistoryTable(1)=>CU_to_D_isLoadInsHistoryTable(1)
             ,isLoadInsHistoryTable(2)=>CU_to_D_isLoadInsHistoryTable(2)
             ,CurrentIsDivIns=>CU_to_DandE_CurrentIsDivIns
             ,PreviousIsDivIns=>CU_to_DandE_PreviousIsDivIns
             ,nRST=>nRST
             ,BranchRequest=>CU_to_D_BranchReq
             ,Branch_Taken_Result=>D_to_CU_BranchTakenResult
             ,Branch_Src=>CU_to_D_Branch_Src
             ,FeedBackPC=>D_to_F_FeedbackPC
             ,Oprand1_decode=>D_to_E_oprand1
             ,Oprand2_decode=>D_to_E_oprand2
             ,DataMemStoreDataIn_Decode=>D_to_E_DataMemStoreDataIn
             ,RF_RD_WriteBack_Decode=>D_to_E_RF_RD_Addr
              );
              
  exe_map:  execution_stage
            port map(
             CLK=>CLK
            ,ALU_OP=>CU_to_E_ALUop
            ,oprand_1_execution=>D_to_E_oprand1
            ,oprand_2_execution=>D_to_E_oprand2
            ,DataMemStoreDataIn_pipe_D2E=>D_to_E_DataMemStoreDataIn
            ,RF_RD_WriteBackAddr_pipe_D2E=>D_to_E_RF_RD_Addr
            ,DIV_done=>E_to_CU_DivDone
            ,ALU_Result_HisTable(1)=>E_to_D_ForwardVal_dist3
            ,ALU_Result_HisTable(0)=>E_to_D_ForwardVal_dist2
            ,CurrentIsDivIns=>CU_to_DandE_CurrentIsDivIns
            ,PreviousIsDivIns=>CU_to_DandE_PreviousIsDivIns
            ,ALU_New_Result=>E_to_D_ForwardVal_dist1
            ,pipeline_enable_execution=>CU_to_E_pipe_enable
            ,Output_exe_stage=>E_to_M_oprand
            ,DataMemStoreDataIn_execution=>E_to_M_DataMemStoreDataIn
            ,RF_RD_WriteBackAddr_execution=>E_to_M_RF_RD_Addr
            );
            
            
  mem_map:  MEM_stage
            port map(
             CLK=>CLK
            ,nRST=>nRST
            ,MEM_stage_pipe_enable=>CU_to_M_pipe_enable
            ,DATA_mem_RD_EN=>CU_to_M_DataMemRead_EN
            ,DATA_mem_WR_EN=>CU_to_M_DataMemWrite_EN
            ,MEMstageOutValSel=>CU_to_M_MEMstageOutValSel
            ,DATA_mem_Store_DataIn=>E_to_M_DataMemStoreDataIn
            ,RF_RD_WriteBackAddr_mem_in=>E_to_M_RF_RD_Addr
            ,Data_mem_inVal=>E_to_M_oprand
            ,DATA_mem_Read_Done=>M_to_CU_DataMemReadDone
            ,MEMstageDataOut=>M_to_W_data
            ,MEM_ForwardingFeedBack=>M_to_D_MEM_LoadForward_dist1
            ,RF_RD_WriteBackAddr_mem_out=>M_to_D_RF_RD_Addr
            );
            
            
  WriteBack_map:  W_to_D_RF_datain <= M_to_W_data;
                  W_to_D_LoadForward_dist2 <= M_to_W_data;
end asd;
