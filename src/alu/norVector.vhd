library ieee;
use ieee.std_logic_1164.all;

entity norVector is
  generic(n: integer);
  port (op1Input, op2Input: in std_ulogic_vector(n downto 0);
        norOutput: out std_ulogic_vector(n downto 0));
end entity norVector;

architecture behavioral of norVector is
begin
  norGate: process(op1Input, op2Input)
		begin
      for i in n downto 0 loop
        norOutput(i) <= op1Input(i) nor op2Input(i);
      end loop;
	end process norGate;
end architecture behavioral; 