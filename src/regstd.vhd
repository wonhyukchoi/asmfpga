library ieee;
use ieee.std_logic_1164.all;

entity regstd is
  generic(n: integer);
  port (clk, en: in std_ulogic;
        d_in: in std_ulogic_vector(n downto 0);
        q_out: out std_ulogic_vector(n downto 0));
end entity regstd;

architecture behav of regstd is
begin
  regstd_behavior: process is
  begin
    wait until rising_edge(clk);
    if en = '1' then
      q_out <= d_in;
    end if;
  end process regstd_behavior;
end architecture behav;