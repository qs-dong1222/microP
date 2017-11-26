library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.func_pkg.all;
use work.type_pkg.all;

entity RF_generic is
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
end RF_generic;

architecture asd of RF_generic is
  -- subtype define address
  subtype REG_INDEX is natural range (RF_REG_SIZE-1) downto 0;
  -- define register file
	type REG_FILE is array(REG_INDEX) of std_logic_vector(RF_BIT_SIZE-1 downto 0); -- define an array having 1-32 elements which has 64 bits
	signal REGISTERS : REG_FILE; 
  
  
begin
  
  CTRL_process: process(CLK, nRESET, ENABLE, ADD_RD1, ADD_RD2, ADD_WR)
                begin
                  if nRESET = '0' then
                      OUT1 <= 0;
                      OUT2 <= 0;
                      for i in 0 to RF_REG_SIZE-1 loop
                        REGISTERS(i) <= std_logic_vector(to_signed(0, RF_BIT_SIZE));
                      end loop;
                  elsif rising_edge(CLK) and (ENABLE = '1') then            
                      if ((WR = '1') and ((ADD_WR rem RF_REG_SIZE) /= 0) and (ADD_WR >= 0))  then
                         REGISTERS(ADD_WR) <= std_logic_vector(to_signed(DATAIN, RF_BIT_SIZE));          
                      end if;
                  end if;
                  
                  if (RD1 = '1') and (ADD_RD1 >= 0) then
                      OUT1 <= to_integer(signed(REGISTERS(ADD_RD1)));
                  end if;
                  
                  if RD2 = '1' and (ADD_RD2 >= 0)then
                      OUT2 <= to_integer(signed(REGISTERS(ADD_RD2)));
                  end if;
                end process;
  
end asd;
