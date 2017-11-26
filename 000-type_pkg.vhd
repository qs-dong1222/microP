library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package type_pkg is
  -- WORD_SIZE should correspons to the length of content in .txt file, here is 32bits for MIPS ISA
  constant ins_bit_SIZE : integer := 32; -- instruction length, i.e. # of bits
  constant insMEM_SIZE : integer := 128; -- 128 instructions space in total, i.e. 128 x 32bits
  type asynMEM_space_type is array(insMEM_SIZE-1 downto 0) of std_logic_vector(ins_bit_SIZE-1 downto 0);
  type Data_history_table is array(integer range <>) of integer;
  
  ----------------------- PC -------------------------
  type PC_OP_type is (PC_RESET, PC_INCR, PC_JUMP, PC_LOCK);
  constant PC_IncrSize : integer := 1;
  
  constant insOPCODE_SIZE : integer := 6;
  constant insFUNC_SIZE : integer := 11;
  constant insIMME_SIZE : integer := 16;
  constant insADDR_SIZE : integer := 5;
  constant insOFFSET_SIZE : integer := 26;
  ----------------------- PC -------------------------
  
  
  ----------------------- CU -------------------------
  type isLoadIns_type is (isLoad, notLoad);
  type isDivIns_type is (isDiv, notDiv);
  type isLoadInsHistory_Table_type is array(integer range <>) of isLoadIns_type;
  type Current_CTRL_Flush_type is (FLUSH, NORMAL);
  ----------------------- CU -------------------------
  
  ---------------- forwarding ------------------
  type FORWARD_SEL_type is (NonForward, Dist1, Dist2, Dist3);
  ---------------- forwarding ------------------
  
  
  ------------------- RF -------------------------
  type RF_ADDR_ALLCATE_OP_type is (R0toRS1, RS1toRS1,
                                   R0toRS2, RS2toRS2);
  type RF_OUT_SEL_type is (ReadValSel, ImmeValSel, Jal8ValSel);
  constant RF_BIT_SIZE : integer := 32;
  constant RF_REG_SIZE : integer := 32;
  ------------------- RF -------------------------
  
  
  ------------------ branch -----------------
  type BRANCH_REQ_type is (IFop1GEop2, IFop1GTop2, IFop1LEop2, IFop1LTop2
                          ,IFop1EQop2, IFop1NEop2, IFop1EQ0, IFop1NE0
                          ,AbsJump, AbsJumpWBR31, NoReq);
  type BRANCH_TAKEN_RESULT_type is (Taken, NotTaken);
  type BRANCH_OFFSET_SRC_type is (srcIMME, srcOFFSET);
  ------------------ branch -----------------
  
  
  ------------------ instruction set ------------------
  type INSTRUCTION_type is (INS_sll,  INS_srl,  INS_sra,  INS_add
                           ,INS_sub,  INS_and,  INS_or,   INS_xor
                           ,INS_seq,  INS_sne,  INS_sle,  INS_sge
                           ,INS_sgt,  INS_div,  INS_mult, INS_addi
                           ,INS_subi, INS_andi, INS_ori,  INS_xori
                           ,INS_nop,  INS_srli, INS_slli, INS_srai
                           ,INS_seqi, INS_snei, INS_slti, INS_sgti
                           ,INS_slei, INS_sgei, INS_lw,   INS_sw
                           ,INS_beqz, INS_bnez, INS_j,    INS_jal);
  ------------------ instruction set ------------------
  
  
  ------------------ alu ------------------
  type ALU_OP_type is (add_op, sub_op, mul_op, div_op, rem_op, and_op, or_op, xor_op
                    ,logic_L_shift_op,logic_R_shift_op, arith_L_shift_op, arith_R_shift_op
                    ,set_op1EQop2, set_op1NEop2, set_op1GTop2, set_op1LTop2, set_op1GEop2
                    ,set_op1LEop2, nop_op);
  ------------------ alu ------------------
  
  
  
  ------------------ memory stage -------------------
  constant DataMemory_ADDR_SIZE : integer := 64;
  type DataMemSpace is array(DataMemory_ADDR_SIZE-1 downto 0) of integer;
  type MEMstageOutValSel_type is (DataMemReadVal, ALUinVal, void);
  ------------------ memory stage -------------------
  
end package type_pkg;
