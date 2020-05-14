-- synthesis library cscie93
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera;
use altera.altera_primitives_components.all; 

library cscie93;

entity clockgen is
	port (
		clk50mhz : in std_logic;
		reset : in std_logic;
		run_clk : std_logic;
		single_step : std_logic;
		clock_divide_limit : in std_logic_vector(19 downto 0) := (others => '0');

		clk1raw : buffer std_logic;
		clk2raw : buffer std_logic;
		clk1 : out std_logic;
		clk2 : out std_logic;
		locked : out std_logic
	);
end;

architecture pll of clockgen is
	attribute keep : boolean;
	
	signal clk_enable : std_logic;
	signal q1,q2,q3 : std_logic;
	signal clock_divide_count : std_logic_vector(19 downto 0) := (others => '0');
	signal clock_divide_limit_internal : std_logic_vector(19 downto 0) := (others => '0');
	--attribute keep of q1 : signal is true;
	--attribute keep of q2 : signal is true;
	--attribute keep of q3 : signal is true;
begin

	pll : entity cscie93.mem_pll_interface(implemented) port map (
											areset=>reset, 
											inclk0 => clk50mhz, 
											enable => '1', 
											c0 => clk1raw, 
											c1 => clk2raw, 
											locked=>locked
										);
	clkctrl1 : cscie93.clock_ctrl port map (inclk => clk1raw, ena => clk_enable, outclk => clk1);
	clkctrl2 : cscie93.clock_ctrl port map (inclk => clk2raw, ena => clk_enable, outclk => clk2);

	-- one-shot triggered by single_step, synchronized to clk50mhz
	dff1 : dff port map (d => single_step, clk => clk50mhz, clrn => '1', prn=>'1', q=>q1);
	dff2 : dff port map (d => q1, clk => clk50mhz, clrn => '1', prn=>'1', q=>q2);
	dff3 : dff port map (d => q2, clk => clk50mhz, clrn => '1', prn=>'1', q=>q3);

	--clk_enable <= 	(q2 and not q3) or run_clk;
	clk_enable <= 	'1' when run_clk='0' and q2='1' and q3='0' else
						'1' when run_clk = '1' and clock_divide_count = X"00000" else
						'0' ;
	
	clock_divide_limit_internal <= clock_divide_limit;
	
	process(clk50mhz, clock_divide_limit_internal, clock_divide_limit) is
	begin
		if falling_edge(clk50mhz) then
			if clock_divide_limit_internal = X"00000" then
				clock_divide_count <= X"00000";
			else
				if clock_divide_count = X"00000" then
					clock_divide_count <= clock_divide_limit;
				else
					clock_divide_count <= std_logic_vector(unsigned(clock_divide_count) - 1);
				end if;
			end if;
		end if;
	end process;
	
end;


