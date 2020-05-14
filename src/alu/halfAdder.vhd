library ieee;
use ieee.std_logic_1164.all;

entity halfAdder is
	port(a,b: in std_logic;
			f,c: out std_logic);
end entity halfAdder;

architecture dataflow of halfAdder is
begin
	f <= a xor b;
	c <= a and b;
end architecture dataflow;