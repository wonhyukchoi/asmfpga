-- synthesis library cscie93
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_controller is
	port (
		clk : in std_logic;
		reset : in std_logic;
		
		fifo_empty : in std_logic;
		fifo_q : in std_logic_vector(7 downto 0);
		
		lcd_en : out std_logic;
		lcd_on : out std_logic;
		lcd_rs : out std_logic;
		lcd_rw : out std_logic;
		lcd_db : inout std_logic_vector(7 downto 0);
		
		fifo_rdack : out std_logic;
		
		dbg_ddram_addr : out std_logic_vector(7 downto 0)
	);
end;

architecture arch of lcd_controller is
	type States is 
	(
		Init, Init1, Init2, InitCLS, WaitCLS, Init3, 
		WriteAddr, 
		Done, Error, Reinit,
		WaitChar, WaitChar2, GrabChar, GrabbedChar, WaitCharComplete,
		GotCharWriteAddr, GotCharWriteAddrWait, GotCharWriteChar, GotEnter, GotEnterCls, 
		AckFifoCls, AckFifo
	);
	
	constant CLOCKEN_DIVISOR : integer := 4000;

	signal current_state : States := Init;
	signal fsm_clken : std_logic;
	
	signal lcd_data : std_logic_vector(9 downto 0);
	signal enable_lcd_clk : std_logic;
	
	signal ddram_addr : std_logic_vector(6 downto 0) := "0000000";
	signal ddram_addr_next : std_logic_vector(6 downto 0);
	
	signal fifo_char : std_logic_vector(7 downto 0);
	
	signal fifo_rdack_internal : std_logic := '0';
	
begin

	dbg_ddram_addr <= '0' & ddram_addr;
	fifo_rdack <= fifo_rdack_internal;

	lcd_on <= '1';
	lcd_rs <= lcd_data(9);
	lcd_rw <= lcd_data(8);
	lcd_db <= lcd_data(7 downto 0);
	
	lcd_en <= enable_lcd_clk; --and clk and fsm_clken;
	
	--fifo_rdack <= 	'1' when (current_state=AckFifo or current_state=AckFifoCls) and fsm_clken='1'
  --						else '0';

		-- generate clock enable to slow us waaayyyy down from 50Mhz
	generate_clk_en : process(clk) is
		variable n : integer := CLOCKEN_DIVISOR;
	begin
		if rising_edge(clk) then
			n := n-1;
			if n=0 then
				fsm_clken <= '1';
				n:= CLOCKEN_DIVISOR;
			else
				fsm_clken <= '0';
			end if;
		end if;
	end process;

	
	FSM : process(clk, fsm_clken, reset) is
		variable iWait : integer := 600;
		variable iCLS : integer := 40;
		variable iWriteAddrWait : integer := 600;
	begin
		if reset = '1' then
			current_state <= Reinit;
			iWait := 600;
			iCLS := 40;
			ddram_addr <= "0000000";
			
			fifo_rdack_internal <= '0';
		elsif rising_edge(clk) and fsm_clken='1' then
			case current_state is
				when Reinit =>
					fifo_rdack_internal <= '0';
					
					if iCLS = 0 then
						current_state <= Init;
						iCLS := 40;
					else
						iCLS := iCLS-1;
					end if;
				when Init =>
					if iWait = 0 then
						current_state <= Init1;
					else
						iWait := iWait - 1;
					end if;
				when Init1 =>
					current_state <= Init2;
					
				when Init2 =>
					current_state <= InitCLS;
					
				when InitCLS =>
					current_state <= WaitCLS;
					
				when WaitCLS =>
					if iCLS = 0 then
						iCLS := 40;
						current_state <= Init3;
					else
						iCLS := iCLS-1;
					end if;
					
				when Init3 =>
					ddram_addr <= "0000000";
					current_state <= WriteAddr;
				
				when WriteAddr =>
					current_state <= WaitChar;
				
				when Done =>
					if iWait = 0 then
						current_state <= WriteAddr;
					else
						iWait := iWait - 1;
					end if;
				
				when WaitChar =>
					if fifo_empty = '0' then
						fifo_rdack_internal <= '1';
						current_state <= WaitChar2;
					end if;
				when WaitChar2 =>
					fifo_rdack_internal <= '0';
					current_state <= GrabChar;
					
				when GrabChar =>
					fifo_char <= fifo_q;
					current_state <= GrabbedChar;
					
				when GrabbedChar =>
					fifo_rdack_internal <= '0';
					current_state <= WaitCharComplete;
				
				when WaitCharComplete =>
					if fifo_char = X"0a" then
						-- linefeed
						--ddram_addr(6) <= not ddram_addr(6);
						ddram_addr <= (6=>not ddram_addr(6), others=>'0');
						if ddram_addr(6) = '1' then
							-- currently on second line so CR puts us to first line: do a CLS
							current_state <= GotEnterCls;
						else
							current_state <= GotEnter;
						end if;
					elsif fifo_char = X"0d" then
						-- cr
						ddram_addr <= (6=>ddram_addr(6),others=>'0');
							current_state <= GotEnter;
					elsif fifo_char = X"08" then
						-- backspace
						if ddram_addr = "0000000" then
							ddram_addr <= "1001111";
						elsif ddram_addr = "1000000" then
							ddram_addr <= "0001111";
						else
							ddram_addr <= std_logic_vector(unsigned(ddram_addr)-1);
						end if;
						current_state <= GotEnter;
					else
						current_state <= GotCharWriteAddr;
					end if;
					
				when GotCharWriteAddr =>
					iWriteAddrWait := 600;
					current_State <= GotCharWriteAddrWait;
					
				when GotCharWriteAddrWait =>
					if iWriteAddrWait = 0 then
						current_State <= GotCharWriteChar;
					else 
						iWriteAddrWait := iWriteAddrWait - 1;
					end if;
				
				when GotCharWriteChar =>
					ddram_addr <= ddram_addr_next;
					current_state <= AckFifo;
					
					
				when AckFifo =>
					current_state <= WaitChar;
						
				when GotEnter =>
					current_state <= AckFifo;
					
				when GotEnterCls =>
					current_state <= AckFifoCls;
									
				when AckFifoCls =>
					current_state <= InitCLS;
				
				when Error =>
					current_state <= Error;
					
				when others =>
					current_state <= Error;
			end case;
		end if;
	end process;
	
	with current_state select
		lcd_data <=	"0000111100" when Init1,
					"0000001111" when Init2,
					"0000000001" when InitCLS,
					"0000000110" when Init3,
					"001" & ddram_addr when WriteAddr | GotCharWriteAddr | GotEnter | GotEnterCls,
					"10" & fifo_char when GotCharWriteChar,
					"01ZZZZZZZZ" when others;
	
	with current_state select
		enable_lcd_clk <=	'1' when Init1 | Init2 | InitCLS | Init3 | WriteAddr | GotCharWriteAddr | GotCharWriteChar | GotEnter | GotEnterCls,
							'0' when others;
	
	ddram_addr_next <=  "1000000" when ddram_addr = "0001111"
						else "0000000" when ddram_addr = "1001111"
						else std_logic_vector(unsigned(ddram_addr) + 1);
	
end;
