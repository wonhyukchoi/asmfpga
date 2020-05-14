library ieee;
use ieee.std_logic_1164.all;

entity orVector is
  generic(n: integer);
  port (op1Input, op2Input: in std_ulogic_vector(n downto 0);
        orOutput: out std_ulogic_vector(n downto 0));
end entity orVector;

architecture behavioral of orVector is
begin
  orGate: process(op1Input, op2Input)
		begin
      for i in n downto 0 loop
        orOutput(i) <= op1Input(i) or op2Input(i);
      end loop;
	end process orGate;
end architecture behavioral; 