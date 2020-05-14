-- synthesis library cscie93
library ieee;
use ieee.std_logic_1164.all;

library cscie93;

entity ram_interface is
	port (
			address		: IN STD_LOGIC_VECTOR (14 DOWNTO 0);
			byteena		: IN STD_LOGIC_VECTOR (1 DOWNTO 0) :=  (OTHERS => '1');
			clken		: IN STD_LOGIC  := '1';
			clock		: IN STD_LOGIC  := '1';
			data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			wren		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
end;

architecture dummy of ram_interface is
  signal mem_contents : std_logic_vector(15 downto 0) := X"ABCD";
  
begin

  process(clock, clken) is
  begin
    if rising_edge(clock) and clken='1' then
      if wren='1' then
        mem_contents <= mem_contents(14 downto 0) & mem_contents(15);
      else
        q <= mem_contents;
      end if;
    end if;
  end process; 
end;


architecture implemented of ram_interface is
begin

	ram : cscie93.ram port map (
				address=>address(14 downto 0),
				byteena => byteena,
				clken => clken,
				clock => clock,
				data => data,
				wren => wren,
				q => q
			);

end;

