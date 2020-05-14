library ieee;
use ieee.std_logic_1164.all;
library alu;

entity complement is
  generic(n: integer);
  port (inputVector: in std_ulogic_vector(n downto 0);
        twosComplement: out std_ulogic_vector(n downto 0));
end entity complement;

architecture structural of complement is
signal outputVector: std_ulogic_vector(n downto 0);
begin

notBits: alu.notVector 
	generic map(n => n)
	port map(
	inputVector => inputVector,
	outputVector => outputVector);

addition: alu.addVector 
	port map(
	a => outputVector,
	b => x"0001",
	f => twosComplement);

end architecture structural; 