library ieee;
use ieee.std_logic_1164.all;

entity copyVector is
  generic(n: integer);
  port (op2Input: in std_ulogic_vector(n downto 0);
        copyOutput: out std_ulogic_vector(n downto 0));
end entity copyVector;

architecture behavioral of copyVector is
begin
  copyGate: process(op2Input)
		begin
      for i in n downto 0 loop
        copyOutput(i) <= op2Input(i);
      end loop;
	end process copyGate;
end architecture behavioral; 