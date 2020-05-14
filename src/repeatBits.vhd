library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity repeatBits is
port(one_bit: in std_ulogic;
	  sixteen_bits: out std_ulogic_vector(15 downto 0));
end entity repeatBits;

architecture dataflow of repeatBits is
begin
    sixteen_bits <= one_bit & one_bit & one_bit & one_bit & 
						  one_bit & one_bit & one_bit & one_bit & 
						  one_bit & one_bit & one_bit & one_bit & 
						  one_bit & one_bit & one_bit & one_bit;
end dataflow;