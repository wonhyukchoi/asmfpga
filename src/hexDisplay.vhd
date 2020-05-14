library ieee;
use ieee.std_logic_1164.all;

entity hexDisplay is
port(bin: in std_ulogic_vector(3 downto 0); 
		display: out std_ulogic_vector(6 downto 0));
end entity hexDisplay;

architecture dataflow of hexDisplay is
begin
display <= "1000000" when bin = "0000" else
       "1111001" when bin = "0001" else
       "0100100" when bin = "0010" else
       "0110000" when bin = "0011" else
       "0011001" when bin = "0100" else
       "0010010" when bin = "0101" else
       "0000010" when bin = "0110" else
       "1111000" when bin = "0111" else
       "0000000" when bin = "1000" else
       "0011000" when bin = "1001" else
       "0001000" when bin = "1010" else
       "0000011" when bin = "1011" else
       "1000110" when bin = "1100" else
       "0100001" when bin = "1101" else
       "0000110" when bin = "1110" else
       "0001110" when bin = "1111" else
       (others => 'X');
		 
end architecture dataflow;