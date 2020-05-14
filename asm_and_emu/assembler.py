from instruction import Instruction, Directive, Comment
from codes import CodeEncoder
from copy import deepcopy
from utils import to_hex, zero_extend, to_twos_complement, arg_parse


class Assembler:
    def __init__(self):
        self._DEPTH = 1 << 15
        self._WIDTH = 1 << 4
        self._MAX = (1 << 16) - 1
        self._MAX_BYTE = (1 << 8) - 1
        self._MAX_INT = (1 << 15) - 1
        self._BYTES_PER_WORD = 2
        self._pc = 0
        self._symbol_table = {}
        self._codes = CodeEncoder()

    def parse(self, asm_file):
        """
        :param asm_file: .asm source file
        :return: parsed instructions
        """
        with open(asm_file, 'r') as f:
            asm_source = f.read()

        # First pass through the instructions.
        # Stores all instructions in a list, and builds the symbol table.
        instructions_list = []
        for raw_instruction in asm_source.split('\n'):
            raw_instruction = raw_instruction.strip()

            if not raw_instruction:  # Pass if empty line
                continue

            line_type = self.line_type(raw_instruction)

            if line_type == 'comment':
                instructions_list.append(self.parse_comment(raw_instruction))

            elif line_type == 'instruction':
                parsed_instruction = Instruction(raw_instruction)
                parsed_instruction.addr = self._pc
                self._pc += 2  # Since memory is byte-addressable and words are 16-bits

                # If we have li, split into lui and ori.
                if parsed_instruction.opname == 'li':
                    parsed_instruction.opname = 'li_lui'
                    parsed_instruction.opcode = self._codes.get_opcode('lui')
                    instructions_list.append(parsed_instruction)

                    # Ori part of instruction
                    ori_li_instruction = deepcopy(parsed_instruction)
                    ori_li_instruction.addr = self._pc
                    self._pc += 2
                    ori_li_instruction.opname = 'li_ori'
                    ori_li_instruction.opcode = self._codes.get_opcode('ori')
                    instructions_list.append(ori_li_instruction)
                else:
                    instructions_list.append(parsed_instruction)

            elif line_type == 'directive':
                # Needs to be a list since asciiz will return multiple lines of instructions.
                directive_list = self.parse_directive_to_list(raw_instruction)
                # Stores the first item's address to the symbol table
                first_in_mem = directive_list[0]
                self._symbol_table[first_in_mem.label] = self._pc
                for directive in directive_list:
                    directive.addr = self._pc
                    self._pc += 2
                    instructions_list.append(directive)

            else:
                assert line_type == 'label'
                self.store_label(raw_asm_line=raw_instruction, addr=self._pc)

        if len(instructions_list) > self._MAX:
            raise MemoryError("Instructions exceeded {}".format(self._MAX))

        encoded_instructions = []
        for instruction in instructions_list:
            encoded_instructions.append(self.encode(instruction))

        return encoded_instructions

    def parse_directive_to_list(self, raw_asm_line: str):
        directive = Directive(raw_instruction=raw_asm_line)
        if directive.type in ('.word', '.byte'):
            directive.value = to_hex(directive.value, num_bits=16)
            return [directive]
        elif directive.type == '.asciiz':
            ascii_str = directive.value
            ascii_str = self._undo_escape(ascii_str)
            # Partitions string every 2 characters. I.e. '12345' => '12', '34', '5'
            ascii_split_16bit = tuple(ascii_str[i: i + self._BYTES_PER_WORD]
                                      for i in range(0, len(ascii_str), self._BYTES_PER_WORD))
            directives_split_16bit = []
            # Stores a list of directives, each storing 2 chars
            # Converts each string into its hexadecimal ascii encoded format.
            for ascii_word in ascii_split_16bit:
                next_ascii_word = deepcopy(directive)
                next_ascii_word.content = f"\"{ascii_word}\""
                first_char = to_hex(ord(ascii_word[0]), num_bits=8)
                second_char = to_hex(ord(ascii_word[-1]), num_bits=8)
                next_ascii_word.value = second_char + first_char
                directives_split_16bit.append(next_ascii_word)

            # Padding null terminator.
            # Create new if string len is even, pad at end if odd.
            if len(ascii_str) % 2 == 0:
                null_directive = deepcopy(directive)
                null_directive.value = '0000'
                null_directive.content = r'"\0\0"'
                directives_split_16bit.append(null_directive)
            else:
                last_ascii = directives_split_16bit[-1]
                ascii_encoded = last_ascii.value
                len_half = len(ascii_encoded) // 2

                # For debugging
                error_msg = "Due to implementation, " \
                            "last directive should have stored two copies of same string"
                assert ascii_encoded[:len_half] == ascii_encoded[len_half:], error_msg

                # FIXME: Too convoluted and unintuitive
                ascii_char = ascii_encoded[:len_half]
                null_terminator = '00'
                last_ascii.value = null_terminator + ascii_char
                # Recovers original letter from hex encoding
                last_ascii.content = "\"" + chr(int(ascii_char, 16)) + r'\0' + "\""

            return directives_split_16bit

        else:
            raise SyntaxError(f"Expected .word or .byte of .asciiz, but got {directive.content}")

    # TODO: can i reduce boilerplate code?
    def encode(self, instruction):
        if instruction.instruct_type == 'comment':
            return instruction.comment

        elif instruction.instruct_type == 'directive':
            encoded = str(instruction.value)
        else:
            assert instruction.instruct_type == 'instruction', \
                "Instruction type should be a comment, directive, or instruction"

            # Label assignment begin
            if instruction.rd in self._symbol_table.keys():
                instruction.rd = self._symbol_table[instruction.rd]
            if instruction.rs in self._symbol_table.keys():
                instruction.rs = self._symbol_table[instruction.rs]
            if instruction.immediate in self._symbol_table.keys():
                instruction.immediate = self._symbol_table[instruction.immediate]
            if instruction.branch_addr in self._symbol_table.keys():
                instruction.branch_addr = self._symbol_table[instruction.branch_addr]
            if instruction.jump_addr in self._symbol_table.keys():
                instruction.jump_addr = self._symbol_table[instruction.jump_addr]
            # Label assignment end

            encoded = ''
            encoded += to_hex(instruction.opcode, debug_instruction=instruction)

            # alu-type instructions all have 4-bit operands
            if instruction.optype == 'alu':
                for operand in (instruction.rd, instruction.rs, instruction.funct_code):
                    operand = self.return_if_int(operand, instruction=instruction)
                    encoded += to_hex(operand, num_bits=4)

            # immediate instruction should have 4-bit registers, and 8 bit immediates
            elif instruction.optype == 'alui':
                instruction.rd = self.return_if_int(instruction.rd,
                                                    instruction=instruction)
                instruction.immediate = self.return_if_int(instruction.immediate,
                                                           instruction=instruction)

                encoded += to_hex(instruction.rd, num_bits=4)
                encoded += to_hex(instruction.immediate, num_bits=8, debug_instruction=instruction)
            # All fields of mem instructions have 4 bits
            elif instruction.optype == 'mem':
                for operand in (instruction.rd, instruction.rs, instruction.mem_offset):
                    operand = self.return_if_int(operand,
                                                 instruction=instruction)
                    encoded += to_hex(operand, num_bits=4)

            # Branch offsets are calculated by target address - next pc address,
            # then shifted right one bit
            elif instruction.optype == 'branch':
                instruction.rd = self.return_if_int(instruction.rd,
                                                    instruction=instruction)
                instruction.branch_addr = self.return_if_int(instruction.branch_addr,
                                                             instruction=instruction)
                encoded += to_hex(instruction.rd, num_bits=4)

                # Calculation of branch offset
                next_pc_addr = instruction.addr + self._BYTES_PER_WORD
                branch_offset = instruction.branch_addr - next_pc_addr
                branch_offset = branch_offset >> 1

                encoded += to_hex(branch_offset, num_bits=8)

            # Jump field should be 12 bits long.
            # Jump addresses are also shifted left one bit.
            elif instruction.opname in ('j', 'jal'):
                instruction.jump_addr = self.return_if_int(instruction.jump_addr,
                                                           instruction=instruction)
                if instruction.jump_addr < 0:
                    raise MemoryError(f"Expected memory value, got {instruction.jump_addr}\n"
                                      f"Instruction: {instruction.content}")

                # Calculation of jump addr
                jump_addr = instruction.jump_addr >> 1
                encoded += zero_extend(jump_addr, num_bits=12)

            elif instruction.opname == 'jr':
                instruction.jump_addr = self.return_if_int(instruction.jump_addr,
                                                           instruction=instruction)
                encoded += zero_extend(instruction.jump_addr, num_bits=4)
                encoded += '00'

            # Parses li pseudoinstruction.
            elif instruction.optype == 'pseudo':
                assert 'li' in instruction.opname, "Only pseudoinstruction is li"
                instruction.rd = self.return_if_int(instruction.rd,
                                                    instruction=instruction)
                encoded += to_hex(instruction.rd, num_bits=4)

                # Depending on lui or ori, takes the first two or last two hex digits.
                if instruction.opname == 'li_lui':
                    instruction.immediate = self.return_if_int(instruction.immediate,
                                                               instruction=instruction)
                    immediate = to_twos_complement(instruction.immediate, num_bits=16)
                    encoded += to_hex(immediate, num_bits=16)[:2]
                elif instruction.opname == 'li_ori':
                    instruction.immediate = self.return_if_int(instruction.immediate,
                                                               instruction=instruction)
                    immediate = to_twos_complement(instruction.immediate, num_bits=16)
                    encoded += to_hex(immediate, num_bits=16)[2:]
                else:
                    print(f"Expected li instruction, got {instruction.opname}\n"
                          f"Instruction: {instruction.content}")

            else:
                raise SyntaxError(f"Expected proper optype, got {instruction.optype}\n"
                                  f"Instruction: {instruction.content}")

            # instructions in hex, so 4 * 4 = 16-bit words
            assert len(encoded) == 4, f"Expected hex length 4, got {encoded}\n" \
                                      f"Instruction: {instruction.content}"

        # Comments and assembly code
        encoded += '; -- ' + repr(instruction.content)
        if instruction.comment:
            encoded += instruction.comment
        assert instruction.addr % 2 == 0, f"Expected word-aligned instruction, got {instruction.content}"
        mif_index = zero_extend(instruction.addr // 2, num_bits=16)
        encoded = mif_index + ' : ' + encoded

        return encoded

    def store_label(self, raw_asm_line: str, addr: int):
        label = raw_asm_line[:raw_asm_line.find(':')]
        if label in self._symbol_table.keys():
            raise SyntaxError(f"Reassigning {label} when it is already assigned")
        else:
            self._symbol_table[label] = addr

    @staticmethod
    def parse_comment(raw_asm_line: str):
        assert raw_asm_line.find('--') == 0
        comment = Comment()
        comment.comment = raw_asm_line
        return comment

    @staticmethod
    def line_type(raw_asm_line):
        raw_asm_line = raw_asm_line.strip()  # Remove whitespace

        if '--' in raw_asm_line:
            # Remove comments
            where_comment = raw_asm_line.find('--')
            raw_asm_line = raw_asm_line[:where_comment].strip()

            # If the line is just a comment
            if not raw_asm_line:
                return 'comment'

        if ':' not in raw_asm_line:
            return 'instruction'
        elif '.' in raw_asm_line:
            return 'directive'
        # Check if the statement ends after the colon
        elif len(raw_asm_line) == raw_asm_line.find(':') + 1:
            return 'label'
        else:
            raise SyntaxError(f"Unknown instruction type: \n{raw_asm_line}")

    @staticmethod
    def make_valid_int(input_str: str, max_val: int):
        try:
            input_int = int(input_str, 0x10)
            if input_int > max_val:
                raise SyntaxError(f"Expected max word size {max_val}, got {input_int}")
        except ValueError:
            raise SyntaxError(f"Expected an integer, got {input_str}")

        return input_str

    @staticmethod
    def return_if_int(value, instruction: Instruction):
        """
        Returns an int if the input(usually string or int) can be parsed as as an int.
        Raises error otherwise.
        :param value: value to check if it can be parsed as an int
        :param instruction: instruction, used for debugging purposes.
        :return: the integer value of the <value> param.
        """
        try:
            value = int(value)
        except ValueError:
            raise SyntaxError(f"Expected integer, but got {value}.\n"
                              f"Instruction: "
                              f"{instruction.addr} : {instruction.content}")

        return value

    @staticmethod
    def _undo_escape(text):
        text = text.replace(r'\t', '\t')
        text = text.replace(r'\r', '\r')
        text = text.replace(r'\n', '\n')
        return text

    def mif_write(self, encoded_instructions, output_name):
        print("Encoding asm file...")
        output_str = f"WIDTH = {self._WIDTH};\n"
        output_str += f"DEPTH = {self._DEPTH};\n"
        output_str += "ADDRESS_RADIX = HEX;\n"
        output_str += "DATA_RADIX = HEX;\n"
        output_str += "CONTENT;\nBEGIN\n\n"
        output_str += '\n'.join(encoded_instructions)
        output_str += '\n\nEND'
        with open(output_name, 'w') as f:
            f.write(output_str)
        print("Success!")


if __name__ == "__main__":
    input_file, output_file = arg_parse(file_extension='.asm',
                                        enforce_second=True)

    assembler = Assembler()
    mif_instructions = assembler.parse(asm_file=input_file)
    assembler.mif_write(mif_instructions, output_name=output_file)
