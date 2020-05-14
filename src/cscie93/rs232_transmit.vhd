-- synthesis library cscie93
library ieee;
use ieee.std_logic_1164.all;

-- Hardwired to transmit at 9600N1, requires 50MHz clock
entity rs232_transmit is
	port (
		clk50mhz : in std_logic;
		reset : in std_logic;
		fifo_empty : in std_logic;
		fifo_q : in std_logic_vector(7 downto 0);
		rs232_txd : out std_logic;
		
		fifo_rdclk : out std_logic;
		fifo_rdreq : out std_logic
	);
	
end;


architecture structural of rs232_transmit is
	signal txbit : std_logic := '1';

	type TxState is (TxWait, Prep,  
				TransmitStart, Transmit0, Transmit1, Transmit2, Transmit3, Transmit4, Transmit5, Transmit6, Transmit7, TransmitStop,
				SignalComplete);
	
	constant CLOCKDIV : integer := 5208;
	
	signal state : TxState := TxWait;
	signal generated_fifo_clk : std_logic := '0';
	
begin
		
	rs232_txd <= txbit;
	fifo_rdclk  <= generated_fifo_clk;

	process(clk50mhz, reset) is
		variable counter : integer range 0 to CLOCKDIV := 0;
	begin
		if reset = '1' then
			state <= TxWait;
		elsif rising_edge(clk50mhz) then
			-- slow clock for 9600 baud
			if counter = CLOCKDIV then
				counter := 0;
				generated_fifo_clk <= '0'; -- poor man's out-of-phase edge
				
				case state is
					when TxWait =>
						if fifo_empty = '0' then
							state <= Prep;
						end if;
					
					when Prep =>
						state <= TransmitStart;
						
					when TransmitStart =>
						state <= Transmit0;
						
					when Transmit0 =>
						state <= Transmit1;

					when Transmit1 =>
						state <= Transmit2;
						
					when Transmit2 =>
						state <= Transmit3;

					when Transmit3 =>
						state <= Transmit4;

					when Transmit4 =>
						state <= Transmit5;
						
					when Transmit5 =>
						state <= Transmit6;

					when Transmit6 =>
						state <= Transmit7;
						
					when Transmit7 =>
						state <= TransmitStop;
						
					when TransmitStop =>
						state <= SignalComplete;
						
					when SignalComplete =>
						state <= TxWait;
						
				end case;
			else
				generated_fifo_clk <= '1';
				counter := counter + 1;
			end if;
		end if;
	end process;
	
	with state select
		txbit <= '0' when TransmitStart,
					fifo_q(0) when Transmit0,
					fifo_q(1) when Transmit1,
					fifo_q(2) when Transmit2,
					fifo_q(3) when Transmit3,
					fifo_q(4) when Transmit4,
					fifo_q(5) when Transmit5,
					fifo_q(6) when Transmit6,
					fifo_q(7) when Transmit7,
					'1' when TransmitStop,
					'1' when others;


	with state select
		fifo_rdreq <= 	'1' when SignalComplete,
							'0' when others;
	
	
end;
