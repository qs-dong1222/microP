library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.func_pkg.all;
use work.type_pkg.all;

entity decode_stage is
port(
  CLK : in std_logic;
  pipe_enable_decode_in : in std_logic; -- from CU
  IMME_decode_in : in integer; -- from fetch stage
  OFFSET_decode_in : in integer; -- from fetch stage, jump offset
  NPC_decode_in : in integer; -- from fetch stage
  nRST : in std_logic; -- from CU
  
  --- RF
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

  --- forwarding
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
  --- branch test request
  BranchRequest : in BRANCH_REQ_type; -- from CU
  Branch_Taken_Result : buffer BRANCH_TAKEN_RESULT_type; -- to CU flush part
  Branch_Src : in BRANCH_OFFSET_SRC_type; -- from CU
  FeedBackPC : buffer integer; -- Next Processed insADDR, feed back to fetch stage PC
  
  -- output
  Oprand1_decode : buffer integer; -- to EXE stage
  Oprand2_decode : buffer integer; -- to EXE stage
  DataMemStoreDataIn_Decode : buffer integer; -- to EXE stage
  RF_RD_WriteBack_Decode : buffer integer
  
);
end decode_stage;



architecture asd of decode_stage is
------------------ component -----------------
component RF_generic is
port(
CLK: 		IN std_logic;
nRESET: 	IN std_logic;
ENABLE: 	IN std_logic;
RD1: 		IN std_logic;
RD2: 		IN std_logic;
WR: 		IN std_logic;
ADD_WR: 	IN integer; --std_logic_vector(log2(N_regs)-1 downto 0);
ADD_RD1: 	IN integer; --std_logic_vector(log2(N_regs)-1 downto 0);
ADD_RD2: 	IN integer; --std_logic_vector(log2(N_regs)-1 downto 0);
DATAIN: 	IN integer; --std_logic_vector(N_bitsOfREG-1 downto 0);
OUT1: 		OUT integer; --std_logic_vector(N_bitsOfREG-1 downto 0);
OUT2: 		OUT integer --std_logic_vector(N_bitsOfREG-1 downto 0)
);
end component;
----------------------------------------------

------------------ SIGNAL -------------------
signal RF_RS1_inter : integer;
signal RF_RS2_inter : integer;
signal RF_out1_inter : integer;
signal RF_out2_inter : integer;
signal RF_out1_mux : integer;
signal RF_out2_mux : integer;
signal RD_ADDR_HisTable : Data_history_table(2 downto 0);
signal RD_ADDR_HisTable_Buf : integer;
signal srcOffsetChoosen : integer;
signal BranchTargetAddr : integer;
signal Oprand1_decode_out : integer; -- to EXE stage pipeline reg
signal Oprand2_decode_out : integer; -- to EXE stage pipeline reg
----------------------------------------------

begin
------------ RF -----------
   RF_map: RF_generic
           port map(
              CLK=>CLK
             ,nRESET=>nRST
             ,ENABLE=>RF_ENABLE_decode_in
             ,RD1=>RF_READ1_decode_in
             ,RD2=>RF_READ2_decode_in
             ,WR=>RF_WRITE_decode_in
             ,ADD_WR=>RF_RD_WriteBack_in
             ,ADD_RD1=>RF_RS1_inter
             ,ADD_RD2=>RF_RS2_inter
             ,DATAIN=>RF_DATAIN_decode_in
             ,OUT1=>RF_out1_inter
             ,OUT2=>RF_out2_inter
           );
 ------------ RF -----------        
         
         
  -------------- RF ADDR allocation -----------
  -- used for flush the instruction RS1,RS2 field if branch prediction failed.
  ADDR_allcate_proc:
  process(ADDR1_ALLCATE_OP_in, ADDR2_ALLCATE_OP_in, CLK)
  begin
    case ADDR1_ALLCATE_OP_in is
      when R0toRS1 =>   RF_RS1_inter <= -1;
      when RS1toRS1=>   RF_RS1_inter <= RF_RS1_decode_in;
      when others=>    null;
    end case;
    
    case ADDR2_ALLCATE_OP_in is
      when R0toRS2 =>   RF_RS2_inter <= -1;
      when RS2toRS2=>   RF_RS2_inter <= RF_RS2_decode_in;
      when others=>    null;
    end case;
  end process;
 -------------- RF ADDR allcation -----------

 -------------- RF output select through level 1 mux ------------
 RF_out_sel_proc:
 process(RFout1_SEL_in, RFout2_SEL_in, RF_out1_mux, RF_out2_mux, IMME_decode_in)
 begin
   case RFout1_SEL_in is
      when ReadValSel=>  Oprand1_decode_out<=RF_out1_mux;
      when ImmeValSel=>  Oprand1_decode_out<=IMME_decode_in;
      when Jal8ValSel=>  Oprand1_decode_out<=NPC_decode_in;
      when others=>      null;
   end case;
   
   case RFout2_SEL_in is
      when ReadValSel=>  Oprand2_decode_out<=RF_out2_mux;
      when ImmeValSel=>  Oprand2_decode_out<=IMME_decode_in;
      when Jal8ValSel=>  Oprand2_decode_out<= 1; -- cooperate with 'NPC_decode_in' in oprand1
      when others=>      null;
   end case;
 end process;
 -------------- RF output select ------------


 -------------- forwarding select ------------
 forwarding_sel_proc:
 process(FORWARD1_SEL, FORWARD2_SEL, RF_out1_mux, RF_out2_mux, ForwardVal_dist1_in
        ,ForwardVal_dist2_in, ForwardVal_dist3_in, MEM_LoadForward_dist1_in
        ,WB_LoadForward_dist2_in, RF_out1_inter, RF_out2_inter)
 begin
 
     case FORWARD1_SEL is
      when NonForward=>  RF_out1_mux<=RF_out1_inter;
      when Dist1=>  
         if (isLoadInsHistoryTable(0) = isLoad) then
            RF_out1_mux <= MEM_LoadForward_dist1_in;--WB_LoadForward_dist2_in;
         else
            RF_out1_mux <= ForwardVal_dist1_in;
         end if;
         
      when Dist2=> 
         if (isLoadInsHistoryTable(1) = isLoad) then
            RF_out1_mux <= WB_LoadForward_dist2_in;
         else
            RF_out1_mux <= ForwardVal_dist2_in;
         end if;   
         
      when Dist3=>  
         if (isLoadInsHistoryTable(1) = isLoad) then
            RF_out1_mux <= RF_out1_inter;
         else
            RF_out1_mux <= ForwardVal_dist3_in;
         end if; 
         
      when others=>      null;
   end case;
   
   
   
   case FORWARD2_SEL is
      when NonForward=>  RF_out2_mux<=RF_out2_inter;
      when Dist1=>  
         if (isLoadInsHistoryTable(0) = isLoad) then
            RF_out2_mux <= MEM_LoadForward_dist1_in;--WB_LoadForward_dist2_in;
         else
            RF_out2_mux <= ForwardVal_dist1_in;
         end if;
         
      when Dist2=> 
         if (isLoadInsHistoryTable(1) = isLoad) then
            RF_out2_mux <= WB_LoadForward_dist2_in;
         else
            RF_out2_mux <= ForwardVal_dist2_in;
         end if;   
         
      when Dist3=>  
         if (isLoadInsHistoryTable(1) = isLoad) then
            RF_out2_mux <= RF_out2_inter;
         else
            RF_out2_mux <= ForwardVal_dist3_in;
         end if; 
      
      when others=>      null;
   end case;
 end process;
 -------------- forwarding select ------------


 
 -------------- forwarding history update ------------
 RD_ADDR_record_proc:
 process(CLK, nRST, pipe_enable_decode_in, RF_RD_decode_in)
 begin
    if (nRST = '0') then
       RD_ADDR_HisTable_Buf <= -1;
       RD_ADDR_HisTable(0) <= -1;
       RD_ADDR_HisTable(1) <= -1;
       RD_ADDR_HisTable(2) <= -1;
    elsif (pipe_enable_decode_in = '1')
      and rising_edge(CLK) then

       RD_ADDR_HisTable(2) <= RD_ADDR_HisTable(1);
       RD_ADDR_HisTable(1) <= RD_ADDR_HisTable(0);
       if (BranchRequest = AbsJumpWBR31) then
          RD_ADDR_HisTable(0) <= 31;
       else
          RD_ADDR_HisTable(0) <= RD_ADDR_HisTable_Buf;
       end if;
       RD_ADDR_HisTable_Buf <= RF_RD_decode_in;
    end if;
 end process;
 -------------- forwarding history update ------------
 
 
  -------------- forwarding logic ------------
 forward_logic_proc:
 process(RF_RS1_inter, RF_RS2_inter, CLK, RD_ADDR_HisTable, pipe_enable_decode_in)
 begin
    ---- oprand_1 forwarding logic
    if (RF_RS1_inter = RD_ADDR_HisTable(0)) then
        FORWARD1_SEL <= Dist1;
    elsif (RF_RS1_inter = RD_ADDR_HisTable(1)) then
        FORWARD1_SEL <= Dist2;
    elsif (RF_RS1_inter = RD_ADDR_HisTable(2)) then
        FORWARD1_SEL <= Dist3;
    else
        FORWARD1_SEL <= NonForward;
    end if;
    
    ---- oprand_2 forwarding logic
    if (RF_RS2_inter = RD_ADDR_HisTable(0)) then
        FORWARD2_SEL <= Dist1;
    elsif (RF_RS2_inter = RD_ADDR_HisTable(1)) then
        FORWARD2_SEL <= Dist2;
    elsif (RF_RS2_inter = RD_ADDR_HisTable(2)) then
        FORWARD2_SEL <= Dist3;
    else
        FORWARD2_SEL <= NonForward;
    end if;

 end process;
 -------------- forwarding logic ------------
 
 
 
 -------------- branch logic ---------------
 branch_logic_proc:
 process(NPC_decode_in, OFFSET_decode_in, IMME_decode_in, Oprand1_decode_out, Oprand2_decode_out, BranchRequest)
 begin

   case BranchRequest is
     -- op1 >= op2
     when IFop1GEop2=>  
        if (Oprand1_decode_out >= Oprand2_decode_out) then
           Branch_Taken_Result <= Taken;
        else
           Branch_Taken_Result <= NotTaken;
        end if;
     -- op1 > op2
     when IFop1GTop2=>  
        if (Oprand1_decode_out > Oprand2_decode_out) then
           Branch_Taken_Result <= Taken;
        else
           Branch_Taken_Result <= NotTaken;
        end if;
     -- op1 <= op2   
     when IFop1LEop2=>  
        if (Oprand1_decode_out <= Oprand2_decode_out) then
           Branch_Taken_Result <= Taken;
        else
           Branch_Taken_Result <= NotTaken;
        end if;
     -- op1 < op2   
     when IFop1LTop2=>  
        if (Oprand1_decode_out < Oprand2_decode_out) then
           Branch_Taken_Result <= Taken;
        else
           Branch_Taken_Result <= NotTaken;
        end if;
     -- op1 = op2   
     when IFop1EQop2=>  
        if (Oprand1_decode_out = Oprand2_decode_out) then
           Branch_Taken_Result <= Taken;
        else
           Branch_Taken_Result <= NotTaken;
        end if;
     -- op1 != op2 
     when IFop1NEop2=>  
        if (Oprand1_decode_out /= Oprand2_decode_out) then
           Branch_Taken_Result <= Taken;
        else
           Branch_Taken_Result <= NotTaken;
        end if;
     -- op1 = 0
     when IFop1EQ0=>  
        if (Oprand1_decode_out = 0) then
           Branch_Taken_Result <= Taken;
        else
           Branch_Taken_Result <= NotTaken;
        end if;
     -- op1 != 0
     when IFop1NE0=>  
        if (Oprand1_decode_out /= 0) then
           Branch_Taken_Result <= Taken;
        else
           Branch_Taken_Result <= NotTaken;
        end if;
     -- absolute jump
     when AbsJump=>
        Branch_Taken_Result <= Taken;
     -- absolute jump write back R31
     when AbsJumpWBR31=>
        Branch_Taken_Result <= Taken;
     -- no branch request
     when NoReq=>  
        Branch_Taken_Result <= NotTaken;  
     -- others   
     when others=>  Branch_Taken_Result <= NotTaken;
          
   end case;
 end process;
 
 -------------- branch logic ---------------
 
 
 -------------- branch processing -------------
 branch_processing_proc:
 process(BranchRequest, IMME_decode_in, OFFSET_decode_in, NPC_decode_in, Branch_Taken_Result)
 begin
    case Branch_Src is
       when srcIMME=>    srcOffsetChoosen <= (IMME_decode_in / 4);
       when srcOFFSET=>  srcOffsetChoosen <= OFFSET_decode_in;
       when others=>     null;
    end case;

    case Branch_Taken_Result is
       when Taken=>     FeedBackPC <= BranchTargetAddr;
       when NotTaken=>  FeedBackPC <= NPC_decode_in;
       when others=>    null;
    end case; 
 end process;
 BranchTargetAddr <= srcOffsetChoosen + NPC_decode_in +1;
 -------------- branch processing -------------
 
 
 -------------- decode stage output pipeline ----------------
 decode_pipeline_proc:
 process(CLK, Oprand1_decode_out, Oprand2_decode_out, pipe_enable_decode_in)
 begin
   if falling_edge(CLK) and (pipe_enable_decode_in = '1') then
     Oprand1_decode <= Oprand1_decode_out;
     Oprand2_decode <= Oprand2_decode_out;
     DataMemStoreDataIn_Decode <= RF_out2_mux; -- read from RF_out2 with forwarding
     if (BranchRequest = AbsJumpWBR31) then
        RF_RD_WriteBack_Decode <= 31;
     else
        RF_RD_WriteBack_Decode <= RF_RD_decode_in;
     end if;
   end if;
 end process;
 -------------- decode stage output pipeline ----------------
end asd;