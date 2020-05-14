library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library alu;

entity aluEntity is
port(op1Input: in std_ulogic_vector(15 downto 0);
	  op2Input: in std_ulogic_vector(15 downto 0);
	  functCode: in std_ulogic_vector(3 downto 0);
	  aluOut: out std_ulogic_vector(15 downto 0));
end entity aluEntity;

architecture dataflow of aluEntity is
signal aluAdd: std_ulogic_vector(15 downto 0);
signal aluSub: std_ulogic_vector(15 downto 0);
signal aluCopy: std_ulogic_vector(15 downto 0);
signal aluAnd: std_ulogic_vector(15 downto 0);
signal aluOr: std_ulogic_vector(15 downto 0);
signal aluXor: std_ulogic_vector(15 downto 0);
signal aluNor: std_ulogic_vector(15 downto 0);
signal aluSlt: std_ulogic_vector(15 downto 0);
signal op2Complement: std_ulogic_vector(15 downto 0);

begin

-- Compute all results 
addition: alu.addVector port map(
	a => op1Input,
	b => op2Input,
	f => aluAdd);

complementOp2: alu.complement 
   generic map(n => 15)
   port map(
   inputVector => op2Input,
   twosComplement => op2Complement);
	
subtraction: alu.addVector port map(
	a => op1Input,
	b => op2Complement,
	f => aluSub);

copy: alu.copyVector 
	generic map(n => 15)
	port map(
	op2Input => op2Input,
	copyOutput => aluCopy);
	
setOnLessThan: alu.sltVector 
	generic map(n => 15)
	port map(
	op1Input => op1Input,
	op2Input => op2Input,
	sltOutput => aluSlt);
	
andGate: alu.andVector
	generic map(n => 15)
   port map(
	op1Input => op1Input,
	op2Input => op2Input,
	andOutput => aluAnd);

orGate: alu.orVector 
	generic map(n => 15)
	port map(
	op1Input => op1Input,
	op2Input => op2Input,
	orOutput => aluOr);

xorGate: alu.xorVector 
   generic map(n => 15) 
	port map(
	op1Input => op1Input,
	op2Input => op2Input,
	xorOutput => aluXor);

norGate: alu.norVector 
   generic map(n => 15) 
	port map(
	op1Input => op1Input,
	op2Input => op2Input,
	norOutput => aluNor);
	
-- Multiplixer, choosing output based on functCode

	with functCode select
				
		aluOut <= aluAdd when "0000", -- Add
		aluSub when "0001", -- Subtract
		aluSlt when "0010", -- Set on less than
		aluCopy when "0011", -- Copy
		aluAnd when "0100", -- And
		aluOr when "0101", -- Or
		aluXor when "0110", -- Xor
		aluNor when "0111", -- Nor	
		x"0000" when others;
		
end architecture dataflow;