library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- https://stackoverflow.com/a/17454372/11801882
entity zeroExtend12to13 is
port(slv_12: in std_ulogic_vector(11 downto 0);
	  slv_13: out std_ulogic_vector(12 downto 0));
end entity zeroExtend12to13;

architecture dataflow of zeroExtend12to13 is
begin
    slv_13 <= std_ulogic_vector(resize(unsigned(slv_12), slv_13'length));
end dataflow;