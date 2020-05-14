-- synthesis library cscie93
library ieee;
use ieee.std_logic_1164.all;

library cscie93;
use cscie93.MemTypes.all;

entity ps2KeyboardReceiver is	
	port (
		ps2_clk : in std_logic;
		ps2_data : in std_logic;
		data_out : buffer std_logic_vector(7 downto 0);
		rcv_ok : out std_logic;
		rcv_error : out std_logic;
		shift_key_down : out std_logic;
		isBreakCode : buffer std_logic
	);
end;

architecture behavioral of ps2KeyboardReceiver is
	attribute keep: boolean;
	
	signal currentState : PS2States := WAITING;
	signal shift_enable : std_logic;
	signal shift_key_down_internal : std_logic := '0';
	signal currentShiftState : ShiftKeyStates := NoShift;
	signal nextShiftState : ShiftKeyStates;
	signal currentBreakCodeState : BreakCodeStates := Default;
	signal nextBreakCodeState : BreakCodeStates := Default;
	
	signal rcv_ok_internal : std_logic;
	attribute keep of rcv_ok_internal : signal is true;
	
begin

	rcv_ok <= rcv_ok_internal;

	main_seq : process(ps2_clk, ps2_data, currentState) is
	begin
		if falling_edge(ps2_clk) then
			case currentState is
					
				when WAITING =>
					if ps2_data = '0' then
						currentState <= RCV0;
					end if;
					
				when RCV0 =>
					currentState <= RCV1;
				when RCV1 =>
					currentState <= RCV2;
				when RCV2 =>
					currentState <= RCV3;
				when RCV3 =>
					currentState <= RCV4;
				when RCV4 =>
					currentState <= RCV5;
				when RCV5 =>
					currentState <= RCV6;
				when RCV6 =>
					currentState <= RCV7;
				when RCV7 =>
					currentState <= RCVP;
				when RCVP =>
					currentState <= RCVSTOP;
				when RCVSTOP =>
					if ps2_data = '1' then
						currentState <= RCVOK;
					else
						currentState <= RCVERR;
					end if;
				
				when RCVOK =>
					if ps2_data = '0' then
						currentState <= RCV0;
					else
						currentState <= WAITING;
					end if;			
					
				when RCVERR =>
					if ps2_data = '0' then
						currentState <= RCV0;
					else
						currentState <= WAITING;
					end if;			
					
				when others =>
					currentState <= currentState;
			end case;
		end if;
	end process;
	

	with currentState select
		shift_enable <= '1' when RCV0 | RCV1 | RCV2 | RCV3 | RCV4 | RCV5 | RCV6 | RCV7,
						'0' when others;

	with currentState select
		rcv_ok_internal <= 	'1' when RCVOK,
									'0' when others;
					
	with currentState select
		rcv_error <= 	'1' when RCVERR,
						'0' when others;
						
	shift_key_down <= shift_key_down_internal;

	shift_seq : process(rcv_ok_internal, nextShiftState) is
	begin
		if rising_edge(rcv_ok_internal) then
			currentShiftState <= nextShiftState;
		end if;
	end process;
	
	break_code_seq_logic:
	process(data_out, currentBreakCodeState) is
	begin
		case currentBreakCodeState is
		when Default =>
			if data_out = X"F0" then
				nextBreakCodeState <= GotF0;
			else
				nextBreakCodeState <= Default;
			end if;
		when GotF0 =>
			nextBreakCodeState <= PostF0;
		when PostF0 =>
			if data_out = X"F0" then
				nextBreakCodeState <= GotF0;
			else
				nextBreakCodeState <= Default;
			end if;
		end case;
	end process;
	
	break_code_seq : process(rcv_ok_internal, nextBreakCodeState) is
	begin
		if rising_edge(rcv_ok_internal) then
			currentBreakCodeState <= nextBreakCodeState;
		end if;
	end process;
	
	with currentBreakCodeState select
		isBreakCode <= '1' when GotF0 | PostF0,
						'0' when others;
	
	shift_seq_logic:
	process(data_out, currentShiftState) is
	begin
		case currentShiftState is
			when NoShift =>
				if data_out = X"12" or data_out = X"59" then
					nextShiftState <= Shift;
				else
					nextShiftState <= currentShiftState;
				end if;
			when Shift =>
				if data_out = X"F0" then
					nextShiftState <= ShiftF0;
				else
					nextShiftState <= currentShiftState;
				end if;
			when ShiftF0 =>
				if data_out = X"12" or data_out = X"59" then
					nextShiftState <= NoShift;
				else
					nextShiftState <= currentShiftState;
				end if;
			when others =>
				nextShiftState <= currentShiftState;
		end case;
	end process;
	
	with currentShiftState select
		shift_key_down_internal <= 	'1' when Shift | ShiftF0,
									'0' when others;


	shift_reg : entity cscie93.shift_register(structural) 
		generic map (WIDTH => 8)
		port map (
			clk_n => ps2_clk,
			data_in => ps2_data,
			shift_enable => shift_enable,
			data_out => data_out,
			carry_out => open
		);
	
			
end;
