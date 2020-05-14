library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regArray is
	port(enWrite: in std_ulogic;
		regToWrite: in std_ulogic_vector(3 downto 0);
		sysclk1: in std_ulogic;
		regToRead_A, regToRead_B: 
		in std_ulogic_vector(3 downto 0);
		writeVal: in std_ulogic_vector(15 downto 0);
		signal regValA, regValB: 
		out std_ulogic_vector(15 downto 0));
end entity regArray;

architecture structural of regArray is
signal reg0En, reg1En, reg2En, reg3En,
	   reg4En, reg5En, reg6En, reg7En,
	   reg8En, reg9En, reg10En, reg11En,
	   reg12En, reg13En, reg14En, reg15En: std_ulogic;

signal reg0Val, reg1Val, reg2Val, reg3Val,
	   reg4Val, reg5Val, reg6Val, reg7Val,
	   reg8Val, reg9Val, reg10Val, reg11Val,
	   reg12Val, reg13Val, reg14Val, reg15Val
	   : std_ulogic_vector(15 downto 0);

begin 

--reg0En <= '1' when (enWrite = '1') and regToWrite = x"0" else '0'; 
--reg1En <= '1' when (enWrite = '1') and regToWrite = x"1" else '0';
--reg2En <= '1' when (enWrite = '1') and regToWrite = x"2" else '0'; 
--reg3En <= '1' when (enWrite = '1') and regToWrite = x"3" else '0';
--reg4En <= '1' when (enWrite = '1') and regToWrite = x"4" else '0'; 
--reg5En <= '1' when (enWrite = '1') and regToWrite = x"5" else '0';
--reg6En <= '1' when (enWrite = '1') and regToWrite = x"6" else '0'; 
--reg7En <= '1' when (enWrite = '1') and regToWrite = x"7" else '0';
--reg8En <= '1' when (enWrite = '1') and regToWrite = x"8" else '0'; 
--reg9En <= '1' when (enWrite = '1') and regToWrite = x"9" else '0';
--reg10En <= '1' when (enWrite = '1') and regToWrite = x"a" else '0'; 
--reg11En <= '1' when (enWrite = '1') and regToWrite = x"b" else '0';
--reg12En <= '1' when (enWrite = '1') and regToWrite = x"c" else '0'; 
--reg13En <= '1' when (enWrite = '1') and regToWrite = x"d" else '0';
--reg14En <= '1' when (enWrite = '1') and regToWrite = x"e" else '0'; 
--reg15En <= '1' when (enWrite = '1') and regToWrite = x"f" else '0';

reg0En <= '0' when enWrite = '0' else '0' when regToWrite /= x"0" else '1';
reg1En <= '0' when enWrite = '0' else '0' when regToWrite /= x"1" else '1';
reg2En <= '0' when enWrite = '0' else '0' when regToWrite /= x"2" else '1';
reg3En <= '0' when enWrite = '0' else '0' when regToWrite /= x"3" else '1';
reg4En <= '0' when enWrite = '0' else '0' when regToWrite /= x"4" else '1';
reg5En <= '0' when enWrite = '0' else '0' when regToWrite /= x"5" else '1';
reg6En <= '0' when enWrite = '0' else '0' when regToWrite /= x"6" else '1';
reg7En <= '0' when enWrite = '0' else '0' when regToWrite /= x"7" else '1';
reg8En <= '0' when enWrite = '0' else '0' when regToWrite /= x"8" else '1';
reg9En <= '0' when enWrite = '0' else '0' when regToWrite /= x"9" else '1';
reg10En <= '0' when enWrite = '0' else '0' when regToWrite /= x"a" else '1';
reg11En <= '0' when enWrite = '0' else '0' when regToWrite /= x"b" else '1';
reg12En <= '0' when enWrite = '0' else '0' when regToWrite /= x"c" else '1';
reg13En <= '0' when enWrite = '0' else '0' when regToWrite /= x"d" else '1';
reg14En <= '0' when enWrite = '0' else '0' when regToWrite /= x"e" else '1';
reg15En <= '0' when enWrite = '0' else '0' when regToWrite /= x"f" else '1';



reg0: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg0En,
	d_in => writeVal,
	q_out => reg0Val);

reg1: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg1En,
	d_in => writeVal,
	q_out => reg1Val);

reg2: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg2En,
	d_in => writeVal,
	q_out => reg2Val);

reg3: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg3En,
	d_in => writeVal,
	q_out => reg3Val);

reg4: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg4En,
	d_in => writeVal,
	q_out => reg4Val);

reg5: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg5En,
	d_in => writeVal,
	q_out => reg5Val);

reg6: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg6En,
	d_in => writeVal,
	q_out => reg6Val);

reg7: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg7En,
	d_in => writeVal,
	q_out => reg7Val);

reg8: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg8En,
	d_in => writeVal,
	q_out => reg8Val);

reg9: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg9En,
	d_in => writeVal,
	q_out => reg9Val);

reg10: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg10En,
	d_in => writeVal,
	q_out => reg10Val);

reg11: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg11En,
	d_in => writeVal,
	q_out => reg11Val);

reg12: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg12En,
	d_in => writeVal,
	q_out => reg12Val);

reg13: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg13En,
	d_in => writeVal,
	q_out => reg13Val);

reg14: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg14En,
	d_in => writeVal,
	q_out => reg14Val);

reg15: work.regstd
	generic map(n => 15)
	port map(
	clk => sysclk1,
	en => reg15En,
	d_in => writeVal,
	q_out => reg15Val);

with regToRead_A select
	regValA <= reg0Val when x"0",
			   reg1Val when x"1",
			   reg2Val when x"2",
			   reg3Val when x"3",
			   reg4Val when x"4",
			   reg5Val when x"5",
			   reg6Val when x"6",
			   reg7Val when x"7",
			   reg8Val when x"8",
			   reg9Val when x"9",
			   reg10Val when x"a",
			   reg11Val when x"b",
			   reg12Val when x"c",
			   reg13Val when x"d",
			   reg14Val when x"e",
			   reg15Val when others;

with regToRead_B select
	regValB <= reg0Val when x"0",
			   reg1Val when x"1",
			   reg2Val when x"2",
			   reg3Val when x"3",
			   reg4Val when x"4",
			   reg5Val when x"5",
			   reg6Val when x"6",
			   reg7Val when x"7",
			   reg8Val when x"8",
			   reg9Val when x"9",
			   reg10Val when x"a",
			   reg11Val when x"b",
			   reg12Val when x"c",
			   reg13Val when x"d",
			   reg14Val when x"e",
			   reg15Val when others;

end structural;