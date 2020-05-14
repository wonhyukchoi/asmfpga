-- synthesis library cscie93
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library cscie93;

entity keyboard_interface is
	port (
		clk : in std_logic; -- clk from controller
		clk2 : in std_logic; -- clk2 from controller, out-of-phase with clk
		ps2_clk : in std_logic;
		ps2_data : in std_logic;
		reset : in std_logic;
		clear_buffer : in std_logic;
		
		fifo_q : out std_logic_vector(7 downto 0);
		fifo_has_data : out std_logic;
		fifo_rdreq : std_logic; -- clocks on clk2 rising edge
		
		-- debugging outputs
		last_scan_code : out std_logic_vector(7 downto 0);
		state_code : out std_logic_vector(3 downto 0)
	);
end;


architecture structural of keyboard_interface is
	type States is 
	(
		Init, 
		WaitKB,
		WaitKBRecovered,
		KBGotF0,
		KBGotF0Wait,
		KBCompleteBreakCode,
		KBGotChar,
		KBIgnoreChar,
		Error
	);
	
	signal current_state : States := Init;

	signal ps2_rcv_ok : std_logic := '0';
	signal ps2_rcv_ok_temp : std_logic := '0';
	signal ps2_rcv_ok_ungated : std_logic;
	
	signal ps2_rcv_err : std_logic;
	signal ps2_scan_code : std_logic_vector(7 downto 0);
	signal ps2_shift : std_logic;
	signal decoder_is_printable : std_logic;
	signal decoder_ascii : std_logic_vector(7 downto 0);
	signal kbfifo_wrreq : std_logic;
	signal kbfifo_rdempty : std_logic;
	signal kbfifo_wrfull : std_logic;
begin
	
	fifo_has_data <= not kbfifo_rdempty;

	ps2rcv : entity cscie93.ps2KeyboardReceiver port map (
					ps2_clk => ps2_clk, ps2_data => ps2_data, rcv_ok => ps2_rcv_ok_ungated, rcv_error => ps2_rcv_err,
					data_out => ps2_scan_code, shift_key_down => ps2_shift, isBreakCode => open 
			);

	decoder : entity cscie93.ps2ScanCodeToAscii port map (
						scan_code => ps2_scan_code, shift_down => ps2_shift, is_printable => decoder_is_printable, ascii => decoder_ascii
					);
		
	fifo_kb : entity cscie93.char_fifo port map (
						aclr=>reset or clear_buffer, data => decoder_ascii, 
						rdclk => clk2, rdreq=>fifo_rdreq, 
						wrclk => clk2, wrreq=>kbfifo_wrreq,
						q => fifo_q, rdempty=>kbfifo_rdempty, wrfull=>kbfifo_wrfull
					);
			
	-- to help sync clk and ps2_clk clock domains
	GateRcvOk : process(clk2,reset) is
	begin
		if reset='1' then
			ps2_rcv_ok_temp <= '0';
			ps2_rcv_ok <= '0';
		elsif rising_edge(clk2) then
			ps2_rcv_ok_temp <= ps2_rcv_ok_ungated;
			ps2_rcv_ok <=  ps2_rcv_ok_temp;
		end if;
	end process;
			
	FSM : process(clk, reset) is
		variable watchdog_counter : unsigned(7 downto 0) := (others=>'0');
	begin
		if reset = '1' then
			current_state <= Init;
		elsif rising_edge(clk) then
			case current_state is
				when Init =>
						current_state <= WaitKB;
					
				when WaitKB =>
					if ps2_rcv_ok = '1' then
						if ps2_scan_code = X"F0" then
							current_state <= KBGotF0;
						elsif decoder_is_printable = '1' then
							current_state <= KBGotChar;
						else
							current_state <= KBIgnoreChar;
						end if;
					end if;
					
				when WaitKBRecovered =>
					if ps2_rcv_ok = '1' then
						if ps2_scan_code = X"F0" then
							current_state <= KBGotF0;
						elsif decoder_is_printable = '1' then
							current_state <= KBGotChar;
						else
							current_state <= KBIgnoreChar;
						end if;
					end if;					
				when KBGotF0 =>
					if ps2_rcv_ok = '0' then
						current_state <= KBGotF0Wait;
					end if;
				
				when KBGotF0Wait =>
					if ps2_rcv_ok = '1' then
						current_state <= KBCompleteBreakCode;
					end if;
					
				when KBIgnoreChar =>
					if ps2_rcv_ok = '0' then
						current_state <= WaitKB;
					end if;
				
				when KBCompleteBreakCode =>
					if ps2_rcv_ok = '0' then
						current_state <= WaitKB;
					end if;
				
				when KBGotChar=>
					last_scan_code <= ps2_scan_code;
					current_state <= KBIgnoreChar;
					
				when Error =>
					watchdog_counter := watchdog_counter+1;
					if watchdog_counter = 0 then
						current_state <= WaitKBRecovered;
					else
						current_state <= Error;
					end if;
					
				when others =>
					current_state <= Error;
			end case;
		end if;
	end process;

	-- gate on 'not kbfifo_wrfull'?
	with current_state select
		kbfifo_wrreq <=	'1' when KBGotChar,
							'0' when others;

	-- debugging outputs
		with current_state select
			state_code <= 	"0000" when Init, 
								"0001" when WaitKB,
								"0010" when KBGotF0,
								"0011" when KBGotF0Wait,
								"0100" when KBCompleteBreakCode,
								"0101" when KBGotChar,
								"0110" when KBIgnoreChar,
								"1110" when WaitKBRecovered,
								"1111" when others;

end;
