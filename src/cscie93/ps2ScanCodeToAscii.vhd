-- synthesis library cscie93
library ieee;
use ieee.std_logic_1164.all;


entity ps2ScanCodeToAscii is
	port (
		scan_code : in std_logic_vector(7 downto 0);
		shift_down : in std_logic;
		
		is_printable : out std_logic;
		ascii : out std_logic_vector(7 downto 0)
	);
end;


architecture behavioral of ps2ScanCodeToAscii is
	signal shift_scan : std_logic_vector(8 downto 0);
	signal ascii_internal : std_logic_vector(7 downto 0);
begin

	shift_scan <= shift_down & scan_code;
	ascii <= ascii_internal;
	
	with shift_scan	select
		ascii_internal <= 
			X"61" when '0' & X"1C", -- a,
			X"41" when '1' & X"1C", -- A,
			X"62" when '0' & X"32", -- b,
			X"42" when '1' & X"32", -- B,
			X"63" when '0' & X"21", -- c,
			X"43" when '1' & X"21", -- C,
			X"64" when '0' & X"23", -- d,
			X"44" when '1' & X"23", -- D,
			X"65" when '0' & X"24", -- e,
			X"45" when '1' & X"24", -- E,
			X"66" when '0' & X"2B", -- f,
			X"46" when '1' & X"2B", -- F,
			X"67" when '0' & X"34", -- g,
			X"47" when '1' & X"34", -- G,
			X"68" when '0' & X"33", -- h,
			X"48" when '1' & X"33", -- H,
			X"69" when '0' & X"43", -- i,
			X"49" when '1' & X"43", -- I,
			X"6a" when '0' & X"3B", -- j,
			X"4a" when '1' & X"3B", -- J,
			X"6b" when '0' & X"42", -- k,
			X"4b" when '1' & X"42", -- K,
			X"6c" when '0' & X"4B", -- l,
			X"4c" when '1' & X"4B", -- L,
			X"6d" when '0' & X"3A", -- m,
			X"4d" when '1' & X"3A", -- M,
			X"6e" when '0' & X"31", -- n,
			X"4e" when '1' & X"31", -- N,
			X"6f" when '0' & X"44", -- o,
			X"4f" when '1' & X"44", -- O,
			X"70" when '0' & X"4D", -- p,
			X"50" when '1' & X"4D", -- P,
			X"71" when '0' & X"15", -- q,
			X"51" when '1' & X"15", -- Q,
			X"72" when '0' & X"2D", -- r,
			X"52" when '1' & X"2D", -- R,
			X"73" when '0' & X"1B", -- s,
			X"53" when '1' & X"1B", -- S,
			X"74" when '0' & X"2C", -- t,
			X"54" when '1' & X"2C", -- T,
			X"75" when '0' & X"3C", -- u,
			X"55" when '1' & X"3C", -- U,
			X"76" when '0' & X"2A", -- v,
			X"56" when '1' & X"2A", -- V,
			X"77" when '0' & X"1D", -- w,
			X"57" when '1' & X"1D", -- W,
			X"78" when '0' & X"22", -- x,
			X"58" when '1' & X"22", -- X,
			X"79" when '0' & X"35", -- y,
			X"59" when '1' & X"35", -- Y,
			X"7a" when '0' & X"1A", -- z,
			X"5a" when '1' & X"1A", -- Z,
			X"30" when '0' & X"45", -- 0,
			X"29" when '1' & X"45", -- 0,
			X"31" when '0' & X"16", -- 1,
			X"21" when '1' & X"16", -- 1,
			X"32" when '0' & X"1E", -- 2,
			X"40" when '1' & X"1E", -- 2,
			X"33" when '0' & X"26", -- 3,
			X"23" when '1' & X"26", -- 3,
			X"34" when '0' & X"25", -- 4,
			X"24" when '1' & X"25", -- 4,
			X"35" when '0' & X"2E", -- 5,
			X"25" when '1' & X"2E", -- 5,
			X"36" when '0' & X"36", -- 6,
			X"5e" when '1' & X"36", -- 6,
			X"37" when '0' & X"3D", -- 7,
			X"26" when '1' & X"3D", -- 7,
			X"38" when '0' & X"3E", -- 8,
			X"2a" when '1' & X"3E", -- 8,
			X"39" when '0' & X"46", -- 9,
			X"28" when '1' & X"46", -- 9,
			X"60" when '0' & X"0E", -- `,
			X"7e" when '1' & X"0E", -- `,
			X"2d" when '0' & X"4E", -- -,
			X"5f" when '1' & X"4E", -- -,
			X"3d" when '0' & X"55", -- =,
			X"2b" when '1' & X"55", -- =,
			X"5c" when '0' & X"5D", -- \\,
			X"7c" when '1' & X"5D", -- \\,
			X"5b" when '0' & X"54", -- [,
			X"7b" when '1' & X"54", -- [,
			X"2a" when '0' & X"7C", -- *,
			X"2a" when '1' & X"7C", -- *,
			X"2d" when '0' & X"7B", -- -,
			X"2d" when '1' & X"7B", -- -,
			X"2b" when '0' & X"79", -- +,
			X"2b" when '1' & X"79", -- +,
			X"2e" when '0' & X"71", -- .,
			X"2e" when '1' & X"71", -- .,
			X"30" when '0' & X"70", -- 0,
			X"30" when '1' & X"70", -- 0,
			X"31" when '0' & X"69", -- 1,
			X"31" when '1' & X"69", -- 1,
			X"32" when '0' & X"72", -- 2,
			X"32" when '1' & X"72", -- 2,
			X"33" when '0' & X"7A", -- 3,
			X"33" when '1' & X"7A", -- 3,
			X"34" when '0' & X"6B", -- 4,
			X"34" when '1' & X"6B", -- 4,
			X"35" when '0' & X"73", -- 5,
			X"35" when '1' & X"73", -- 5,
			X"36" when '0' & X"74", -- 6,
			X"36" when '1' & X"74", -- 6,
			X"37" when '0' & X"6C", -- 7,
			X"37" when '1' & X"6C", -- 7,
			X"38" when '0' & X"75", -- 8,
			X"38" when '1' & X"75", -- 8,
			X"39" when '0' & X"7D", -- 9,
			X"39" when '1' & X"7D", -- 9,
			X"5d" when '0' & X"5B", -- ],
			X"7D" when '1' & X"5B", -- ],
			X"3b" when '0' & X"4C", -- ;,
			X"3A" when '1' & X"4C", -- ;,
			X"27" when '0' & X"52", -- ',
			X"22" when '1' & X"52", -- ',
			X"2c" when '0' & X"41", -- ,,
			X"3C" when '1' & X"41", -- ,,
			X"2e" when '0' & X"49", -- .,
			X"3E" when '1' & X"49", -- .,
			X"2f" when '0' & X"4A", -- /,
			X"3F" when '1' & X"4A", -- /
			X"20" when '0' & X"29", -- space
			X"20" when '1' & X"29", -- space
			X"0D" when '0' & X"5A", -- Enter, we map to a single CR
			X"0D" when '1' & X"5A", -- Enter, we map to a single CR
			X"08" when '1' & X"66", -- backspace
			X"08" when '0' & X"66", -- backspace
			X"00" when others;
			
		with ascii_internal select
			is_printable <= '0' when X"00",
							'1' when others;

end;
