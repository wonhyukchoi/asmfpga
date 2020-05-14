library ieee;
use ieee.std_logic_1164.all;


entity sr_latch is 
	port (
		s : in std_logic;
		r : in std_logic;
		clr : in std_logic := '0';
		
		q : buffer std_logic := '0'
	);
end;

architecture arch of sr_latch is
begin

	-- set-dominant SR latch
	process(s, r, clr) is
	begin
		if clr = '1' then 
			q <= '0';
		elsif s='1' then -- set dominates
			q <= '1';
		elsif s='0' and r='1' then
			q <='0';
		end if;
	end process;

end;
