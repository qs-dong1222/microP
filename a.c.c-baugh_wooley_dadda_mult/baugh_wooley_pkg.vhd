library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package baugh_wooley_pkg is
------------------------ lab1_pkg ---------------------------------
constant NPIPE: integer := 5; -- size is exxluding an input and output register.
constant Nbits : integer := 11;
constant Ncoff : integer := 9;
constant N : integer := 32;
type SLV_VECTOR is array(integer range <>) of STD_LOGIC_VECTOR(Nbits - 1 downto 0);
type SLV32_VECTOR is array(integer range <>) of STD_LOGIC_VECTOR(32 - 1 downto 0);
function Rshift (VecTobeSF : signed(N-1 downto 0)) return signed;
-------------------------------------------------------------------

constant Nmult : integer := 13;
constant N_daddaLayers : integer := 6;
constant N_element : integer := Nmult+3;

type INT_VECTOR is array(integer range <>) of integer;
type ADDER_RES_VEC is array(integer range <>) of STD_LOGIC_VECTOR(1 downto 0);
type DOT_VEC is array(integer range <>) of std_logic_vector(N_element downto 0);

constant Lreqdot : INT_VECTOR(N_daddaLayers-1 downto 0) := (2, 3, 4, 6, 9, 13); --, 19, 28, 42);

function HalfAdder (A : std_logic; B :std_logic) return std_logic_vector;
function FullAdder (A : std_logic; B :std_logic; Cin : std_logic) return std_logic_vector;
end package baugh_wooley_pkg;

package body baugh_wooley_pkg is

function HalfAdder (A : std_logic; B :std_logic) return std_logic_vector is
variable result_vec : std_logic_vector(1 downto 0);
begin
  result_vec(0) := A xor B;
  result_vec(1) := A and B;
  return result_vec;
end function HalfAdder;


function FullAdder (A : std_logic; B :std_logic; Cin : std_logic) return std_logic_vector is
variable result_vec : std_logic_vector(1 downto 0);
begin
  result_vec(0) := A xor B xor Cin;
  result_vec(1) := (A and B) or (A and Cin) or (B and Cin);
  return result_vec;
end function FullAdder;


------------------------ lab1_pkg ---------------------------------
function Rshift (VecTobeSF : signed(N-1 downto 0)) return signed is
variable VecSFed : signed(N-1 downto 0);
begin
  VecSFed :=  VecTobeSF(N-1)
            & VecTobeSF(N-1)
            & VecTobeSF(N-1)
            & VecTobeSF(N-1)
            & VecTobeSF(N-1)
            & VecTobeSF(N-1)
            & VecTobeSF(N-1)
            & VecTobeSF(N-1)
            & VecTobeSF(N-1)
            & VecTobeSF(N-1)
            & VecTobeSF(N-1 downto 10);
  return VecSFed;

end function Rshift;
-------------------------------------------------------------------

end package body baugh_wooley_pkg;