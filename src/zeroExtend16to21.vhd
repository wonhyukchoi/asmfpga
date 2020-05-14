library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- https://stackoverflow.com/a/17454372/11801882
entity zeroExtend16to21 is
port(slv_16: in std_ulogic_vector(15 downto 0);
	  slv_21: out std_ulogic_vector(20 downto 0));
end entity zeroExtend16to21;

architecture dataflow of zeroExtend16to21 is
begin
    slv_21 <= std_ulogic_vector(resize(unsigned(slv_16), slv_21'length));
end dataflow;