library ieee;
use ieee.std_logic_1164.all;

entity regstdResetable is
  generic(n: integer);
  port (clk, en: in std_ulogic;
		  reset: in std_ulogic;
        d_in: in std_ulogic_vector(n downto 0);
        q_out: out std_ulogic_vector(n downto 0));
end entity regstdResetable;

architecture behav of regstdResetable is
begin
  regstd_behavior: process(reset, clk) is
  begin
	 if reset = '1' then 
		q_out <= x"0000";
	 elsif rising_edge(clk) then 
		 if en = '1' then
			q_out <= d_in;
		 end if;
	 end if;
  end process regstd_behavior;
end architecture behav;