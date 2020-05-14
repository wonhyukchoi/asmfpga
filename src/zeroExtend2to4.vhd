library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- https://stackoverflow.com/a/17454372/11801882
entity zeroExtend2to4 is
port(slv_2: in std_ulogic_vector(1 downto 0);
	  slv_4: out std_ulogic_vector(3 downto 0));
end entity zeroExtend2to4;

architecture dataflow of zeroExtend2to4 is
begin
    slv_4 <= std_ulogic_vector(resize(unsigned(slv_2), slv_4'length));
end dataflow;