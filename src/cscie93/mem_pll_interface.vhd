-- synthesis library cscie93
library ieee;
use ieee.std_logic_1164.all;

library cscie93;

ENTITY mem_pll_interface IS
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		enable : std_logic := '1';
		c0		: OUT STD_LOGIC ;
		c1		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
END mem_pll_interface;

architecture dummy of mem_pll_interface is
begin

	c0 <= inclk0;
	c1 <= not inclk0;
	
	locked <= '1';
	
end;



architecture implemented of mem_pll_interface is
begin

	-- pll : cscie93.mem_pll port map (areset => areset, inclk0 => inclk0, pllena=>enable, c0 => c0, c1 => c1, locked=>locked);
	-- no pllenabme generated on Cyclone4, was hardcoded to 1 anyway
	pll : cscie93.mem_pll port map (areset => areset, inclk0 => inclk0, c0 => c0, c1 => c1, locked=>locked);

end;



