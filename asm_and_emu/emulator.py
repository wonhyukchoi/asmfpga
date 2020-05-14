import re
from codes import CodeDecoder
from executor import Executor
from utils import arg_parse


# TODO: try mult
class Emulator:
    """
    Abandon all hope, ye who enter here.
    """
    def __init__(self):
        self._MAX_BITS = 16
        self._REG_IOBUFFER_1 = 0xff04
        self._register = {i: 0 for i in range(self._MAX_BITS)}
        self._mult_register = [0]  # Immutables cannot be passed in by value
        self._memory = {i: '' for i in range(2 ** self._MAX_BITS)}
        self._debug_memory = {i: '' for i in range(2 ** self._MAX_BITS)}
        self._decoder = CodeDecoder()
        self._executor = Executor(register=self._register,
                                  mult_register=self._mult_register,
                                  memory=self._memory)
        self._pc = 0
        self._message = ''
        self._io_buffer = []

        self._reg_io_init()

    # FIXME: needs to end properly if we don't have infinite loops
    def run(self, debug_mode='default'):
        """
        :param debug_mode: can say 'break'
        :return:
        """
        debug_mode = debug_mode.lower().strip()

        while True:
            # For debugging
            old_register = {k: v for k, v in self._register.items()}
            old_memory = {k: v for k, v in self._memory.items()}

            self._execute(debug=debug_mode)

            # Shows changes in registers and memory
            if debug_mode:
                print({self._decoder.get_reg_decoded(k): v for k, v in self._register.items()})
                self.print_changes(old_register, self._register, 'register')
                self.print_changes(old_memory, self._memory, 'memory')

                if debug_mode == 'break':
                    # Auto break point
                    input("Process halted. Press enter to continue.\n")

    # FIXME: convoluted
    def _execute(self, debug='default'):
        instruction = self._get_word(self._pc)
        comment = self._debug_memory[self._pc]

        if debug:
            print(f"PC {self._pc}: {instruction} {comment}")

        self._pc += 2

        if self._is_break_point(instruction):
            self._activate_break_point(instruction)

        elif self._is_load_iobuffer1(instruction):
            if not self._io_buffer:
                self._io_buffer = self._prompt_user()
            self._memory[self._REG_IOBUFFER_1] = self._io_buffer.pop()

        op_exec_type = self._decoder.get_op_exec_type(instruction)

        if op_exec_type == 'reg_mem':
            self._executor.execute(instruction, comment)
        elif op_exec_type == 'jump_branch':
            target_addr = self._executor.calc_addr(instruction, self._pc, comment)
            self._pc = target_addr
        else:
            raise SyntaxError(f"Undefined instruction: {instruction}"
                              f"\n Instruction: {self._debug_memory[self._pc - 2]}")

        # Print result of stored iobuffer
        if self._is_store_iobuffer1(instruction):
            char_out = self._memory[self._REG_IOBUFFER_1]
            char_out = chr(int(char_out, 16))
            print(char_out, end='')

    @staticmethod
    def _is_break_point(machine_code: str) -> bool:
        """
        Activate break point if we try to copy a register to itself.
        :param machine_code: a string of machine code, i.e. 0113
        :return: a boolean
        """
        is_alu = machine_code[0] == '0'
        is_copy = machine_code[3] == '3'
        same_reg = machine_code[1] == machine_code[2]
        return all((is_alu, is_copy, same_reg))

    def _activate_break_point(self, machine_code: str):
        print("\nBreak point activated.")
        reg_value = int(machine_code[1], 16)
        print(f"The value of register "
              f"{self._decoder.get_reg_decoded(reg_value)} is "
              f"{self._register[reg_value]}")
        print({self._decoder.get_reg_decoded(k): v for
               k, v in self._register.items()})
        while True:
            break_key = input("Press ^ to continue.")
            if break_key == '^':
                break

    # FIXME: make this cleaner
    @staticmethod
    def _prompt_user() -> list:
        prompt = "\n"

        def is_valid(ascii_encoding: str, sign_bit=False) -> bool:
            """
            ASCII TABLE
            45 : '-'
            48 ~ 57 : '1 ~ 9'
            :param ascii_encoding: char in ascii, stored as string
            :param sign_bit: if it's the first bit or not
            :return: boolean
            """
            ascii_code = int(ascii_encoding, 16)
            is_neg_sign = False
            if sign_bit:
                is_neg_sign = ascii_code == 0x2d
            is_num = 0x30 <= ascii_code <= 0x39
            return any((is_neg_sign, is_num))

        # Checks that input is valid
        while True:
            input_string = input(prompt)
            if len(input_string) > 6:
                print(f"Expected input of maximum 6 characters, "
                      f"but got {input_string}")
                continue

            # [2:] needed to remove the "0x"
            ascii_array = [hex(ord(char))[2:] for char in input_string]

            valid = True

            # If any of our ascii characters are not
            # - or any of our decimal numerals
            if not is_valid(ascii_array[0], sign_bit=True):
                valid = False
                print(f"{ascii_array[0]} is not a proper number")

            for i in range(1, len(ascii_array)):
                ascii_char = ascii_array[i]
                if not is_valid(ascii_char):
                    valid = False
                    print(f"{ascii_char} is not a proper number")
                    break

            # Reverse and add null terminator for popping
            if valid:
                ascii_array.reverse()
                ascii_array = ['00'] + ascii_array
                return ascii_array

    def _is_load_iobuffer1(self, machine_code: str):
        r2 = int(machine_code[2], 16)
        r2_val = self._register[r2]
        is_iobuffer_1 = r2_val == self._REG_IOBUFFER_1

        # Hack by using magic numbers
        lb_code = 8
        lw_code = 9
        opcode = int(machine_code[0], 16)
        is_load = (opcode == lb_code) or (opcode == lw_code)

        return is_load and is_iobuffer_1

    def _is_store_iobuffer1(self, machine_code: str):
        r2 = int(machine_code[2], 16)
        r2_val = self._register[r2]
        is_iobuffer_1 = r2_val == self._REG_IOBUFFER_1

        # Hack by using magic numbers
        sb_code = 10
        sw_code = 11
        opcode = int(machine_code[0], 16)
        is_store = (opcode == sb_code) or (opcode == sw_code)

        return is_store and is_iobuffer_1

    @staticmethod
    def print_changes(old_values: dict, new_values: dict, type_name: str):
        for key, value in new_values.items():
            if new_values[key] != old_values[key]:
                print(f"Value of {type_name} {key} changed from "
                      f"{old_values[key]} to {new_values[key]}")

    def _get_word(self, addr: int):
        low_byte = self._memory[addr]
        high_byte = self._memory[addr + 1]
        word = high_byte + low_byte
        return word

    def _reg_io_init(self):
        """
        Sets all bits of REG_IOCONTROL to 1
        :return: None
        """
        REG_IOCONTROL = 0xff00
        self._memory[REG_IOCONTROL] = 'ffff'

    def load_mif(self, mif_text: str):
        """
        Parses mif files and stores instructions into memory.
        Note: mif file indices are word-addressable,
        so we need to convert them into byte-addressable addresses.
        :param mif_text: A line-delineated string, the mif file
        :return: None
        """
        for line in mif_text.split('\n'):
            regex_pattern = re.compile(r'^([0-9a-f]+) : ([0-9a-f]+);')
            regex_match = re.match(regex_pattern, line)
            if regex_match:
                mif_index, instruction = regex_match.groups()
                # Parse instruction into bytes
                assert len(instruction) == 4, f'Expected word size 16 bits, ' \
                                              f'but got {len(instruction)}' \
                                              f'Instruction: {line}'
                one_byte = 2
                high_byte = instruction[:one_byte]
                low_byte = instruction[one_byte:]
                # Save instructions to memory addresses parsed from mif index
                addr = int(mif_index, 16) * 2
                self._memory[addr] = low_byte
                self._memory[addr + 1] = high_byte

                # For debugging
                where_comment = line.find('--')
                assert where_comment == 13, f"Comment should start at the 13th char," \
                                            f"but got {line}"
                comment = line[where_comment:]
                self._debug_memory[addr] = comment

    @property
    def memory(self):
        return self._memory


if __name__ == "__main__":
    input_file, debug_arg = arg_parse(file_extension='.mif',
                                      enforce_second=False)
    emulator = Emulator()
    with open(input_file, 'r') as f:
        emulator.load_mif(mif_text=f.read())
    emulator.run(debug_mode=debug_arg)
