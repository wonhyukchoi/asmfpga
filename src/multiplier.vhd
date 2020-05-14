library ieee;
library alu;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity multiplier is
  port (multiplicand, multiplier: in std_ulogic_vector(15 downto 0);
        result: out std_ulogic_vector(15 downto 0) := x"0000");
end entity multiplier;

architecture dataflow of multiplier is

signal cand0, cand1, cand2, cand3, cand4, cand5, cand6, cand7,
       cand8, cand9, cand10, cand11, cand12, cand13, cand14, cand15, 
       leaf0, leaf1, leaf2, leaf3, leaf4, leaf5, leaf6, leaf7,
       leaf8, leaf9, leaf10, leaf11, leaf12, leaf13, leaf14, leaf15,
       depth_4_0, depth_4_1, depth_4_2, depth_4_3,
       depth_4_4, depth_4_5, depth_4_6, depth_4_7,
       depth_3_0, depth_3_1, depth_3_2, depth_3_3,
       depth_2_0, depth_2_1: 
       std_ulogic_vector(15 downto 0);

begin

-- Multiplier is logarithmic ander & adder.
-- Requires a total of 16 + 8 + 4 + 2 + 1 = 31 gates, 
-- with gate delay of 4 gates.

node0: work.repeatBits
  port map(
  one_bit => multiplicand(0),
  sixteen_bits => cand0);
leaf_0: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand0,
  andOutput => leaf0);

node1: work.repeatBits
  port map(
  one_bit => multiplicand(1),
  sixteen_bits => cand1);
leaf_1: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand1,
  andOutput => leaf1);

node2: work.repeatBits
  port map(
  one_bit => multiplicand(2),
  sixteen_bits => cand2);
leaf_2: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand2,
  andOutput => leaf2);

node3: work.repeatBits
  port map(
  one_bit => multiplicand(3),
  sixteen_bits => cand3);
leaf_3: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand3,
  andOutput => leaf3);

node4: work.repeatBits
  port map(
  one_bit => multiplicand(4),
  sixteen_bits => cand4);
leaf_4: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand4,
  andOutput => leaf4);

node5: work.repeatBits
  port map(
  one_bit => multiplicand(5),
  sixteen_bits => cand5);
leaf_5: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand5,
  andOutput => leaf5);

node6: work.repeatBits
  port map(
  one_bit => multiplicand(6),
  sixteen_bits => cand6);
leaf_6: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand6,
  andOutput => leaf6);

node7: work.repeatBits
  port map(
  one_bit => multiplicand(7),
  sixteen_bits => cand7);
leaf_7: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand7,
  andOutput => leaf7);

node8: work.repeatBits
  port map(
  one_bit => multiplicand(8),
  sixteen_bits => cand8);
leaf_8: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand8,
  andOutput => leaf8);

node9: work.repeatBits
  port map(
  one_bit => multiplicand(9),
  sixteen_bits => cand9);
leaf_9: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand9,
  andOutput => leaf9);

node10: work.repeatBits
  port map(
  one_bit => multiplicand(10),
  sixteen_bits => cand10);
leaf_10: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand10,
  andOutput => leaf10);

node11: work.repeatBits
  port map(
  one_bit => multiplicand(11),
  sixteen_bits => cand11);
leaf_11: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand11,
  andOutput => leaf11);

node12: work.repeatBits
  port map(
  one_bit => multiplicand(12),
  sixteen_bits => cand12);
leaf_12: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand12,
  andOutput => leaf12);

node13: work.repeatBits
  port map(
  one_bit => multiplicand(13),
  sixteen_bits => cand13);
leaf_13: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand13,
  andOutput => leaf13);

node14: work.repeatBits
  port map(
  one_bit => multiplicand(14),
  sixteen_bits => cand14);
leaf_14: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand14,
  andOutput => leaf14);

node15: work.repeatBits
  port map(
  one_bit => multiplicand(15),
  sixteen_bits => cand15);
leaf_15: alu.andVector
  generic map(n => 15)
  port map(
  op1Input => multiplier,
  op2Input => cand15,
  andOutput => leaf15);

d4_0: alu.addVector
  port map(
  a => leaf0,
  b => std_ulogic_vector(shift_left(signed(leaf1), 1)),
  f => depth_4_0);

d4_1: alu.addVector
  port map(
  a => std_ulogic_vector(shift_left(signed(leaf2), 2)),
  b => std_ulogic_vector(shift_left(signed(leaf3), 3)),
  f => depth_4_1);

d4_2: alu.addVector
  port map(
  a => std_ulogic_vector(shift_left(signed(leaf4), 4)),
  b => std_ulogic_vector(shift_left(signed(leaf5), 5)),
  f => depth_4_2);

d4_3: alu.addVector
  port map(
  a => std_ulogic_vector(shift_left(signed(leaf6), 6)),
  b => std_ulogic_vector(shift_left(signed(leaf7), 7)),
  f => depth_4_3);

d4_4: alu.addVector
  port map(
  a => std_ulogic_vector(shift_left(signed(leaf8), 8)),
  b => std_ulogic_vector(shift_left(signed(leaf9), 9)),
  f => depth_4_4);

d4_5: alu.addVector
  port map(
  a => std_ulogic_vector(shift_left(signed(leaf10), 10)),
  b => std_ulogic_vector(shift_left(signed(leaf11), 11)),
  f => depth_4_5);

d4_6: alu.addVector
  port map(
  a => std_ulogic_vector(shift_left(signed(leaf12), 12)),
  b => std_ulogic_vector(shift_left(signed(leaf13), 13)),
  f => depth_4_6);

d4_7: alu.addVector
  port map(
  a => std_ulogic_vector(shift_left(signed(leaf14), 14)),
  b => std_ulogic_vector(shift_left(signed(leaf15), 15)),
  f => depth_4_7);

d3_0: alu.addVector
  port map(
  a => depth_4_0,
  b => depth_4_1,
  f => depth_3_0); 

d3_1: alu.addVector
  port map(
  a => depth_4_2,
  b => depth_4_3,
  f => depth_3_1); 

d3_2: alu.addVector
  port map(
  a => depth_4_4,
  b => depth_4_5,
  f => depth_3_2); 

d3_3: alu.addVector
  port map(
  a => depth_4_6,
  b => depth_4_7,
  f => depth_3_3); 

d2_0: alu.addVector
  port map(
  a => depth_3_0,
  b => depth_3_1,
  f => depth_2_0);

d2_1: alu.addVector
  port map(
  a => depth_3_2,
  b => depth_3_3,
  f => depth_2_1);

root: alu.addVector
  port map(
  a => depth_2_0,
  b => depth_2_1,
  f => result);

end architecture dataflow;