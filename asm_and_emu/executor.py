from codes import CodeDecoder
from utils import to_hex, from_twos_complement


# TODO: I should make pylint happy
class Executor:
    def __init__(self, register: dict, mult_register: list,
                 memory: dict):
        self._MAX_UNSIGNED = (1 << 16) - 1
        self._MAX_BYTE_UNSIGNED = (1 << 8) - 1
        self._register = register
        self._mult_register = mult_register
        self._memory = memory
        self._decoder = CodeDecoder()
        self._alu_funs = {
            'add': self._add_execute,
            'sub': self._sub_execute,
            'slt': self._slt_execute,
            'cp': self._cp_execute,
            'and': self._and_execute,
            'or': self._or_execute,
            'xor': self._xor_execute,
            'nor': self._nor_execute,
            'sll': self._sll_execute,
            'srl': self._srl_execute,
            'sra': self._sra_execute,
            'mult': self._mult_execute,
            'multload': self._multload_execute,
        }
        self._immediate_funs = {
            'addi': self._addi_execute,
            'subi': self._subi_execute,
            'slti': self._slti_execute,
            'lui': self._lui_execute,
            'andi': self._andi_execute,
            'ori': self._ori_execute,
            'xori': self._xori_execute
        }
        self._mem_funs = {
            'lb': self._lb_execute,
            'lw': self._lw_execute,
            'sb': self._sb_execute,
            'sw': self._sw_execute
        }

    def execute(self, instruction: str, comment: str):
        optype = self._decoder.get_optype(instruction)
        if optype == 'alu':
            self._alu_execute(instruction, comment)
        elif optype == 'alui':
            self._immediate_execute(instruction, comment)
        elif optype == 'mem':
            self._mem_execute(instruction, comment)
        else:
            raise SyntaxError(f"Expected alu, alui, or mem instruction, got {instruction}\n"
                              f"Instruction: {comment}")

    def _alu_execute(self, instruction: str, comment: str):
        funct_name = self._decoder.get_funct_code(instruction)
        funct = self._alu_funs[funct_name]
        r1, r2 = self._get_r1_r2(instruction, comment)
        funct(r1, r2)

    def _immediate_execute(self, instruction: str, comment: str):
        opname = self._decoder.get_opname(instruction)
        funct = self._immediate_funs[opname]
        r1, immediate = self._get_r1_and_immediate(instruction, comment)
        funct(r1, immediate)

    def _mem_execute(self, instruction: str, comment: str):
        """
        As long as you don't try to load instructions into memory,
        this should work.
        If you try to load an instruction into memory...
        well, you'll break my code.
        :param instruction: a string of 4 hex chars
        :param comment: the actual asm instruction, for debugging purposes
        :return: None
        """
        opname = self._decoder.get_opname(instruction)
        funct = self._mem_funs[opname]
        r1, base, offset = self._get_r1_base_offset(instruction, comment)
        funct(r1, base, offset, comment)

    def calc_addr(self, instruction: str, pc: int, comment: str):
        opname = self._decoder.get_opname(instruction)

        if opname == 'beq':
            r1, immediate = self._get_r1_and_immediate(instruction, comment)
            return self._beq_execute(r1=r1, immediate=immediate, pc=pc)

        elif opname == 'j':
            return self._get_j_addr(instruction, comment)

        elif opname == 'jal':
            # Linking
            ra = self._decoder.get_regcode('$ra')
            self._register[ra] = pc
            return self._get_j_addr(instruction, comment)

        elif opname == 'jr':
            return self._get_jr_addr(instruction, comment)

        else:
            raise SyntaxError(f"Expected branch or jump, but got {instruction}\n"
                              f"Instruction: {comment}")

    #################
    # ALU functions #
    #################

    def _add_execute(self, r1: int, r2: int):
        r1_val = self._register[r1]
        r2_val = self._register[r2]
        result = r1_val + r2_val
        self._register[r1] = result

    def _sub_execute(self, r1: int, r2: int):
        """
        FIXME: Emulator-wise, this bugs on the edge case of -32768,
        FIXME: but I think this should work on actual hardware
        :param r1:
        :param r2:
        :return:
        """
        r1_val = self._register[r1]
        r2_val = self._register[r2]
        r2_val = from_twos_complement(r2_val, num_bits=16)
        result = r1_val - r2_val
        self._register[r1] = result

    def _slt_execute(self, r1: int, r2: int):
        r1_val = self._register[r1]
        r2_val = self._register[r2]
        result = 0 if r1_val < r2_val else 1
        self._register[r1] = result

    def _cp_execute(self, r1: int, r2: int):
        r2_val = self._register[r2]
        result = r2_val
        self._register[r1] = result

    def _and_execute(self, r1: int, r2: int):
        r1_val = self._register[r1]
        r2_val = self._register[r2]
        result = r1_val & r2_val
        self._register[r1] = result

    def _or_execute(self, r1: int, r2: int):
        r1_val = self._register[r1]
        r2_val = self._register[r2]
        result = r1_val | r2_val
        self._register[r1] = result

    def _xor_execute(self, r1: int, r2: int):
        r1_val = self._register[r1]
        r2_val = self._register[r2]
        result = r1_val ^ r2_val
        self._register[r1] = result

    def _nor_execute(self, r1: int, r2: int):
        r1_val = self._register[r1]
        r2_val = self._register[r2]
        result = ~(r1_val | r2_val)
        self._register[r1] = result

    def _sll_execute(self, r1: int, r2: int):
        r1_val = self._register[r1]
        r2_val = self._register[r2]
        result = r1_val << r2_val
        self._register[r1] = result

    def _srl_execute(self, r1: int, r2: int):
        r1_val = self._register[r1]
        r2_val = self._register[r2]
        result = r1_val >> r2_val
        self._register[r1] = result

    def _sra_execute(self, r1: int, r2: int):
        raise NotImplementedError

    def _mult_execute(self, r1: int, r2: int):
        r1_val = self._register[r1]
        r2_val = self._register[r2]
        result = r1_val * r2_val
        self._mult_register[0] = result

    def _multload_execute(self, r1: int, r2: int):
        self._register[r1] = self._mult_register[0]
        print('yo')

    #######################
    # Immediate functions #
    #######################

    def _addi_execute(self, r1: int, immediate: int):
        r1_val = self._register[r1]
        result = r1_val + immediate
        self._register[r1] = result

    def _subi_execute(self, r1: int, immediate: int):
        r1_val = self._register[r1]
        immediate = from_twos_complement(immediate, num_bits=8)
        result = r1_val - immediate
        self._register[r1] = result

    def _slti_execute(self, r1: int, immediate: int):
        r1_val = self._register[r1]
        result = 0 if r1_val < immediate else 1
        self._register[r1] = result

    def _lui_execute(self, r1: int, immediate: int):
        result = immediate << 8
        self._register[r1] = result

    def _andi_execute(self, r1: int, immediate: int):
        r1_val = self._register[r1]
        result = r1_val & immediate
        self._register[r1] = result

    def _ori_execute(self, r1: int, immediate: int):
        r1_val = self._register[r1]
        result = r1_val | immediate
        self._register[r1] = result

    def _xori_execute(self, r1: int, immediate: int):
        r1_val = self._register[r1]
        result = r1_val ^ immediate
        self._register[r1] = result

    ####################
    # Memory functions #
    ####################

    def _lw_execute(self, r1: int, base: int, offset: int, comment: str):
        base_addr = self._register[base]
        target_addr = base_addr + offset
        value_at_addr = self._get_word_and_parse(addr=target_addr, comment=comment)
        self._register[r1] = value_at_addr

    def _lb_execute(self, r1: int, base: int, offset: int, comment: str):
        base_addr = self._register[base]
        target_addr = base_addr + offset
        value_at_addr = self._get_byte_and_parse(addr=target_addr, comment=comment)
        self._register[r1] = value_at_addr

    def _sw_execute(self, r1: int, base: int, offset: int, comment: str):
        base_addr = self._register[base]
        target_addr = base_addr + offset

        r1_value = self._register[r1]
        val_as_hex = to_hex(value=r1_value, num_bits=16, debug_comment=comment)
        one_byte = 2
        high_byte = val_as_hex[:one_byte]
        low_byte = val_as_hex[one_byte:]
        self._memory[target_addr] = low_byte
        self._memory[target_addr + 1] = high_byte

    def _sb_execute(self, r1: int, base: int, offset: int, comment: str):
        base_addr = self._register[base]
        target_addr = base_addr + offset

        r1_value = self._register[r1]
        val_as_hex = to_hex(value=r1_value, num_bits=16, debug_comment=comment)
        one_byte = 2
        low_byte = val_as_hex[one_byte:]
        self._memory[target_addr] = low_byte

    #########################
    # Branch & Jump functions #
    #########################

    def _beq_execute(self, r1: int, immediate: int, pc: int):
        r1_value = self._register[r1]
        if r1_value == 0:
            offset = from_twos_complement(immediate) << 1
            target_addr = pc + offset
            return target_addr
        else:
            return pc

    def _get_j_addr(self, instruction: str, comment: str):
        jump_addr = self._get_jump_addr(instruction, comment)
        jump_addr = jump_addr << 1
        return jump_addr

    def _get_jr_addr(self, instruction: str, comment: str):
        rd = self._get_jump_register(instruction, comment)
        rd_value = self._register[rd]
        return rd_value

    @staticmethod
    def _get_r1_r2(instruction, comment):
        try:
            r1 = int(instruction[1], 16)
            r2 = int(instruction[2], 16)
        except ValueError:
            raise SyntaxError(f"Expected hex value for r1 and r2, but got {instruction}\n"
                              f"Instruction: {comment}")
        return r1, r2

    @staticmethod
    def _get_r1_and_immediate(instruction, comment):
        try:
            r1 = int(instruction[1], 16)
            immediate = int(instruction[2:], 16)
        except ValueError:
            raise SyntaxError(f"Expected hex value for r1 and r2, but got {instruction}\n"
                              f"Instruction: {comment}")
        return r1, immediate

    @staticmethod
    def _get_r1_base_offset(instruction, comment):
        try:
            r1 = int(instruction[1], 16)
            base = int(instruction[2], 16)
            offset = int(instruction[3], 16)
        except ValueError:
            raise SyntaxError(f"Expected hex value for r1 and r2, but got {instruction}\n"
                              f"Instruction: {comment}")
        return r1, base, offset

    @staticmethod
    def _get_jump_addr(instruction, comment):
        try:
            jump_addr = int(instruction[1:], 16)
            return jump_addr
        except ValueError:
            raise SyntaxError(f"Expected hex value for r1 and r2, but got {instruction}\n"
                              f"Instruction: {comment}")

    @staticmethod
    def _get_jump_register(instruction, comment):
        try:
            jump_addr = int(instruction[1], 16)
            return jump_addr
        except ValueError:
            raise SyntaxError(f"Expected hex value for r1 and r2, but got {instruction}\n"
                              f"Instruction: {comment}")

    def _get_word_and_parse(self, addr: int, comment: str):
        low_byte = self._memory[addr]
        high_byte = self._memory[addr + 1]
        word = high_byte + low_byte
        try:
            value_at_addr = int(word, 16)
            if value_at_addr > self._MAX_UNSIGNED:
                raise ValueError(f"Expected 16-bit number, got {value_at_addr}\n"
                                 f"Instruction: {comment}")
            return value_at_addr
        except ValueError:
            raise ValueError(f"Expected hex string, but got {word}\n"
                             f"Instruction: {comment}")

    def _get_byte_and_parse(self, addr: int, comment: str):
        byte = self._memory[addr]
        try:
            value_at_addr = int(byte, 16)
            if value_at_addr > self._MAX_BYTE_UNSIGNED:
                raise ValueError(f"Expected 8-bit number, got {value_at_addr}\n"
                                 f"Instruction: {comment}")
            return value_at_addr
        except ValueError:
            raise ValueError(f"Expected hex string, but got {byte}"
                             f"\nInstruction: {comment}")
