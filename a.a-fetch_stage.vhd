library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all; -- ****************
use ieee.std_logic_textio.all; -- ***********
use work.func_pkg.all;
use work.type_pkg.all;


entity FETCH_STAGE is
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
  
  ------ for program counter ---------
  Jmp_PC : in integer; -- from Decode stage
  PC_op : in PC_OP_type; -- from CU
  ------ for program counter ---------
  
  ------ for instruction mem ---------
  nRST : in std_logic; -- from external world
  filePath : in string -- from external world
  ------ for instruction mem ---------

);
end FETCH_STAGE;



architecture asd of FETCH_STAGE is
------------ internal signals-------------------
-- for PC
signal OUT_PC : integer;

-- for instruction mem
signal MEM_space : asynMEM_space_type;
signal insMEM_out : std_logic_vector(ins_bit_SIZE-1 downto 0);
------------ internal signals-------------------



begin
  ------------------ bhv of PC ----------------------
    PC_process: process(CLK, nRST)
                begin
                if (nRST = '0') then
                   OUT_PC <= 0;
                elsif rising_edge(CLK) then
                   case PC_op is
                      when PC_RESET=>  OUT_PC <= 0;
                      when PC_INCR =>  OUT_PC <= OUT_PC+PC_IncrSize;
                      when PC_JUMP =>  OUT_PC <= Jmp_PC;
                      when PC_LOCK =>  OUT_PC <= OUT_PC;
                      when others  =>  OUT_PC <= OUT_PC;
                   end case;
                end if;
              end process; 
------------------ bhv of PC ----------------------


----------------- insMEM_bhv -----------------------
  initialization: process(nRST)
                  file filein : TEXT; -- file handler
                  variable fstatus : FILE_OPEN_STATUS;
                  variable lineContent : LINE;
                  variable lineString : string(ins_bit_SIZE/4 downto 1);
                  variable bin_data : std_logic_vector(ins_bit_SIZE-1 downto 0);
                  variable index : integer; -- := 0;
                  
                  begin
                    if (nRST = '0') then
                       file_open(fstatus, filein , filePath, read_mode);
                       index := 0;
                       --if rising_edge(insMEM_CLK) and not endfile(filein) then
                          while not endfile(filein) loop
                            readline(filein, lineContent); -- read next line's content
                            read(lineContent, lineString); -- put line's content into a string variable
                            bin_data := hex_to_slv(lineString);
                            MEM_space(index) <= bin_data;
                            index := index + 1;
                          end loop;
                          MEM_space(index-1) <= (others=>'U');
                       --else -- rising and at the end of the file
                       --   NULL;
                       --end if;
                    end if;                    
                  end process;


  read_process: process(OUT_PC, nRST) 
                begin
                  if (nRST = '1') and (OUT_PC >= 0) then
                    insMEM_out <= MEM_space(OUT_PC);
                  end if;
                end process;
----------------- insMEM_bhv ----------------------- 


----------------- pipeline bhv of fetch stage -------------
  output_fetch_process: -- Instruction Register update at every falling edge of clk.
      process(CLK, insMEM_out, pipe_enable_fetch, nRST)
      variable RS1_field_val : integer;
      variable RS2_field_val : integer;
      variable RD_field_val : integer;
      variable OPCODE_field_val : std_logic_vector(insOPCODE_SIZE-1 downto 0);
      begin
        RS1_field_val := to_integer(unsigned(insMEM_out(ins_bit_SIZE-insOPCODE_SIZE-1 downto ins_bit_SIZE-insOPCODE_SIZE-insADDR_SIZE)));
        RS2_field_val := to_integer(unsigned(insMEM_out(ins_bit_SIZE-insOPCODE_SIZE-insADDR_SIZE-1 downto ins_bit_SIZE-insOPCODE_SIZE-(2*insADDR_SIZE))));
        RD_field_val := to_integer(unsigned(insMEM_out(insIMME_SIZE-1 downto insFUNC_SIZE)));  
        OPCODE_field_val := insMEM_out(ins_bit_SIZE-1 downto ins_bit_SIZE-insOPCODE_SIZE);
        
        if (nRST = '0') then
          OPCODE_fetch <= (others=>'0');
          FUNC_fetch <= (others=>'0');
          IMME_fetch <= 0;
          RS1_fetch <= 0;
          RS2_fetch <= 0;
          RD_fetch <= 0;
          OFFSET_fetch <= 0;
          NPC_fetch <= 0;
        elsif falling_edge(CLK) and (pipe_enable_fetch = '1') then
          OPCODE_fetch <= OPCODE_field_val;
          FUNC_fetch <= insMEM_out(insFUNC_SIZE-1 downto 0);
          IMME_fetch <= to_integer(signed(insMEM_out(insIMME_SIZE-1 downto 0)));
          if (OPCODE_field_val = "000000") or (OPCODE_field_val = "000001") then
             -- R-type / mult-type
             RS2_fetch <= RS2_field_val;
             RD_fetch <= RD_field_val;
          elsif (OPCODE_field_val(insOPCODE_SIZE-1 downto 1) = "00010") then
             -- b-type branch
             RS2_fetch <= -2;
             RD_fetch <= -3;
          elsif (OPCODE_field_val = "101011") then
             -- store type
             RS2_fetch <= RS2_field_val;
             RD_fetch <= -4;
          elsif (OPCODE_field_val = "UUUUUU")
             or (OPCODE_field_val = "010101")then
             -- nop/undefined
             RS2_fetch <= RS2_field_val;
             RD_fetch <= -5;  
          else
             -- general I-type or J-type
             RS2_fetch <= -2;
             RD_fetch <= RS2_field_val;
          end if;
          RS1_fetch <= RS1_field_val;
          OFFSET_fetch <= (to_integer(signed(insMEM_out(ins_bit_SIZE-insOPCODE_SIZE-1 downto 0))) / 4);
          NPC_fetch <= OUT_PC;
        end if;
      end process;
----------------- pipeline bhv of fetch stage -------------- 

end asd;