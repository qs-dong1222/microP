----------------------------------------------------------------------
-- Author : Qiu Shi
-- Fully generic Baugh-Wooley mult with Dadda arch by process only
-- Only things need to change are : 
-- 1. N_element, the # of bits for each column
-- 2. Lreqdot, element value in array AKA d=[2*1.5]
-- 3. N_daddaLayers, # of element according to 2.
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.baugh_wooley_pkg.all;

entity baugh_wooley_mult is 
port(
	A_in : in integer;
	B_in : in integer;
	P_out : out integer
);

end baugh_wooley_mult;


architecture asd of baugh_wooley_mult is
signal  A, B : std_logic_vector(Nmult-1 downto 0);
signal  Pout : std_logic_vector(2*Nmult-1 downto 0);

begin
	A <= std_logic_vector(to_signed(A_in, A'LENGTH));
	B <= std_logic_vector(to_signed(B_in, B'LENGTH));
	P_out <= to_integer(signed(Pout));

	organizeProc:
	process(A, B)
	variable P_dot_chain : DOT_VEC(2*Nmult-1 downto 0); -- column P0~P63
	variable P_dot_count : INT_VECTOR(2*Nmult-1 downto 0); -- number of dots in each column
	variable Nfa : integer;
	variable Nha : integer;
	variable NextraDots : integer;
	variable NshiftDots : integer;
	variable tempResult : std_logic_vector(1 downto 0);
	begin
		P_dot_chain := (others=>(others=>'0'));
		P_dot_count := (others=>0);
		Nfa := 0;
		Nha := 0;
		NextraDots := 0;
		NshiftDots := 0;
		
		columnLoop:
		for i in 0 to 2*Nmult-1 loop
			if (i < Nmult-1) then -- P0~30
				rowLoop_A:
				for j in 0 to i loop
					P_dot_chain(i)(j) := A(i-j) and B(j);
					P_dot_count(i) := P_dot_count(i)+1; -- update count for P(i)
				end loop rowLoop_A;
						
			elsif (i >= Nmult-1) and (i <= 2*Nmult-4) then -- P31~P60
				rowLoop_B:
				for j in 0 to (2*Nmult-i-2) loop -- i=31, 32, 33, ...
					if (j <= 2*Nmult-i-2-2) then -- j=0, 1, 2, ... , 29
						P_dot_chain(i)(j) := A(Nmult-2-j) and B(i-Nmult+2+j);
						P_dot_count(i) := P_dot_count(i)+1; -- update count for P(i)
					elsif (j = 2*Nmult-i-2-1) then -- j=30
						P_dot_chain(i)(j) := A(i-Nmult+2+j) nand B(Nmult-2-j);
						P_dot_count(i) := P_dot_count(i)+1; -- update count for P(i)
					elsif (j = 2*Nmult-i-2) then
						P_dot_chain(i)(j) := A(i+1-Nmult) nand B(Nmult-1);
						P_dot_count(i) := P_dot_count(i)+1; -- update count for P(i)
					else
						null;
					end if;
				end loop rowLoop_B;
				
				if (i = Nmult) then
					P_dot_chain(i)(Nmult-1) := '1';
					P_dot_count(i) := P_dot_count(i)+1; -- update count for P(i)
				end if;
				
			elsif (i = 2*Nmult-3) then -- P61
				P_dot_chain(i)(0) := A(Nmult-1) nand B(Nmult-2);
				P_dot_chain(i)(1) := A(Nmult-2) nand B(Nmult-1);
				P_dot_count(i) := P_dot_count(i)+2; -- update count for P(i)
			elsif (i = 2*Nmult-2) then -- P62
				P_dot_chain(i)(0) := A(Nmult-1) and B(Nmult-1);
				P_dot_count(i) := P_dot_count(i)+1; -- update count for P(i)
			elsif (i = 2*Nmult-1) then -- P63
				P_dot_chain(i)(0) := '1';
				P_dot_count(i) := P_dot_count(i)+1; -- update count for P(i)
			end if;
		end loop columnLoop;
		-------------------------------------------------------------------------------------
		
		
		
		compressLoop:
		for i in 0 to N_daddaLayers-1 loop -- each layer
			cmpDotWRTLreqdot:
			for j in 0 to 2*Nmult-1 loop -- each column
				--------------------------------------- P0~P63 -------------------------------------------
				if ( P_dot_count(j) > Lreqdot(i) ) and ( j /= 2*Nmult-1) then 
					NextraDots := P_dot_count(j) - Lreqdot(i);
					Nfa := NextraDots/2;
					Nha := NextraDots rem 2;
					NshiftDots := P_dot_count(j) - (2*Nha) - (3*Nfa);
					
					if (Nha /= 0) then -- only one half adder can be used at most
						tempResult := HalfAdder( P_dot_chain(j)(0), P_dot_chain(j)(1) );
						P_dot_chain(j)(0) := tempResult(0); -- sum
						P_dot_count(j) := P_dot_count(j) - 1; -- update this column's dot number
						P_dot_chain(j+1)(P_dot_count(j+1)) := tempResult(1); -- carry
						P_dot_count(j+1) := P_dot_count(j+1) + 1; -- update this column's dot number

						fullAdderLoop:
						for n in 0 to Nfa-1 loop
							tempResult := FullAdder( P_dot_chain(j)(2+3*n), P_dot_chain(j)(3+3*n), P_dot_chain(j)(4+3*n) );
							P_dot_chain(j)(1+n) := tempResult(0); -- sum
							P_dot_count(j) := P_dot_count(j) - 2;
							P_dot_chain(j+1)(P_dot_count(j+1)) := tempResult(1); -- carry
							P_dot_count(j+1) := P_dot_count(j+1) + 1;
						end loop fullAdderLoop;
						---- rest of dots shift towards up -------
						moveUp:
						for m in 0 to NshiftDots-1 loop
							P_dot_chain(j)( Nha+Nfa+m ) := P_dot_chain(j)( (Nha*2) + (Nfa*3) + m );
						end loop moveUp;
						--------- clean up ----------
						cleanUp1:
						for u in Nha+Nfa+NshiftDots to N_element loop
						  P_dot_chain(j)(u) := '0';
						end loop cleanUp1;
						
					elsif (Nha = 0) then -- only full adders are used
						onlyFullAdderLoop:
						for k in 0 to Nfa-1 loop
							tempResult := FullAdder( P_dot_chain(j)(3*k), P_dot_chain(j)(1+3*k), P_dot_chain(j)(2+3*k) );
							P_dot_chain(j)(k) := tempResult(0); -- sum
							P_dot_count(j) := P_dot_count(j) - 2;
							P_dot_chain(j+1)(P_dot_count(j+1)) := tempResult(1); -- carry
							P_dot_count(j+1) := P_dot_count(j+1) + 1;
						end loop onlyFullAdderLoop;
						---- rest of dots shift towards up -------
						shiftUp:
						for q in 0 to NshiftDots-1 loop
							P_dot_chain(j)( Nfa+q ) := P_dot_chain(j)( (Nfa*3)+q );
						end loop shiftUp;
						--------- clean up ----------
						cleanUp2:
						for u in Nfa+NshiftDots to N_element loop
						  P_dot_chain(j)(u) := '0';
						end loop cleanUp2;
					end if;
					
					Nha := 0;
					Nfa := 0;
				------------------------------------ P0~P63 -------------------------------------
				
				------------------------------------ P64 -------------------------------------
				elsif ( P_dot_count(j) > Lreqdot(i) ) and ( j = 2*Nmult-1) then
					NextraDots := P_dot_count(j) - Lreqdot(i);
					Nfa := NextraDots/2;
					Nha := NextraDots rem 2;
					NshiftDots := P_dot_count(j) - (2*Nha) - (3*Nfa);
					
					if (Nha /= 0) then -- only one half adder can be used at most
						P_dot_chain(j)(0) := HalfAdder( P_dot_chain(j)(0), P_dot_chain(j)(1) )(0); -- sum
						P_dot_count(j) := P_dot_count(j) - 1; -- update this column's dot number
						
						fullAdderLoop1:
						for n in 0 to Nfa-1 loop
							tempResult := FullAdder( P_dot_chain(j)(2+3*n), P_dot_chain(j)(3+3*n), P_dot_chain(j)(4+3*n) );
							P_dot_chain(j)(1+n) := tempResult(0); -- sum
							P_dot_count(j) := P_dot_count(j) - 2;
						end loop fullAdderLoop1;
						---- rest of dots shift towards up -------
						moveUp1:
						for m in 0 to NshiftDots-1 loop
							P_dot_chain(j)( Nha+Nfa+m ) := P_dot_chain(j)( (Nha*2) + (Nfa*3) + m );
						end loop moveUp1;
						--------- clean up ----------
						cleanUp3:
						for u in Nha+Nfa+NshiftDots to N_element loop
						  P_dot_chain(j)(u) := '0';
						end loop cleanUp3;
						
					elsif (Nha = 0) then -- only full adders are used
						onlyFullAdderLoop1:
						for k in 0 to Nfa-1 loop
							tempResult := FullAdder( P_dot_chain(j)(3*k), P_dot_chain(j)(1+3*k), P_dot_chain(j)(2+3*k) );
							P_dot_chain(j)(k) := tempResult(0); -- sum
							P_dot_count(j) := P_dot_count(i) - 2;
						end loop onlyFullAdderLoop1;
						---- rest of dots shift towards up -------
						shiftUp1:
						for q in 0 to NshiftDots-1 loop
							P_dot_chain(j)( Nfa+q ) := P_dot_chain(j)( (Nfa*3)+q );
						end loop shiftUp1;
						--------- clean up ----------
						cleanUp4:
						for u in Nfa+NextraDots to N_element loop
						  P_dot_chain(j)(u) := '0';
						end loop cleanUp4;
					end if;
					
					Nha := 0;
					Nfa := 0;
				------------------------------------ P64 -------------------------------------
				end if;
			end loop cmpDotWRTLreqdot;
		end loop compressLoop;


		------------------------ dummy out-----------------------
		Pout(0) <= P_dot_chain(0)(0);
		tempResult := HalfAdder(P_dot_chain(1)(0), P_dot_chain(1)(1));
		Pout(1) <= tempResult(0);
		P_dot_chain(2)(2) := tempResult(1);
		outLoop:
		for i in 2 to 2*Nmult-2 loop
			tempResult := FullAdder( P_dot_chain(i)(0), P_dot_chain(i)(1), P_dot_chain(i)(2) );
			Pout(i) <= tempResult(0);
			P_dot_chain(i+1)(2) := tempResult(1);
		end loop outLoop;
		tempResult := FullAdder( P_dot_chain(2*Nmult-1)(0), P_dot_chain(2*Nmult-1)(1), P_dot_chain(2*Nmult-1)(2) );
		Pout(2*Nmult-1) <= tempResult(0);
		------------------------ dummy out-----------------------
		
	end process;
	
end asd;
