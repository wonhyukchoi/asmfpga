library ieee;
use ieee.std_logic_1164.all;
library alu;

entity fullAdder is
	port(a,b,cin: in std_logic;
			f, cout: out std_logic);
end entity fullAdder;

architecture structural of fullAdder is
signal temp_f : std_logic;
signal temp_c1 : std_logic;
signal temp_c2 : std_logic;
begin
	u0: alu.halfAdder port map( 
	a => a,
	b => b,
	f => temp_f,
	c => temp_c1);
	
	u1: alu.halfAdder port map(  
	a => temp_f,
	b => cin,
	f => f,
	c => temp_c2);
	
	cout <= temp_c1 or temp_c2;
end architecture structural;
	