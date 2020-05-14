library ieee;
use ieee.std_logic_1164.all;

entity notVector is 
  generic(n: integer);
  port (inputVector: in std_ulogic_vector(n downto 0);
        outputVector: out std_ulogic_vector(n downto 0));
end entity notVector;

architecture behavioral of notVector is
begin
  invert: process(inputVector)
		begin
      for i in n downto 0 loop
        outputVector(i) <= not inputVector(i);
      end loop;
	end process invert;
end architecture behavioral; 