library ieee;
use ieee.std_logic_1164.all;
library alu;

-- Can't use generic becuase re-using old bit8Adder which should be refactored

-- Returns 0 if op1 < op2. 
-- Is this confusing? I think so. 
-- But it makes it easier to use beq.
-- But I should just modify my design to make it more intuitive.
-- Let there be dragons...

entity sltVector is
  generic(n: integer);
  port (op1Input, op2Input: in std_ulogic_vector(n downto 0);
        sltOutput: out std_ulogic_vector(15 downto 0));
end entity sltVector;

architecture structural of sltVector is
signal op2Complement: std_ulogic_vector(n downto 0);
signal subResult: std_ulogic_vector(n downto 0);

begin

complementOp2: alu.complement 
	generic map(n => n)
	port map(
	inputVector => op2Input,
	twosComplement => op2Complement);
	
subtraction: alu.addVector 
	port map(
	a => op1Input,
	b => op2Complement,
	f => subResult);

	
-- Determines sign from the high most bit	
sltOutput <= x"0001" when subResult(n) = '0' else
       x"0000"; -- subResult(n) = '1' 

end architecture structural; 