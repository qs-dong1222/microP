library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.func_pkg.all;
use work.type_pkg.all;

entity CU is
port(
 CLK : in std_logic;
 OPCODE_CU : in std_logic_vector(insOPCODE_SIZE-1 downto 0);
 FUNC_CU : in std_logic_vector(insFUNC_SIZE-1 downto 0);
 nRST : in std_logic; -- from external world
 
 
 -------- real outputs of CU after flush mux -----------
 -------- to fetch stage ------------
 PC_op_CU : buffer PC_OP_type;
 pipe_enable_fetch_CU : buffer std_logic;
 
 -------- to decode stage ------------
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
 -------- to execution stage ------------
 DIVIDER_DONE_CU : in std_logic;
 pipe_enable_execution_CU : buffer std_logic; --/
 ALU_OP_CU_real : buffer ALU_OP_type; --/
 
 
 -------- to memory stage ------------
 pipe_enable_memory_CU : buffer std_logic; --//
 DataMemRead_EN_CU : buffer std_logic; --// to 
 DataMemWrite_EN_CU : buffer std_logic;
 DataMemReadDone_CU : in std_logic;
 MEMstageOutValSel_CU : buffer MEMstageOutValSel_type
);
end CU;


architecture asd of CU is
----------------------------- signals --------------------------------------
signal InsAnalyzeResult : INSTRUCTION_type;
signal CurrentIsLoadIns : isLoadIns_type;
 -------- to fetch stage ------------
 --nothing
 -------- to decode stage ------------
signal RFout1_SEL_flush : RF_OUT_SEL_type; -- RF output_1 1st level output select
signal RFout2_SEL_flush : RF_OUT_SEL_type; -- RF output_2 1st level output select
-- RFout1_SEL_CU, RFout2_SEL_CU are outputs
signal ADDR1_ALLCATE_OP_flush : RF_ADDR_ALLCATE_OP_type; -- RF read_1_addr sel
signal ADDR2_ALLCATE_OP_flush : RF_ADDR_ALLCATE_OP_type; -- RF read_2_addr sel  
-- ADDR1_ALLCATE_OP_CU, ADDR2_ALLCATE_OP_CU are outputs
 -------- to execution stage ------------
signal ALU_OP_flush : ALU_OP_type;
 -------- to memory stage ------------
signal DataMemRead_EN_CU_flush : std_logic;
signal DataMemRead_EN_CU_Buf_1 : std_logic;
signal DataMemWrite_EN_CU_flush : std_logic;
signal DataMemWrite_EN_CU_Buf_1 : std_logic;
signal MEMstageOutValSel_CU_flush : MEMstageOutValSel_type;
signal MEMstageOutValSel_CU_Buf_1 : MEMstageOutValSel_type;
 -------- to write back stage ----------
signal RF_WRITE_decode_flush : std_logic; 
signal RF_WRITE_decode_CU_pipeBuf_1 : std_logic;
signal RF_WRITE_decode_CU_pipeBuf_2 : std_logic;
signal FLUSH_SEL : Current_CTRL_Flush_type;
signal test : integer;
--------------------------------------------------------------------------------

begin
  InsAnalyzeResult <= AnalyzeIns(OPCODE_CU, FUNC_CU);
  
-------------------------------------------------------------------------------------------------------------------------------------  
  --****** flush assignment ******-- 
  RF_WRITE_decode_flush <= '0'; 
  RFout1_SEL_flush <= ReadValSel;
  RFout2_SEL_flush <= ReadValSel;
  ADDR1_ALLCATE_OP_flush <= R0toRS1; 
  ADDR2_ALLCATE_OP_flush <= R0toRS2; 
  ALU_OP_flush <= add_op;
  DataMemRead_EN_CU_flush <= '0';
  DataMemWrite_EN_CU_flush <= '0';
  MEMstageOutValSel_CU_flush <= void;
 --****** flush assignment ******-- 
 
 ------------ next ins whether flush or not ------------- 
  next_ins_flush_assign_proc:
  -- used for determine if next ins is going to be flushed
  process(nRST, Branch_Taken_Result_CU)
  begin
    -- flush select
    if (nRST = '0') then
       FLUSH_SEL <= NORMAL;
    elsif (Branch_Taken_Result_CU = Taken) then
       FLUSH_SEL <= FLUSH;
    else
       FLUSH_SEL <= NORMAL;
    end if;
  end process;    
  ------------ next ins whether flush or not ------------- 
  
  ----- PC assignment process -----
  PC_flush_proc:
  process(nRST, Branch_Taken_Result_CU, CurrentIsLoadIns, PreviousIsDivIns, DataMemReadDone_CU, DIVIDER_DONE_CU)
  begin
  --- This is for next-next instruction's correcte PC_op
  if (nRST = '0') then
      PC_op_CU <= PC_RESET;
  elsif (Branch_Taken_Result_CU = Taken) then
      PC_op_CU <= PC_JUMP;
	elsif ((CurrentIsLoadIns = isLoad)
     --and ((Forward_SEL_1 = Dist1)or(Forward_SEL_2 = Dist1))
     and (DataMemReadDone_CU /= '1')) then
	    PC_op_CU <= PC_LOCK;
	elsif (PreviousIsDivIns = isDiv) and (DIVIDER_DONE_CU /= '1') then
	    PC_op_CU <= PC_LOCK;
  else
      PC_op_CU <= PC_INCR;
  end if;
  end process;
 ----- PC assignment process -----
 -------------------------------------------------------------------------------------------------------------------------------------  
  
  
  
  ----- used for current ins falling edge pipe disable
  process(nRST, isLoadInsHistoryTable, DataMemReadDone_CU, CurrentIsDivIns, PreviousIsDivIns, DIVIDER_DONE_CU)
  begin
  if (nRST = '0') then
     pipe_enable_fetch_CU <= '0';
     pipe_enable_decode_CU <= '0';
     pipe_enable_execution_CU <= '0';
     pipe_enable_memory_CU <= '0';
	elsif (isLoadInsHistoryTable(0) = isLoad) and (DataMemReadDone_CU /= '1') then
	   pipe_enable_fetch_CU <= '0';
     pipe_enable_decode_CU <= '0';
     pipe_enable_execution_CU <= '1';
     pipe_enable_memory_CU <= '1';
	elsif ((CurrentIsDivIns = notDiv) 
	and (PreviousIsDivIns = isDiv)
	and (DIVIDER_DONE_CU /= '1')) then
	   pipe_enable_fetch_CU <= '0';
     pipe_enable_decode_CU <= '0';
     pipe_enable_execution_CU <= '0';
     pipe_enable_memory_CU <= '1';
	else
	   pipe_enable_fetch_CU <= '1';
     pipe_enable_decode_CU <= '1';
     pipe_enable_execution_CU <= '1';
     pipe_enable_memory_CU <= '1';
	end if;
  end process;
  

	
	   

	   
  -----------------------------------------------------------------------------------------------------------------------------------
  CTRL_assign_proc:
  process(CLK, nRST)
  begin
    if (nRST = '0') then
       -------- CU -----------      
       CurrentIsDivIns <= notDiv;
       PreviousIsDivIns <= notDiv;
       CurrentIsLoadIns <= notLoad;
       isLoadInsHistoryTable(0) <= notLoad;
       isLoadInsHistoryTable(1) <= notLoad;
       isLoadInsHistoryTable(2) <= notLoad;
       -------- to fetch stage -------------   
       -------- to decode stage ------------
       RF_ENABLE_decode_CU <= '1';
       RF_READ1_decode_CU <= '1'; 
       RF_READ2_decode_CU <= '1'; 
       RF_WRITE_decode_CU_pipeBuf_1 <= '0'; 
       RFout1_SEL_CU <= ReadValSel; -- RF output_1 1st level output select
       RFout2_SEL_CU <= ReadValSel; -- RF output_2 1st level output select
       ADDR1_ALLCATE_OP_CU <= RS1toRS1; -- RF read_1_addr sel
       ADDR2_ALLCATE_OP_CU <= RS2toRS2; -- RF read_2_addr sel
       BranchRequest_CU <= NoReq;  -- send to Branch comp unit  
       Branch_Src_CU <= srcOFFSET;      
       -------- to execution stage ------------
       ALU_OP_CU_real <= add_op;
       -------- to memory stage ------------

       

-- ********************* SEALED ***********************--
    elsif rising_edge(CLK) then
       
       if (pipe_enable_decode_CU = '1') then
     	    isLoadInsHistoryTable(0) <= CurrentIsLoadIns;
		      isLoadInsHistoryTable(1) <= isLoadInsHistoryTable(0);
		      isLoadInsHistoryTable(2) <= isLoadInsHistoryTable(1);
		      PreviousIsDivIns <= CurrentIsDivIns;
		      RF_WRITE_decode_CU_pipeBuf_2 <= RF_WRITE_decode_CU_pipeBuf_1;
		   elsif (isLoadInsHistoryTable(0) = isLoad) then
		      RF_WRITE_decode_CU_pipeBuf_2 <= RF_WRITE_decode_flush;
	     end if;
       
       if (pipe_enable_execution_CU = '1') then
		      RF_WRITE_decode_CU <= RF_WRITE_decode_CU_pipeBuf_2;
		      MEMstageOutValSel_CU <= MEMstageOutValSel_CU_Buf_1;
		      DataMemRead_EN_CU <= DataMemRead_EN_CU_Buf_1;
		      DataMemWrite_EN_CU <= DataMemWrite_EN_CU_Buf_1;
       end if;
      
       if (FLUSH_SEL = FLUSH) then
          RFout1_SEL_CU <= RFout1_SEL_flush;
          RFout2_SEL_CU <= RFout2_SEL_flush;
          ADDR1_ALLCATE_OP_CU <= ADDR1_ALLCATE_OP_flush;
          ADDR2_ALLCATE_OP_CU <= ADDR2_ALLCATE_OP_flush;
          BranchRequest_CU <= NoReq;
          ALU_OP_CU_real <= ALU_OP_flush;
          DataMemRead_EN_CU_Buf_1 <= DataMemRead_EN_CU_flush;
          DataMemWrite_EN_CU_Buf_1 <= DataMemWrite_EN_CU_flush;
          MEMstageOutValSel_CU_Buf_1 <= MEMstageOutValSel_CU_flush;
          RF_WRITE_decode_CU_pipeBuf_1 <= RF_WRITE_decode_flush;
       else
         
        case InsAnalyzeResult is
			  when INS_nop=>
				 RF_WRITE_decode_CU_pipeBuf_1 <= '0'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= R0toRS1; 
				 ADDR2_ALLCATE_OP_CU <= R0toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= add_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= void;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_sll=>
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= logic_L_shift_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_slli=>
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= logic_L_shift_op;   
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_srl=>
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;
				 ALU_OP_CU_real <= logic_R_shift_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_srli=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= logic_R_shift_op;   
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				  
			  when INS_sra=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;
				 ALU_OP_CU_real <= arith_R_shift_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_srai=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= arith_R_shift_op;   
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_add=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= add_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_addi=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= add_op;   
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_sub=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= sub_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_subi=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= sub_op;   
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_mult=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= mul_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_div=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= div_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= isDiv;
				 
			  
			  when INS_and=>			 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= and_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_andi=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= and_op;   
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				  
			  when INS_or=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= or_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad; 
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_ori=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= or_op;   
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_xor=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= xor_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
					
			  when INS_xori=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= xor_op;   
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_lw=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= add_op;
				 DataMemRead_EN_CU_Buf_1 <= '1';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= DataMemReadVal;
				 CurrentIsLoadIns <= isLoad; 
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_sw=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '0'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= add_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '1';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_seq=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= set_op1EQop2;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_sne=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= set_op1NEop2;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;  
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_sle=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= set_op1LEop2;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;  
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_sge=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= set_op1GEop2;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;  
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_sgt=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= set_op1GTop2;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;    
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_seqi=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= set_op1EQop2;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_snei=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= set_op1NEop2;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_slti=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= set_op1LTop2;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_sgti=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= set_op1GTop2;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_slei=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= set_op1LEop2;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_sgei=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ImmeValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= NoReq;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= set_op1GEop2;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
					   
			  when INS_beqz=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '0'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= IFop1EQ0;
				 Branch_Src_CU <= srcIMME;        
				 ALU_OP_CU_real <= nop_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= void;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_bnez=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '0'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= RS1toRS1; 
				 ADDR2_ALLCATE_OP_CU <= RS2toRS2; 
				 BranchRequest_CU <= IFop1NE0;
				 Branch_Src_CU <= srcIMME;        
				 ALU_OP_CU_real <= nop_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= void;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_j=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '0'; 
				 RFout1_SEL_CU <= ReadValSel; 
				 RFout2_SEL_CU <= ReadValSel; 
				 ADDR1_ALLCATE_OP_CU <= R0toRS1; 
				 ADDR2_ALLCATE_OP_CU <= R0toRS2; 
				 BranchRequest_CU <= AbsJump;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= nop_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= void;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when INS_jal=>				 
				 RF_WRITE_decode_CU_pipeBuf_1 <= '1'; 
				 RFout1_SEL_CU <= Jal8ValSel; 
				 RFout2_SEL_CU <= Jal8ValSel; 
				 ADDR1_ALLCATE_OP_CU <= R0toRS1; 
				 ADDR2_ALLCATE_OP_CU <= R0toRS2; 
				 BranchRequest_CU <= AbsJumpWBR31;
				 Branch_Src_CU <= srcOFFSET;        
				 ALU_OP_CU_real <= add_op;
				 DataMemRead_EN_CU_Buf_1 <= '0';
				 DataMemWrite_EN_CU_Buf_1 <= '0';
				 MEMstageOutValSel_CU_Buf_1 <= ALUinVal;
				 CurrentIsLoadIns <= notLoad;
				 CurrentIsDivIns <= notDiv;
				 
			  when others=> null;
          end case;
       end if;
    -- ********************* SEALED ***********************--    
    end if;
    
  end process;
  
  ----------- control signals assignment ----------------
  
  
  
  
end asd;
