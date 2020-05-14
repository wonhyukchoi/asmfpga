-- synthesis library cscie93
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library cscie93;

entity memory_controller is
	port (
		clk50mhz : in std_logic;
		
		mem_addr : in std_logic_vector(20 downto 0);
		mem_data_write : in std_logic_vector(31 downto 0);
		mem_rw : in std_logic;
		mem_sixteenbit : in std_logic;
		mem_thirtytwobit : in std_logic;
		mem_addressready : in std_logic;
		
		mem_reset : in std_logic;
		
		ps2_clk : in std_logic;
		ps2_data : in std_logic;
		
		clock_hold : in std_logic;
		clock_step : in std_logic;
		clock_divide_limit : in std_logic_vector(19 downto 0) := (others => '0');
		mem_suspend : in std_logic;
		
		lcd_en : out std_logic;
		lcd_on : out std_logic;
		lcd_rs : out std_logic;
		lcd_rw : out std_logic;
		lcd_db : inout std_logic_vector(7 downto 0);
		
		mem_data_read : out std_logic_vector(31 downto 0);
		mem_dataready_inv : out std_logic;
		mem_ready : out std_logic;
		
		sysclk1 : out std_logic;
		sysclk2 : out std_logic;
		
		rs232_rxd : in std_logic;
		rs232_txd : out std_logic;
		rs232_cts : out std_logic;
		
		-- SSRAM interface
		sram_dq : inout std_logic_vector (15 downto 0);
		sram_addr : out std_logic_vector(19 downto 0);
		sram_ce_N : out std_logic;
		sram_oe_N : out std_logic;
		sram_we_N : out std_logic;
		sram_ub_N : out std_logic;
		sram_lb_N : out std_logic;
		
		-- usable as interrupts for char ready
		serial_character_ready : out std_logic;
		ps2_character_ready : out std_logic;
		
		--diagnostics
		fsmStateCode : out std_logic_vector(5 downto 0);
		ps2KbStateCode : out std_logic_vector(3 downto 0);
		serial_out_fifo_full : buffer std_logic;
		serial_out_fifo_empty : buffer std_logic;
		lcd_fifo_full : buffer std_logic;
		lcd_fifo_empty : buffer std_logic;
		dbg_lcd_ddram_addr : out std_logic_vector(7 downto 0)
	);
end;

architecture a of memory_controller is
	constant CHARIO_CONTROL_PORT : std_logic_vector(20 downto 0) := "00000" & X"FF00";
	constant SERIAL_CHARIO_DATA_PORT : std_logic_vector(20 downto 0) := "00000" & X"FF04";
	constant PS2_LCD_CHARIO_DATA_PORT : std_logic_vector(20 downto 0) := "00000" & X"FF08";

	signal mem_rw_internal : std_logic;
	signal mem_16bit_internal : std_logic := '0';
	signal mem_32bit_internal : std_logic := '0';
	signal mem_addr_internal : std_logic_vector(20 downto 0);
	signal mem_data_read_internal : std_logic_vector(31 downto 0);
	signal mem_data_write_internal : std_logic_vector(31 downto 0);
	signal fpga_mem_data_write : std_logic_vector(15 downto 0); -- this is the write data presented to on-chip RAM.It is 16 bits
	signal byte_enable : std_logic_vector(1 downto 0);
	signal mem_q : std_logic_vector(15 downto 0);
	signal mem_clkenable : std_logic;

	-- raw clocks not gated by clock_run/clock_suspend
	signal clk1raw : std_logic;
	signal clk2raw : std_logic;
	
	-- cooked clocks are gated by clock_run/clock_suspend
	signal clk1 : std_logic;
	signal clk2 : std_logic;
	
	signal pll_locked : std_logic;
	
	signal kb_serial_charready : std_logic;
	signal kb_serial_nextchar : std_logic_vector(7 downto 0);
	signal kb_serial_rdreq : std_logic;
	signal kb_serial_clear_buffer : std_logic;

	signal kb_ps2_charready : std_logic;
	signal kb_ps2_nextchar : std_logic_vector(7 downto 0);
	signal kb_ps2_rdreq : std_logic;
	signal kb_ps2_clear_buffer : std_logic;
	
	signal lcd_fifo_clr : std_logic;
	signal lcd_fifo_write : std_logic;
	signal lcd_fifo_rdreq : std_logic;
	signal lcd_fifo_q : std_logic_vector(7 downto 0);
	
	signal serial_out_fifo_rdclk : std_logic;
	signal serial_out_fifo_clr : std_logic;
	signal serial_out_fifo_write : std_logic;
	signal serial_out_fifo_rdreq : std_logic;
	signal serial_out_fifo_q : std_logic_vector(7 downto 0);
	

	type States is (Init, WaitForAddrReady, LatchControlInputs, 
						ClockRamRead, LatchReadOutputs, ClockRamRead32, LatchReadOutputs32, ReadDataReady, 
						WaitForWriteSignal, ClockRamWrite, ClockRamWrite32,
						GetCharSerial0, GetCharSerial1, GetCharSerial2, -- these are reads from serial input
						GetCharPs2_0, GetCharPs2_1, GetCharPs2_2,
						GetIoControl, 
						PutCharSerial0, PutCharSerial1, 	-- these are writes to serial output 
						PutCharLcd0, PutCharLcd1, 			-- these are writes to LCD output 
						PutIoControl0, PutIoControl1,
						SRAMStartRead, SRAMWaitRead, SRAMWaitRead2, SRAMWaitRead_32_1, SRAMWaitRead_32_2, SRAMFinishRead, 
						SRAMWaitForWriteSignal, SRAMStartWrite, SRAMContinueWrite, SRAMStartWrite_32, SRAMContinueWrite_32, SRAMFinishWrite
					);
	signal currentState : States := Init;
begin

	sysclk1 <= clk1;
	sysclk2 <= clk2;

	byte_enable(0) <= '0' when mem_32bit_internal='0' and mem_16bit_internal='0' and mem_addr_internal(0) = '1'
							else '1';
	byte_enable(1) <= '0' when mem_32bit_internal='0' and mem_16bit_internal='0' and mem_addr_internal(0) = '0'
							else '1';

	mem_data_write_internal <= 	
								mem_data_write when mem_32bit_internal='1' 
								else mem_data_write(7 downto 0) & X"00" & mem_data_write(7 downto 0) & X"00" when mem_32bit_internal='0' and mem_16bit_internal='0' and mem_addr_internal(0) = '1'
								else mem_data_write(15 downto 0) & mem_data_write(15 downto 0);

	with currentState select
		fpga_mem_data_write <= 	mem_data_write_internal(31 downto 16) when ClockRamWrite32,
										mem_data_write_internal(15 downto 0) when others;
		
	mem_data_read <= mem_data_read_internal when mem_32bit_internal = '1' 
							else X"0000" & mem_data_read_internal(15 downto 0) when mem_16bit_internal='1' 
							else X"000000" & mem_data_read_internal(7 downto 0) when mem_16bit_internal='0' and mem_addr_internal(0)='0'
							else X"000000" & mem_data_read_internal(15 downto 8);
	
	serial_character_ready <= kb_serial_charready;
	
	ps2_character_ready <= kb_ps2_charready;
	
	clockgen : entity cscie93.clockgen(pll) port map (
									clk50mhz => clk50mhz, 
									reset=>mem_reset, 
									run_clk=>not clock_hold, 
									single_step => clock_step,
									clock_divide_limit => clock_divide_limit,
									clk1raw => clk1raw,
									clk2raw=>clk2raw,
									clk1=>clk1, 
									clk2=>clk2, 
									locked=>pll_locked
								);
	
	ram : entity cscie93.ram_interface(implemented) port map (
				address=>mem_addr_internal(15 downto 1),
				byteena => byte_enable,
				clken => mem_clkenable,
				clock => clk2raw, --clk2,
				data => fpga_mem_data_write,
				wren => mem_rw_internal,
				q => mem_q
			);
			
	-- TODO: embed in a new lcd controller entity
	fifo_lcd : entity cscie93.lcd_fifo port map (
									aclr => mem_reset or lcd_fifo_clr,
									rdclk => clk2raw,
									wrclk => clk2raw,
									data => mem_data_write_internal(7 downto 0),
									rdreq => lcd_fifo_rdreq,
									wrreq => lcd_fifo_write,
									rdempty => lcd_fifo_empty,
									wrfull => lcd_fifo_full,
									q => lcd_fifo_q
								);
								
	lcd_ctrl : cscie93.lcd_controller port map (
							clk => clk1raw,
							reset => mem_reset,
							fifo_empty => lcd_fifo_empty,
							fifo_q => lcd_fifo_q,
							lcd_en => lcd_en,
							lcd_on => lcd_on,
							lcd_rs => lcd_rs,
							lcd_rw => lcd_rw,
							lcd_db => lcd_db,
							fifo_rdack => lcd_fifo_rdreq,
							dbg_ddram_addr => dbg_lcd_ddram_addr
						);
								
								
	-- TODO: embed in a new serial controller entity
	fifo_serial_out : entity cscie93.char_out_fifo port map (
									aclr => mem_reset or serial_out_fifo_clr,
									data => mem_data_write_internal(7 downto 0),
									rdclk => serial_out_fifo_rdclk,
									rdreq => serial_out_fifo_rdreq,
									wrclk => clk2, -- clk2raw,
									wrreq => serial_out_fifo_write,
									q => serial_out_fifo_q,
									rdempty => serial_out_fifo_empty,
									rdfull => open,
									wrempty => open,
									wrfull => serial_out_fifo_full
							);
	
	ps2_kb_ctrl : entity cscie93.keyboard_interface port map (
						clk => clk1raw,
						clk2 => clk2raw,
						ps2_clk => ps2_clk,
						ps2_data => ps2_data,
						reset => mem_reset,
						clear_buffer => kb_ps2_clear_buffer,
						fifo_q => kb_ps2_nextchar,
						fifo_has_data => kb_ps2_charready,
						fifo_rdreq => kb_ps2_rdreq,
						last_scan_code => open,
						state_code => ps2KbStateCode
					);

	rs232_rcv : entity cscie93.rs232_receive port map (
						clk50mhz => clk50mhz,
						clk2 => clk2, -- clk2raw, 
						rs232_rxd => rs232_rxd,
						rs232_cts => rs232_cts,
						reset => mem_reset,
						clear_buffer => kb_serial_clear_buffer,
						fifo_q => kb_serial_nextchar,
						fifo_has_data => kb_serial_charready,
						fifo_rdreq => kb_serial_rdreq
					);
				
	rs232_xmit : entity cscie93.rs232_transmit port map (
							clk50MHz => clk50MHz,
							reset => mem_reset,
							fifo_empty => serial_out_fifo_empty,
							fifo_q => serial_out_fifo_q,
							rs232_txd => rs232_txd,							
							fifo_rdclk => serial_out_fifo_rdclk,
							fifo_rdreq => serial_out_fifo_rdreq
						);
			
	with currentState select
		mem_clkenable <= 	'1' when ClockRamRead | ClockRamRead32 | ClockRamWrite | ClockRamWrite32,
							'0' when others;
	
	with currentState select
		mem_dataready_inv <=	'0' when ReadDataReady 
													| WaitForWriteSignal | ClockRamWrite | ClockRamWrite32
													| SRAMWaitForWriteSignal | SRAMStartWrite | SRAMContinueWrite | SRAMStartWrite_32 | SRAMContinueWrite_32 | SRAMFinishWrite
													| PutCharSerial0 | PutCharSerial1 
													| PutCharLcd0 | PutCharLcd1 
													| PutIoControl0 | PutIoControl1,
										'1' when others;
								
	with currentState select
		mem_ready <= 	'1' when WaitForAddrReady,
							'0' when others;
							
	kb_serial_clear_buffer <= '1' when currentState=PutIoControl0 and mem_data_write_internal(0)='1'
							 else '0';

	kb_ps2_clear_buffer <= '1' when currentState=PutIoControl0 and mem_data_write_internal(2)='1'
									else '0';

	serial_out_fifo_clr <=	'1' when currentState = PutIoControl0 and mem_data_write_internal(1)='1'
									else '0';
							
	lcd_fifo_clr <=	'1' when currentState = PutIoControl0 and mem_data_write_internal(3)='1'
							else '0';

	FSM :
	process(clk1, mem_reset) is
	begin
		if mem_reset = '1' then
			currentState <= Init;
		elsif rising_edge(clk1) then
			case currentState is
				when Init =>
					if pll_locked='1' then
						currentState <= WaitForAddrReady;
					end if;
					
				when WaitForAddrReady =>
					if mem_addressready = '1' and mem_suspend='0' then
						currentState <= LatchControlInputs;
					end if;
					
				when LatchControlInputs =>
					mem_rw_internal <= mem_rw;
					mem_16bit_internal <= mem_sixteenbit;
					mem_32bit_internal <= mem_thirtytwobit;
					mem_addr_internal <= mem_addr;
					if mem_rw = '0' then
						if mem_addr(20 downto 1) = SERIAL_CHARIO_DATA_PORT(20 downto 1) then
							currentState <= GetCharSerial0;
						elsif mem_addr(20 downto 1) = CHARIO_CONTROL_PORT(20 downto 1) then
							currentState <= GetIoControl;
						elsif mem_addr(20 downto 1) = PS2_LCD_CHARIO_DATA_PORT(20 downto 1) then
							currentState <= GetCharPs2_0;
						elsif mem_addr(20)='1' or mem_addr(19)='1' or mem_addr(18)='1' or mem_addr(17)='1' or mem_addr(16)='1' then
							-- this is a read from the high bank, which is implemented in SSRAM
							currentState <= SRAMStartRead;							
						else
							-- this is a read from the "main" (on-chip) bank of memory
							currentState <=  ClockRamRead;
						end if;
					else
						if mem_addr(20 downto 1) = SERIAL_CHARIO_DATA_PORT(20 downto 1) then
							currentState <= PutCharSerial0;
						elsif mem_addr(20 downto 1) = CHARIO_CONTROL_PORT(20 downto 1) then
							currentState <= PutIoControl0;
						elsif mem_addr(20 downto 1) = PS2_LCD_CHARIO_DATA_PORT(20 downto 1) then
							currentState <= PutCharLcd0;
						elsif mem_addr(20)='1' or mem_addr(19)='1' or mem_addr(18)='1' or mem_addr(17) = '1' or  mem_addr(16) = '1' then
							-- this is a write to the high bank, which is implemented in SSRAM (except for mapped I/O locations handled above)
							currentState <= SRAMWaitForWriteSignal;							
						else
							currentState <= WaitForWriteSignal;
						end if;
					end if;
					
				when ClockRamRead =>
					currentState <= LatchReadOutputs;
				
				when LatchReadOutputs =>
					mem_data_read_internal(15 downto 0) <= mem_q;
					if mem_32bit_internal = '0' then
						currentState <= ReadDataReady;
					else
						currentState <= ClockRamRead32;
						mem_addr_internal <= std_logic_vector(unsigned(mem_addr_internal) + 2);
					end if;
					
				-- finish a 32-bit read from FPGA RAM
				when ClockRamRead32 =>
					currentState <= LatchReadOutputs32;
					
				when LatchReadOutputs32 =>
					mem_data_read_internal(31 downto 16) <= mem_q;
					currentState <= ReadDataReady;
					
				when ReadDataReady =>
					if mem_addressready='0' then
						currentState <= WaitForAddrReady;
					end if;
					
				when WaitForWriteSignal =>
					if mem_addressready = '0' then
						currentState <= ClockRamWrite;
					end if;
				
				when ClockRamWrite =>
					if mem_32bit_internal='0' then
						currentState <= WaitForAddrReady;
					else
						currentState <= ClockRamWrite32;
						mem_addr_internal <= std_logic_vector(unsigned(mem_addr_internal) + 2);
					end if;
					
				when ClockRamWrite32 =>
					currentState <= WaitForAddrReady;
					
				when GetCharSerial0 =>
					if kb_serial_charready = '1' then
						currentState <= GetCharSerial1;
					else
						mem_data_read_internal <= X"2BAD2BAD";
						currentState <= ReadDataReady;
					end if;
				when GetCharSerial1 =>
					currentState <= GetCharSerial2;
					
				when GetCharSerial2 =>
					mem_data_read_internal <= X"000000" & kb_serial_nextchar;
					currentState <= ReadDataReady;
				
				when GetCharPs2_0 =>
					if kb_ps2_charready = '1' then
						currentState <= GetCharPs2_1;
					else
						mem_data_read_internal <= X"2BAD2BAD";
						currentState <= ReadDataReady;
					end if;
				when GetCharPs2_1 =>
					currentState <= GetCharPs2_2;
					
				when GetCharPs2_2 =>
					mem_data_read_internal <= X"000000" & kb_ps2_nextchar;
					currentState <= ReadDataReady;
					
				when GetIoControl =>
					mem_data_read_internal <= (3=>not lcd_fifo_full,  2=>kb_ps2_charready, 1=>not serial_out_fifo_full, 0=>kb_serial_charready, others=>'0');
					currentState <= ReadDataReady;
				
				when PutCharSerial0 =>
					if mem_addressready = '0' then
						currentState <= PutCharSerial1;
					end if;
				
				when PutCharSerial1 =>
					currentState <= WaitForAddrReady;
					
				when PutCharLcd0 =>
					if mem_addressready = '0' then
						currentState <= PutCharLcd1;
					end if;
				
				when PutCharLcd1 =>
					currentState <= WaitForAddrReady;
					
				when PutIoControl0 =>
					currentState <= PutIoControl1;
					
				when PutIoControl1 =>
					if mem_addressready = '0' then
						currentState <= WaitForAddrReady;
					end if;

				when SRAMStartRead =>
					currentState <= SRAMWaitRead;
				
				when SRAMWaitRead =>
					currentState <= SRAMWaitRead2;
					
				when SRAMWaitRead2 =>
					mem_data_read_internal(15 downto 0) <= sram_dq;
					if mem_32bit_internal = '1' then
						currentState <= SRAMWaitRead_32_1;
					else
						currentState <= SRAMFinishRead;
					end if;
					
				when SRAMWaitRead_32_1 =>
					mem_addr_internal <= std_logic_vector(unsigned(mem_addr_internal) + 2);
					currentState <= SRAMWaitRead_32_2;
					
				when SRAMWaitRead_32_2 =>
					mem_data_read_internal(31 downto 16) <= sram_dq;
					currentState <= SRAMFinishRead;
					
				when SRAMFinishRead =>
					currentState <= ReadDataReady;
					
				when SRAMWaitForWriteSignal =>
					if mem_addressready = '0' then
						currentState <= SRAMStartWrite;
					end if;
					
				when SRAMStartWrite =>
					currentState <= SRAMContinueWrite;
					
				when SRAMContinueWrite =>
					if mem_32bit_internal = '1' then
						currentState <= SRAMStartWrite_32;
					else
						currentState <= SRAMFinishWrite;
					end if;
					
				when SRAMStartWrite_32 =>
					mem_addr_internal <= std_logic_vector(unsigned(mem_addr_internal) + 2);
					currentState <= SRAMContinueWrite_32;
					
				when SRAMContinueWrite_32 =>
					currentState <= SRAMFinishWrite;
					
				when SRAMFinishWrite =>
					currentState <= WaitForAddrReady;
					
					
				when others =>
					if mem_addressready = '0' then
						currentState <= WaitForAddrReady;
					end if;
					
			end case;
		end if;
	end process;
	
	
	with currentState select
		kb_serial_rdreq <= 	'1' when GetCharSerial1,
							'0' when others;
							
	with currentState select
		kb_ps2_rdreq <= 	'1' when GetCharPs2_1,
								'0' when others;
							
	with currentState select
		serial_out_fifo_write <=	'1' when PutCharSerial1,
											'0' when others;
								
	with currentState select
		lcd_fifo_write <=	'1' when PutCharLcd1,
								'0' when others;

	-- SSRAM signals
--	
--	-- For addresses mapped to the SSRAM the address mapping is more or less direct; FSM logic pre-determines 
--	--  whether an address implies an SSRAM operation or a main memory operation
--	sram_addr(18) <= '0';
--	sram_addr(17) <= '0';
--	sram_addr(16) <= '0';
	--sram_addr(15) <= '0';
--	sram_addr(15 downto 0) <= mem_addr_internal(17 downto 2);
	sram_addr <= mem_addr_internal(20 downto 1);
--	
--	-- write enable
	with currentState select
		sram_we_N <=	'0' when SRAMContinueWrite | SRAMContinueWrite_32,
							'1' when others;

	-- byte enables for writes
	sram_ub_N <= '0' when mem_32bit_internal='1' or mem_16bit_internal='1' or mem_addr_internal(0) = '1'
							else '1';
	sram_lb_N <= '0' when mem_32bit_internal='1' or mem_16bit_internal='1' or mem_addr_internal(0) = '0'
							else '1';
	
	
	-- carefully drive the dq pins only when writing
	with currentState select
		sram_dq <=	mem_data_write_internal(15 downto 0) when SRAMContinueWrite,
						mem_data_write_internal(31 downto 16) when SRAMStartWrite_32 | SRAMContinueWrite_32,
						(others => 'Z') when others;

	-- chip enables asserted for all SRAM states, deasserted otherwise
	with currentState select
		sram_ce_N <= 	'0' when SRAMStartRead | SRAMWaitRead | SRAMWaitRead2 | SRAMWaitRead_32_1 | SRAMWaitRead_32_2 | SRAMFinishRead 
										| SRAMWaitForWriteSignal | SRAMStartWrite | SRAMContinueWrite | SRAMStartWrite_32 | SRAMContinueWrite_32 |SRAMFinishWrite,
							'1' when others;
	
	-- output enable is carefully asserted when needed
	with currentState select							
		sram_oe_N <=	'0' when SRAMWaitRead | SRAMWaitRead2 | SRAMWaitRead_32_1 | SRAMWaitRead_32_2 | SRAMFinishRead,
							'1' when others;
	
								
	with currentState select
		fsmStateCode <= 	"000000" when Init,
								"000001" when  WaitForAddrReady,
								"000010" when  LatchControlInputs,
								"000011" when  ClockRamRead,
								"000100" when  LatchReadOutputs,
								"000101" when  ReadDataReady,
								"000110" when  WaitForWriteSignal,
								"000111" when  ClockRamWrite,
								"001000" when  GetCharSerial0,
								"001001" when  GetCharSerial1,
								"001010" when  GetCharSerial2,
								"001011" when  PutCharSerial0,
								"001100" when  PutCharSerial1,
								"001101" when GetIoControl,
								"001110" when PutIoControl0,
								"001111" when PutIoControl1,
								"010000" when GetCharPs2_0,
								"010001" when GetCharPs2_1,
								"010010" when GetCharPs2_2,
								"010011" when SRAMStartRead,
								"010100" when SRAMWaitRead,
								"010101" when SRAMWaitRead2,
								"010110" when SRAMFinishRead,
								"010111" when SRAMWaitForWriteSignal,
								"011000" when SRAMStartWrite,
								"011001" when SRAMContinueWrite,
								"011010" when SRAMFinishWrite,
								"011011" when ClockRamRead32,
								"011100" when LatchReadOutputs32,
								"011101" when ClockRamWrite32,
								"011110" when SRAMWaitRead_32_1,
								"011111" when SRAMWaitRead_32_2,
								"100000" when SRAMStartWrite_32,
								"100001" when SRAMContinueWrite_32,
								"111111" when others;
								
end;
