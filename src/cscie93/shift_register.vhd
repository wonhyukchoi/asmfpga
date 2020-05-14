-- synthesis library cscie93
library ieee;
use ieee.std_logic_1164.all;



entity shift_register is
	generic (WIDTH : positive);
	port (
		clk_n : in std_logic;
		data_in : in std_logic;
		shift_enable : in std_logic;
		data_out : out std_logic_vector(WIDTH-1 downto 0);
		carry_out : out std_logic
	);
end;


architecture structural of shift_register is
	signal data : std_logic_vector(WIDTH-1 downto 0);
begin
	
	data_out <= data;
	
	compose : for i in 1 to WIDTH-1 generate
	begin
		generate_shift_process : process(clk_n, shift_enable, data) is
		begin
			if shift_enable='1' and falling_edge(clk_n) then
				data(i-1) <= data(i);
			end if;
		end process generate_shift_process;
	end generate compose;
	
	shift_process : process(clk_n, shift_enable, data_in) is
	begin
		if shift_enable='1' and falling_edge(clk_n) then
			data(WIDTH-1) <= data_in;
			carry_out <= data(0);
		end if;
	end process shift_process;
	
end;