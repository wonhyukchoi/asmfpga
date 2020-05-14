library ieee;
use ieee.std_logic_1164.all;

entity xorVector is
  generic(n: integer);
  port (op1Input, op2Input: in std_ulogic_vector(n downto 0);
        xorOutput: out std_ulogic_vector(n downto 0));
end entity xorVector;

architecture behavioral of xorVector is
begin
  xorGate: process(op1Input, op2Input)
		begin
      for i in n downto 0 loop
        xorOutput(i) <= op1Input(i) xor op2Input(i);
      end loop;
	end process xorGate;
end architecture behavioral; 