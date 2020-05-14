library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- https://stackoverflow.com/a/17454372/11801882
entity signExtend16to32 is
port(slv_16: in std_ulogic_vector(15 downto 0);
	  slv_32: out std_ulogic_vector(31 downto 0));
end entity signExtend16to32;

architecture dataflow of signExtend16to32 is
begin
    slv_32 <= std_ulogic_vector(resize(signed(slv_16), slv_32'length));
end dataflow;