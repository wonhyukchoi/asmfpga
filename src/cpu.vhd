library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library cscie93;
library alu;

use cscie93.memory_controller;


-- This file should be used for the DE2-115 board ONLY
entity cpu is
port (
-- CLOCK
clk50mhz : in std_logic;
-- PS/2 PORT
ps2_clk : in std_logic;
ps2_data : in std_logic;
-- LCD
lcd_en : out std_logic;
lcd_on : out std_logic;
lcd_rs : out std_logic;
lcd_rw : out std_logic;
lcd_db : inout std_logic_vector(7 downto 0);
-- RS232
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
-- Slide switches and keys
key2, key3, 
sw0, sw1, sw2, sw3,
sw4, sw5, sw6, sw7,
sw10, sw11,
sw13, sw14, sw15, 
sw16, sw17: in std_ulogic;
-- Hex displays
hexDisplay0,hexDisplay1,hexDisplay2,hexDisplay3,
hexDisplay4, hexDisplay5,
hexDisplay6, hexDisplay7 :
out std_ulogic_vector(6 downto 0) := "1111111";
-- LED lights
led1, led2, led3, led4,
ledg0 : out std_ulogic
);
end;


architecture default of cpu is
attribute chip_pin : string;
-- Provided attributes
attribute chip_pin of clk50mhz : signal is "Y2";
attribute chip_pin of ps2_clk : signal is "G6";
attribute chip_pin of ps2_data : signal is "H5";
attribute chip_pin of lcd_on : signal is "L5";
attribute chip_pin of lcd_en : signal is "L4";
attribute chip_pin of lcd_rw : signal is "M1";
attribute chip_pin of lcd_rs : signal is "M2";
attribute chip_pin of lcd_db : signal is "M5,M3,K2,K1,K7,L2,L1,L3";
attribute chip_pin of rs232_rxd : signal is "G12";
attribute chip_pin of rs232_txd : signal is "G9";
attribute chip_pin of rs232_cts : signal is "G14";
attribute chip_pin of sram_dq : signal is "AG3,AF3,AE4,AE3,AE1,AE2,AD2,AD1,AF7,AH6,AG6,AF6,AH4,AG4,AF4,AH3";
attribute chip_pin of sram_addr : signal is "T8,AB8,AB9,AC11,AB11,AA4,AC3,AB4, AD3, AF2, T7, AF5, AC5, AB5, AE6, AB6, AC7, AE7, AD7, AB7";
attribute chip_pin of sram_ce_N : signal is "AF8";
attribute chip_pin of sram_oe_N : signal is "AD5";
attribute chip_pin of sram_we_N : signal is "AE8";
attribute chip_pin of sram_ub_N : signal is "AC4";
attribute chip_pin of sram_lb_N : signal is "AD4";
-- Slide switches and keys

-- key2: memory stop
-- key3: memory reset 
attribute chip_pin of key2: signal is "N21";
attribute chip_pin of key3: signal is "R24";

-- sw0~15: debugging
attribute chip_pin of sw0:  signal is "AB28";
attribute chip_pin of sw1:  signal is "AC28";
attribute chip_pin of sw2:  signal is "AC27";
attribute chip_pin of sw3:  signal is "AD27";

attribute chip_pin of sw4:  signal is "AB27";
attribute chip_pin of sw5:  signal is "AC26";
attribute chip_pin of sw6:  signal is "AD26";
attribute chip_pin of sw7:  signal is "AB26";

attribute chip_pin of sw10: signal is "AC24";
attribute chip_pin of sw11: signal is "AB24";

attribute chip_pin of sw13: signal is "AA24";
attribute chip_pin of sw14: signal is "AA23";
attribute chip_pin of sw15: signal is "AA22";


-- sw16: clock hold
-- sw17: clock halt
attribute chip_pin of sw16: signal is "Y24";
attribute chip_pin of sw17: signal is "Y23";

-- Hex displays (debugging)
attribute chip_pin of hexDisplay7: signal is "AA14, AG18, AF17, AH17, AG17, AE17, AD17"; -- HEX 7 
attribute chip_pin of hexDisplay6: signal is "AC17, AA15, AB15, AB17, AA16, AB16, AA17"; -- HEX 6 

attribute chip_pin of hexDisplay5: signal is "AH18, AF18, AG19, AH19, AB18, AC18, AD18"; -- Hex 5
attribute chip_pin of hexDisplay4: signal is "AE18, AF19, AE19, AH21, AG21, AA19, AB19"; -- Hex 4

attribute chip_pin of hexDisplay3: signal is "Y19, AF23, AD24, AA21, AB20, U21, V21"; -- HEX 3
attribute chip_pin of hexDisplay2: signal is "W28, W27, Y26, W26, Y25, AA26, AA25"; -- HEX 2
attribute chip_pin of hexDisplay1: signal is "U24, U23, W25, W22, W21, Y22, M24"; -- HEX 1
attribute chip_pin of hexDisplay0: signal is "H22, J22, L25, L26, E17, F22, G18"; -- HEX 0

-- LED's (debugging)
attribute chip_pin of led1: signal is "F19";
attribute chip_pin of led2: signal is "E19";
attribute chip_pin of led3: signal is "F21";
attribute chip_pin of led4: signal is "F18";

attribute chip_pin of ledg0: signal is "E21";

-- Memory signals 
signal clock_divide_limit: std_ulogic_vector(19 downto 0);
signal sysclk1: std_ulogic;

signal mem_addr: std_ulogic_vector(15 downto 0);
signal mem_addr_21: std_ulogic_vector(20 downto 0) := "100001111000011110000";
signal mem_addr_ready: std_ulogic;

signal mem_dataready_inv: std_ulogic;

signal mem_rw: std_ulogic;
signal mem_data_read: std_ulogic_vector(31 downto 0);
signal mem_data_write: std_ulogic_vector(31 downto 0);

signal mem_sixteenbit: std_ulogic;

signal serial_character_ready: std_ulogic;

-- unused signals 
signal unUsed0: std_ulogic;
signal unUsed2: std_ulogic; 

-- control lines
signal load_ir: std_ulogic;
signal load_pc: std_ulogic;
signal addr_from_pc_or_alu: std_ulogic;
signal reg_read_or_write: std_ulogic;

-- PC and IR
signal pc_in: std_ulogic_vector(15 downto 0) := x"0000";
signal pc_out: std_ulogic_vector(15 downto 0) := x"0000";
signal pc_seq: std_ulogic_vector(15 downto 0);
signal instruction: std_ulogic_vector(15 downto 0);
signal opCode: std_ulogic_vector(3 downto 0) := instruction(15 downto 12);

-- Register array
signal regToWrite: std_ulogic_vector(3 downto 0);
signal regToRead_A, regToRead_B: std_ulogic_vector(3 downto 0);
signal writeVal: std_ulogic_vector(15 downto 0);
signal regValA, regValB: std_ulogic_vector(15 downto 0) := x"0000";
signal rtypeVal: std_ulogic_vector(15 downto 0);

-- Immediates
signal immediate: std_ulogic_vector(15 downto 0);
signal memSignExtend: std_ulogic_vector(15 downto 0);
signal luiExtended: std_ulogic_vector(15 downto 0);
signal luiVector: std_ulogic_vector(15 downto 0);
signal zeroExtend: std_ulogic_vector(15 downto 0);
signal signExtend: std_ulogic_vector(15 downto 0);

-- ALU lines
signal op2Input: std_ulogic_vector(15 downto 0);
signal aluOut: std_ulogic_vector(15 downto 0);
signal functCode: std_ulogic_vector(3 downto 0);
signal immediateFunctCode: std_ulogic_vector(3 downto 0);

-- Shifter
signal shiftedRight: std_ulogic_vector(15 downto 0);
signal shiftedLeft: std_ulogic_vector(15 downto 0);
signal shiftedResult: std_ulogic_vector(15 downto 0);

-- Multiplier
signal multResult: std_ulogic_vector(15 downto 0);

-- Branching
signal branchOffset: std_ulogic_vector(15 downto 0);
signal branchTarget: std_ulogic_vector(15 downto 0);

-- Jumping
signal jumpExtended: std_ulogic_vector(12 downto 0);
signal jumpShifted: std_ulogic_vector(12 downto 0);
signal jumpTarget: std_ulogic_vector(15 downto 0);

-- Debugging
signal clockSpeeder: std_ulogic_vector(1 downto 0);
signal debugRegister: std_ulogic_vector(3 downto 0);
signal chooseRightHex: std_ulogic_vector(3 downto 0);
signal hexLeftLeftDisplay: std_ulogic_vector(7 downto 0);
signal hexLeftRightDisplay: std_ulogic_vector(7 downto 0);
signal hexRightDisplay: std_ulogic_vector(15 downto 0);
signal muxDebug: std_ulogic_vector(3 downto 0);
signal fsm_state: std_ulogic_vector(4 downto 0);
signal regsToRead: std_ulogic_vector(7 downto 0);

begin

-- Logic is organized as follows.
-- PC => Memory => IR => Register Array =>
-- Immediates => ALU => Shifter => Multiplier
-- => branching/jumping => sequencer
-- This is in relative concordance with the block diagram.

-- Clock
clockSpeeder <= sw11 & sw10;
with clockSpeeder select
	clock_divide_limit <= x"003F0" when "00",
						  x"00AF0" when "01",
						  x"006F0" when "10",
						  x"FFFF0" when "11";
-- PC
---- PC register
pc: work.regstdResetable
	generic map (n => 15)
	port map(
	clk => sysclk1,
	en => load_pc,
	reset => not(key3),
	d_in => pc_in,
	q_out => pc_out);

-- mux
pc_in <= pc_seq when unsigned(opCode) < x"c" else
	     jumpTarget when opCode = x"d" else 
		 jumpTarget when opCode = x"e" else
	     aluOut when opCode = x"f" else
	     branchTarget when aluOut = x"0000" else
	     pc_seq;

-- sequential 
sequential: alu.addVector 
	port map(
	a => pc_out,
	b => x"0002",
	f => pc_seq);

-- memory

---- mux
mem_addr <= pc_out when (addr_from_pc_or_alu = '0') else aluOut;

memAddrExtend: work.zeroExtend16to21 port map(
	slv_16 => mem_addr,
	slv_21 => mem_addr_21);

aluSignExtend: work.signExtend16to32 port map(
	slv_16 => regValB,
	slv_32 => mem_data_write);
	
---- memory start
mem : cscie93.memory_controller port map (
clk50mhz => clk50mhz,

mem_addr => To_StdLogicVector(mem_addr_21),
mem_data_write => To_StdLogicVector(mem_data_write), 
mem_rw => mem_rw, 
mem_sixteenbit => mem_sixteenbit, 
mem_thirtytwobit => '0', 
mem_addressready => mem_addr_ready, 
mem_reset => not(key3), 

ps2_clk => ps2_clk,
ps2_data => ps2_data,

clock_hold => sw16,
clock_step => not(key2), 
clock_divide_limit => To_StdLogicVector(clock_divide_limit), 
mem_suspend => sw17, 

lcd_en => lcd_en,
lcd_on => lcd_on,
lcd_rs => lcd_rs,
lcd_rw => lcd_rw,
lcd_db => lcd_db,

To_StdULogicVector(mem_data_read)=> mem_data_read, 
mem_dataready_inv => mem_dataready_inv, 
sysclk1 => sysclk1, 
sysclk2 => unUsed0,

rs232_rxd => rs232_rxd,
rs232_txd => rs232_txd,
rs232_cts => rs232_cts,
sram_dq => sram_dq,
sram_addr => sram_addr,
sram_ce_N => sram_ce_N,
sram_oe_N => sram_oe_N,
sram_we_N => sram_we_N,
sram_ub_N => sram_ub_N,
sram_lb_N => sram_lb_N,

serial_character_ready => serial_character_ready, 
ps2_character_ready =>  unUsed2 

);
---- memory end 

-- IR
ir: work.regstd
	generic map (n => 15)
	port map(
	clk => sysclk1,
	en => load_ir,
	d_in => mem_data_read(15 downto 0),
	q_out => instruction);

-- Register array

---- Mux
regToWrite <= x"e" when opCode = x"e" else instruction(11 downto 8); -- jal

with opCode select
	regToRead_A <= instruction(7 downto 4) when x"8" | x"9" | x"a" | x"b",
				   x"e" when x"f", -- jr
				   instruction(11 downto 8) when others;

regToRead_B <= debugRegister when chooseRightHex = "0010" else
			   instruction(11 downto 8) when opCode = x"a" else
			   instruction(11 downto 8) when opCode = x"b" else
			   instruction(7 downto 4);

with instruction(3 downto 0) select
	rtypeVal <= shiftedResult when x"8" | x"9" | x"a",
				multResult when x"b",
				aluOut when others;

with opCode select
	writeVal <= rtypeVal when x"0",
				mem_data_read(15 downto 0) when x"8" | x"9", 
				pc_seq when x"e",
				luiVector when x"4",
				aluOut when others; -- immediate

---- Entity
regArray: work.regArray
	port map(
	enWrite => reg_read_or_write,
	regToWrite => regToWrite,
	sysclk1 => sysclk1,
	regToRead_A => regToRead_A,
	regToRead_B => regToRead_B,
	writeVal => writeVal,
	regValA => regValA,
	regValB => regValB);

-- Immediates

---- Port maps 
signExtendImmediate: work.signExtend8to16
	port map(
	slv_8 => instruction(7 downto 0),
	slv_16 => signExtend);

zeroExtendImmediate: work.zeroExtend8to16
	port map(
	slv_8 => instruction(7 downto 0),
	slv_16 => zeroExtend);

luiZeroExtend: work.zeroExtend8to16
	port map(
	slv_8 => instruction(7 downto 0),
	slv_16 => luiExtended);
	
luiVector <= std_ulogic_vector(shift_left(unsigned(luiExtended), 8));

memExtend: work.signExtend4to16
	port map(
	slv_4 => instruction(3 downto 0),
	slv_16 => memSignExtend);

with opCode select
	immediate <= signExtend when x"1" | x"2" | x"3",
				 zeroExtend when x"5" | x"6" | x"7",
				 memSignExtend when others;

-- ALU
---- input mux
with opCode select
	op2Input <= regValB when x"0",
				x"0000" when x"c" | x"f", -- beq or jr
				immediate when others;

with opCode select
	immediateFunctCode <= x"0" when x"1" | x"8" | x"9" | x"a" | x"b",
					      x"1" when x"2",
					      x"2" when x"3",
					      x"3" when x"4",
					      x"4" when x"5",
					      x"5" when x"6",
					      x"6" when others;

functCode <= instruction(3 downto 0) when (opCode = x"0")
			 else immediateFunctCode;

---- ALU entity 
aluCalc: alu.aluEntity
	port map(
	op1Input => regValA,
	op2Input => op2Input,
	functCode => functCode,
	aluOut => aluOut);

-- Shifter

shiftedLeft <= std_ulogic_vector(shift_left(unsigned(regValA), to_integer(unsigned(regValB))));
shiftedRight <= std_ulogic_vector(shift_right(unsigned(regValA), to_integer(unsigned(regValB))));
shiftedResult <= shiftedLeft when (functCode = x"8")
				 else shiftedRight;

-- Multiplier: 
multiplication: work.multiplier
	port map(	
	multiplicand => regValA,
	multiplier => regValB,
	result => multResult);

-- Branching
branchOffset <= std_ulogic_vector(shift_left(signed(signExtend), 1));
branchAddrCalc: alu.addVector
	port map(
	a => branchOffset,
	b => pc_seq,
	f => branchTarget);

-- Jumping
jumpExtend: work.zeroExtend12to13
	port map(
	slv_12 => instruction(11 downto 0),
	slv_13 => jumpExtended);

jumpShifted <= std_ulogic_vector(shift_left(signed(jumpExtended), 1));
jumpTarget <= pc_out(15 downto 13) & jumpShifted;


-- sequencer
---- sequencer start
sequencer: work.sequencer
	port map(
	sysclk1 => sysclk1,
	mem_dataready_inv => mem_dataready_inv,
	mem_reset => not(key3),
	instruction => instruction,
	alu_result => aluOut,
	load_pc => load_pc,
	load_ir => load_ir,
	addr_from_pc_or_alu => addr_from_pc_or_alu,
	mem_addr_ready => mem_addr_ready,
	mem_rw => mem_rw,
	mem_sixteenbit => mem_sixteenbit,
	reg_read_or_write => reg_read_or_write,
	fsm_state => fsm_state);

---- sequencer end

-- Everything below here is for debugging purposes.
-- Use at your own ease to see what comes up.
regsToRead <= regToRead_A & regToRead_B;
hexLeftLeftDisplay <= pc_out(15 downto 8) when (sw15='0') else "000" & fsm_state;
hexLeftRightDisplay <= pc_out(7 downto 0) when (sw14 ='0') else regsToRead;

debugRegister <= sw3 & sw2 & sw1 & sw0;

chooseRightHex <= sw7 & sw6 & sw5 & sw4;

with chooseRightHex select
	hexRightDisplay <= instruction when "0000",
					   regValA when "0001",
					   regValB when "0010",
					   aluOut when "0011",
					   mem_addr(15 downto 0) when "0100",
					   mem_data_read(15 downto 0) when "0101",
					   mem_data_write(15 downto 0) when "0110",
					   writeVal when "0111",
					   multResult when "1000",
					   rtypeVal when "1001",
					   branchOffset when "1101",
					   branchTarget when "1110",
					   pc_out when "1111",
					   x"4747" when others;

muxExtend: work.zeroExtend2to4
	port map(
	slv_2 => "00",
	slv_4 => muxDebug);

hex7Display: work.hexDisplay port map(
	bin => hexLeftLeftDisplay(7 downto 4),
	display => hexDisplay7);
hex6Display: work.hexDisplay port map(
	bin => hexLeftLeftDisplay(3 downto 0),
	display => hexDisplay6);

hex5Display: work.hexDisplay port map(
	bin => hexLeftRightDisplay(7 downto 4),
	display => hexDisplay5);
hex4Display: work.hexDisplay port map(
	bin => hexLeftRightDisplay(3 downto 0),
	display => hexDisplay4);

hex3Display: work.hexDisplay port map(
	bin => hexRightDisplay(15 downto 12),
	display => hexDisplay3);
hex2Display: work.hexDisplay port map(
	bin => hexRightDisplay(11 downto 8),
	display => hexDisplay2);
hex1Display: work.hexDisplay port map(
	bin => hexRightDisplay(7 downto 4),
	display => hexDisplay1);
hex0Display: work.hexDisplay port map(
	bin => hexRightDisplay(3 downto 0),
	display => hexDisplay0);


-- LED's 
led4 <= serial_character_ready;
led3 <= mem_dataready_inv;
led2 <= mem_addr_ready;
led1 <= mem_rw;
ledg0 <= addr_from_pc_or_alu;
end;