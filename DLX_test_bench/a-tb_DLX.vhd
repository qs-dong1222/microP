library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.func_pkg.all;
use work.type_pkg.all;

entity tb_DLX is
end tb_DLX;


architecture asd of tb_DLX is
----------- sim component ----------
component DLX is
port(
CLK : in std_logic;
nRST : in std_logic;
filePath : in string -- from external world
);
end component;
------------------------------------

----------- sim signal -------------
signal sim_CLK : std_logic := '1';
signal sim_nRST : std_logic;
signal sim_filePath : string(68 downto 1) := "F:\VirtualBox\Ubuntu_64_VirtualDisk\share\assembler.bin\Jump.asm.txt";
------------------------------------  
  
begin
  simmap: DLX
          port map(
          sim_CLK
         ,sim_nRST
         ,sim_filePath
          );
 
 
  CLK_proc:
  process
  begin
    sim_CLK <= not sim_CLK;
    wait for 2 ns;
  end process;
  
  
  sim_proc:
  process
  begin
    sim_nRST <= '1';
    wait for 1 ns;
    
    sim_nRST <= '0';
    wait for 2 ns;
    
    sim_nRST <= '1';
    wait for 10 us;
  end process; 
end asd;