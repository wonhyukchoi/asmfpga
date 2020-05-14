-- synthesis library cscie93
library ieee;
use ieee.std_logic_1164.all;

library cscie93;

entity rs232_receive is
	port (
		clk50mhz : in std_logic;
		clk2 : in std_logic; -- clk2 from controller, out-of-phase with clk
		
		rs232_rxd : in std_logic;
		rs232_cts : out std_logic;
		reset : in std_logic;
		clear_buffer : in std_logic;
		
		fifo_q : out std_logic_vector(7 downto 0);
		fifo_has_data : out std_logic;
		fifo_rdreq : std_logic -- clocks on clk2 rising edge
		
	);
	
end;


architecture arch of rs232_receive is
	signal data : std_logic_vector(7 downto 0) := X"00";
	
	type States is (Waiting, RcvStart, RcvData, RcvStop, WriteFifo);
	signal state : States := Waiting;
	
	constant CLOCKDIV_9600x16 : integer := 325; -- 50MHz / 5208 -> 9600 baud; 50MHz / 325 -> 16x oversampled 9600 baud interval
	constant CLOCKDIV_9600x16_HALF : integer := 162; -- 50MHz / 5208 -> 9600 baud; 50MHz / 162 -> 32x oversampled 9600 baud interval (for clock gen)
	constant SKIPSAMPLES : integer := 15; -- we'll get 16 samples per bit
	constant SKIPSAMPLES_TO_CENTER : integer := 23; -- we'll get 6 for the first bit to center on the pulse
	
	signal fifo_wrreq : std_logic;
	signal fifo_rdempty : std_logic;
	signal fifo_wrfull : std_logic;
	
	-- this is at 16x-oversampling for 9600 baud, 50% duty
	signal serial_clk_16x : std_logic := '0';

		
begin

	fifo_has_data <= not fifo_rdempty;
	rs232_cts <= '0'; -- no flow control, force CTS asserted (this is 0 because the interface chip inverts all signals)

	process(clk50mhz, serial_clk_16x) is
		variable i : integer range 0 to CLOCKDIV_9600x16_HALF := 0;
	begin
		if rising_edge(clk50mhz) then
			if i = CLOCKDIV_9600x16_HALF then
				serial_clk_16x <= not serial_clk_16x;
				i := 0;
			else
				i := i+1;
			end if;
		end if;
	end process;
	
	
	process(serial_clk_16x) is
		variable sample_skip_counter : integer := 0;
		variable iBit : integer := 0;
	
	begin
		if rising_edge(serial_clk_16x) then
			
			-- this process runs at 16x oversampling for the baud rate
			
			case state is
				when Waiting =>
					if rs232_rxd = '0' then
						state <= RcvStart;
						iBit := 0;
						sample_skip_counter := 0;
					end if;
					
				when RcvStart=>
					if sample_skip_counter = SKIPSAMPLES_TO_CENTER then
						sample_skip_counter := 0;
						state <= RcvData;
					else
						sample_skip_counter := sample_skip_counter + 1;
					end if;
					
				when RcvData =>
					if sample_skip_counter = SKIPSAMPLES then
						sample_skip_counter := 0;
						iBit := iBit + 1;
						if iBit = 8 then
							state <= RcvStop;
						end if;
					else
						if sample_skip_counter = 0 then
							data <= rs232_rxd & data(7 downto 1);
						end if;
						sample_skip_counter := sample_skip_counter + 1;
					end if;
					
				when RcvStop =>
					if sample_skip_counter = SKIPSAMPLES then
						sample_skip_counter := 0;
						state <= WriteFifo;
					else
						sample_skip_counter := sample_skip_counter + 1;
					end if;
				
				when WriteFifo =>
					state <= Waiting;
					
			end case;
		end if;
	end process;
	
	
	with state select
		fifo_wrreq <=	'1' when WriteFifo,
							'0' when others;
	
	fifo_kb : entity cscie93.char_fifo port map (
						aclr=>reset or clear_buffer, data => data, 
						rdclk => clk2, rdreq=>fifo_rdreq, 
						wrclk => not serial_clk_16x, wrreq=>fifo_wrreq,
						q => fifo_q, rdempty=>fifo_rdempty, wrfull=>fifo_wrfull
					);
	
					
end;
