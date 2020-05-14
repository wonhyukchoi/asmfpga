library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sequencer is port(
	sysclk1: in std_ulogic;
	mem_dataready_inv, mem_reset: in std_ulogic;
	instruction: in std_ulogic_vector(15 downto 0);
	alu_result: in std_ulogic_vector(15 downto 0);

	load_pc, addr_from_pc_or_alu, load_ir: out std_ulogic;
	mem_addr_ready, mem_rw,
	mem_sixteenbit: out std_ulogic;
	reg_read_or_write: out std_ulogic;
	fsm_state: out std_ulogic_vector(4 downto 0));
end entity sequencer;

architecture behavioral of sequencer is 
type StateType is (idle, ir_fetch, write_register, branch, j, jal, jr,
	pc_fetch_0, pc_fetch_1, pc_fetch_2, pc_fetch_3, pc_fetch_4_5, pc_fetch_6_8,
	load_1, load_2, load_3, load_4_5, load_6_8,
	store_1, store_2, store_3, store_4_5, store_7_8_9);
signal presentState: StateType := idle;
signal byteAccess: std_ulogic;
signal isMemInstruction: std_ulogic;
signal opCode: std_ulogic_vector(3 downto 0) := instruction(15 downto 12);

begin

-- combinatorial logic 
load_pc <= '1' when (presentState = pc_fetch_0) else '0';

with presentState select
	addr_from_pc_or_alu <= '0' when pc_fetch_0 | pc_fetch_1 | 
							pc_fetch_2 |  pc_fetch_3 | pc_fetch_4_5,
			               '1' when others;

load_ir <= '1' when (presentState = ir_fetch) else '0';

reg_read_or_write <= '1' when (presentState = write_register) else '0';

with presentState select
	mem_rw <= '1' when store_2 | store_3 | store_4_5,
	                   '0' when others;

with presentState select
	mem_addr_ready <= '1' when load_3 | pc_fetch_3 |
							   load_4_5 | pc_fetch_4_5 |
							   store_3 | store_4_5,
					  '0' when others;
with opCode select
	byteAccess <= '1' when x"8" | x"a",
					  '0' when others;

with presentState select
	isMemInstruction <= '1' when load_2 | store_2 |
								load_3 | store_3 | 
								load_4_5 | store_4_5,
					   '0' when others;

mem_sixteenbit <= not(byteAccess and isMemInstruction);

with presentState select
	fsm_state <= "00000" when idle,
				 "00001" when ir_fetch,
				 "00010" when write_register,
				 "00011" when branch,
				 "00100" when j,
				 "00101" when jr,
				 "00110" when pc_fetch_0,
				 "00111" when pc_fetch_1,
				 "01000" when pc_fetch_2,
				 "01001" when pc_fetch_3,
				 "01010" when pc_fetch_4_5,
				 "01011" when pc_fetch_6_8,
				 "01100" when load_1,
				 "01101" when load_2,
				 "01110" when load_3,
				 "01111" when load_4_5,
				 "10000" when load_6_8,
				 "10001" when store_1,
				 "10010" when store_2,
				 "10011" when store_3,
				 "10100" when store_4_5,
				 "10101" when jal,
				 "10110" when store_7_8_9;

-- FSM logic 

	FSM: process(sysclk1, mem_reset) is 
		variable nextState: StateType;

	begin

		if mem_reset = '1' then
			nextState := idle;

		elsif falling_edge(sysclk1) then	

			case presentState is
				when idle => 
					nextState := pc_fetch_1;

				when ir_fetch =>
					if (unsigned(opCode) < x"8") then
						nextState := write_register;
					elsif (opCode = x"8") then
						nextState := load_1;
					elsif (opCode = x"9") then
						nextState := load_1;
					elsif (opCode = x"a") then
						nextState := store_1;
					elsif (opCode = x"b") then
						nextState := store_1;
					elsif (opCode = x"c") then
						nextState := branch;
					elsif (opCode = x"f") then
						nextState := jr;
					elsif (opCode = x"c") then
						nextState := j;
					else
						nextState := jal;
					end if;

				when write_register | branch | j | jr =>
					nextState := pc_fetch_0;

				when jal =>
					nextState := write_register;

				when pc_fetch_0 =>
					nextState := pc_fetch_1;
				when pc_fetch_1 => 
					if (mem_dataready_inv = '0') then
						nextState := pc_fetch_1;
					else
						nextState := pc_fetch_2;
					end if;
				when pc_fetch_2 =>
					nextState := pc_fetch_3;
				when pc_fetch_3 =>
					nextState := pc_fetch_4_5;
				when pc_fetch_4_5 =>
					if (mem_dataready_inv = '1') then
						nextState := pc_fetch_4_5;
					else
						nextState := pc_fetch_6_8;
					end if;
				when pc_fetch_6_8 =>
					nextState := ir_fetch;


				when load_1 => 
					if (mem_dataready_inv = '0') then
						nextState := load_1;
					else
						nextState := load_2;
					end if;
				when load_2 =>
					nextState := load_3;
				when load_3 =>
					nextState := load_4_5;
				when load_4_5 =>
					if (mem_dataready_inv = '1') then
						nextState := load_4_5;
					else
						nextState := load_6_8;
					end if;
				when load_6_8 =>
					nextState := write_register;


				when store_1 =>
					if (mem_dataready_inv = '0') then
						nextState := store_1;
					else
						nextState := store_2;
					end if;
				when store_2 =>
					nextState := store_3;
				when store_3 =>
					nextState := store_4_5;
				when store_4_5 =>
					if (mem_dataready_inv = '1') then 
						nextState := store_4_5;
					else
						nextState := store_7_8_9;
					end if;
				when store_7_8_9 =>
					nextState := pc_fetch_0;

			end case;
		end if;

		presentState <= nextState;		
	
	end process FSM;

end behavioral;