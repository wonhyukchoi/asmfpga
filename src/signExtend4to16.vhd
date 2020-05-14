library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- https://stackoverflow.com/a/17454372/11801882
entity signExtend4to16 is
port(slv_4: in std_ulogic_vector(3 downto 0);
	  slv_16: out std_ulogic_vector(15 downto 0));
end entity signExtend4to16;

architecture dataflow of signExtend4to16 is
begin
    slv_16 <= std_ulogic_vector(resize(signed(slv_4), slv_16'length));
end dataflow;