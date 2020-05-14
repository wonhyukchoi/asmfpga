

class Codes:
    def __init__(self):
        self._opname_encoded = {
            'add': 0b0000,
            'sub': 0b0000,
            'slt': 0b0000,
            'cp': 0b0000,
            'and': 0b0000,
            'or': 0b0000,
            'xor': 0b0000,
            'nor': 0b0000,
            'sll': 0b0000,
            'srl': 0b0000,
            'sra': 0b0000,
            'mult': 0b0000,
            'multload': 0b0000,
            'addi': 0b0001,
            'subi': 0b0010,
            'slti': 0b0011,
            'lui': 0b0100,
            'andi': 0b0101,
            'ori': 0b0110,
            'xori': 0b0111,
            'lb': 0b1000,
            'lw': 0b1001,
            'sb': 0b1010,
            'sw': 0b1011,
            'beq': 0b1100,
            'j': 0b1101,
            'jal': 0b1110,
            'jr': 0b1111,
            'li': None
        }

        self._funct_encoded = {
            'add': 0b0000,
            'sub': 0b0001,
            'slt': 0b0010,
            'cp': 0b0011,
            'and': 0b0100,
            'or': 0b0101,
            'xor': 0b0110,
            'nor': 0b0111,
            'sll': 0b1000,
            'srl': 0b1001,
            'sra': 0b1010,
            'mult': 0b1011,
            'multload': 0b1100,
        }

        self._reg_encoded = {
            '$0': 0,
            '$r0': 1,
            '$r1': 2,
            '$v0': 3,
            '$v1': 4,
            '$t0': 5,
            '$t1': 6,
            '$t2': 7,
            '$t3': 8,
            '$s0': 9,
            '$s1': 10,
            '$s2': 11,
            '$s3': 12,
            '$sp': 13,
            '$ra': 14,
            '$at': 15
        }

        self._opname_decoded = {value: key for key, value in self._opname_encoded.items()}
        self._funct_decoded = {value: key for key, value in self._funct_encoded.items()}
        self._reg_decoded = {value: key for key, value in self._reg_encoded.items()}

        self._alu = ('add', 'sub', 'slt', 'cp', 'and', 'or', 'xor', 'nor',
                     'sll', 'srl', 'sra', 'mult', 'multload', 'subs')
        self._alui = ('addi', 'subi', 'slti', 'lui', 'andi', 'ori', 'xori')
        self._mem = ('lb', 'lw', 'sb', 'sw')
        self._branch = ('beq',)
        self._jump = ('j', 'jal', 'jr')
        self._pseudo = ('li',)

        self._four_operands = ('mem',)
        self._three_operands = ('alu', 'alui', 'branch', 'pseudo')
        self._two_operands = ('jump',)

    def get_regcode(self, regname: str):
        try:
            return self._reg_encoded[regname]
        except KeyError:
            raise SyntaxError(f"{regname} is a not a proper register name")


class CodeEncoder(Codes):
    def __init__(self):
        super().__init__()

    def get_optype(self, opname):
        if opname in self._alu:
            return 'alu'
        elif opname in self._alui:
            return 'alui'
        elif opname in self._mem:
            return 'mem'
        elif opname in self._branch:
            return 'branch'
        elif opname in self._jump:
            return 'jump'
        elif opname in self._pseudo:
            return 'pseudo'
        else:
            raise SyntaxError(f"{opname} is not a proper opname")

    def get_funct_code(self, opname):
        try:
            return self._funct_encoded[opname]
        except KeyError:
            raise SyntaxError(f"{opname} is not a proper alu type instruction.\n"
                              "This error shouldn't have happened anyways, how are you here?")

    def get_opcode(self, opname):
        try:
            return self._opname_encoded[opname]
        except KeyError:
            raise SyntaxError(f"{opname} is not a proper opname.\n"
                              "This error shouldn't have happened anyways, how are you here?")

    def get_num_operands(self, optype):
        if optype in self._four_operands:
            return 4
        elif optype in self._three_operands:
            return 3
        elif optype in self._two_operands:
            return 2
        else:
            raise SyntaxError(f"{optype} is not a proper op type.\n"
                              "This error shouldn't have happened anyways, how are you here?")


class CodeDecoder(Codes):
    def __init__(self):
        super().__init__()
        self._jump_branch = self._branch + self._jump
        self._reg_mem = self._alu + self._alui + self._mem

    def get_op_exec_type(self, instruction: str):
        opname = self.get_opname(instruction)
        if opname in self._reg_mem:
            return 'reg_mem'
        elif opname in self._jump_branch:
            return 'jump_branch'
        else:
            raise SyntaxError(f"Unexpected opcode in {instruction}")

    def get_opname(self, instruction: str):
        opcode_hex = instruction[0]
        opcode = int(opcode_hex, 16)
        return self._opname_decoded[opcode]

    def get_optype(self, instruction: str):
        opcode_hex = instruction[0]
        opcode = int(opcode_hex, 16)
        opname = self._opname_decoded[opcode]
        optype = self.opname_to_optype(opname)
        return optype

    def opname_to_optype(self, opname: str):
        if opname in self._alu:
            return 'alu'
        elif opname in self._alui:
            return 'alui'
        elif opname in self._mem:
            return 'mem'
        elif opname in self._branch:
            return 'branch'
        elif opname in self._jump:
            return 'jump'
        elif opname in self._pseudo:
            return 'pseudo'
        else:
            raise SyntaxError(f"{opname} is not a proper opname")

    def get_funct_code(self, instruction: str):
        funct_code_hex = instruction[-1]
        funct_code = int(funct_code_hex, 16)
        funct_name = self._funct_decoded[funct_code]
        return funct_name

    def get_reg_decoded(self, reg_int: int):
        return self._reg_decoded[reg_int]