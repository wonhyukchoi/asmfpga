library ieee;
use ieee.std_logic_1164.all;

entity andVector is
  generic(n: integer);
  port (op1Input, op2Input: in std_ulogic_vector(n downto 0);
        andOutput: out std_ulogic_vector(n downto 0));
end entity andVector;

architecture behavioral of andVector is
begin
  andGate: process(op1Input, op2Input)
		begin
      for i in n downto 0 loop
        andOutput(i) <= op1Input(i) and op2Input(i);
      end loop;
	end process andGate;
end architecture behavioral; 