library ieee;
use ieee.std_logic_1164.all;
library alu;

entity addVector is
	port(a, b: in std_ulogic_vector(15 downto 0);
			f: out std_ulogic_vector(15 downto 0));
end entity addVector;

architecture structural of addVector is
signal c0,c1,c2,c3,c4,c5,c6,c7,
	   c8,c9,c10,c11,c12,c13,c14,c15: std_ulogic;

begin
	u0: alu.halfAdder port map(
	a => a(0),
	b => b(0),
	f => f(0),
	c => c0);
	
	u1: alu.fullAdder port map(
	a => a(1),
	b => b(1),
	cin => c0,
	f => f(1),
	cout => c1);
	
	u2: alu.fullAdder port map(
	a => a(2),
	b => b(2),
	cin => c1,
	f => f(2),
	cout => c2);
	
	u3: alu.fullAdder port map(
	a => a(3),
	b => b(3),
	cin => c2,
	f => f(3),
	cout => c3);
	
	u4: alu.fullAdder port map(
	a => a(4),
	b => b(4),
	cin => c3,
	f => f(4),
	cout => c4);
	
	u5: alu.fullAdder port map(
	a => a(5),
	b => b(5),
	cin => c4,
	f => f(5),
	cout => c5);
	
	u6: alu.fullAdder port map(
	a => a(6),
	b => b(6),
	cin => c5,
	f => f(6),
	cout => c6);
		
	u7: alu.fullAdder port map(
	a => a(7),
	b => b(7),
	cin => c6,
	f => f(7),
	cout => c7);

	u8: alu.fullAdder port map(
	a => a(8),
	b => b(8),
	cin => c7,
	f => f(8),
	cout => c8);

	u9: alu.fullAdder port map(
	a => a(9),
	b => b(9),
	cin => c8,
	f => f(9),
	cout => c9);

	u10: alu.fullAdder port map(
	a => a(10),
	b => b(10),
	cin => c9,
	f => f(10),
	cout => c10);

	u11: alu.fullAdder port map(
	a => a(11),
	b => b(11),
	cin => c10,
	f => f(11),
	cout => c11);
	
	u12: alu.fullAdder port map(
	a => a(12),
	b => b(12),
	cin => c11,
	f => f(12),
	cout => c12);
	
	u13: alu.fullAdder port map(
	a => a(13),
	b => b(13),
	cin => c12,
	f => f(13),
	cout => c13);
	
	u14: alu.fullAdder port map(
	a => a(14),
	b => b(14),
	cin => c13,
	f => f(14),
	cout => c14);
	
	u15: alu.fullAdder port map(
	a => a(15),
	b => b(15),
	cin => c14,
	f => f(15),
	cout => c15);
end architecture structural;