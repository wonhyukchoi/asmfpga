from codes import CodeEncoder


class BaseInstruction:
    def __init__(self):
        self.__addr = 0
        self.__content = None
        self.__instruct_type = None
        self.__comment = None

    @property
    def addr(self):
        return self.__addr

    @addr.setter
    def addr(self, value: str):
        self.__addr = value

    @property
    def content(self):
        return self.__content

    @content.setter
    def content(self, value):
        self.__content = value

    @property
    def instruct_type(self):
        return self.__instruct_type

    @instruct_type.setter
    def instruct_type(self, value):
        self.__instruct_type = value

    @property
    def comment(self):
        return self.__comment

    @comment.setter
    def comment(self, comment: str):
        self.__comment = comment


class Instruction(BaseInstruction):
    def __init__(self, raw_instruction: str):
        super().__init__()
        self.__addr = 0
        self.content = raw_instruction
        self.__opname = None
        self.__optype = None
        self.__opcode = None
        self.__funct_code = None
        self.__rd = None
        self.__rs = None
        self.__immediate = 0
        self.__mem_offset = 0
        self.__branch_addr = 0
        self.__jump_addr = None
        self.__comment = None
        self.__codes = CodeEncoder()
        self.instruct_type = 'instruction'
        self.__parse_instruction()

    def __parse_instruction(self):
        # Parse comment
        if '--' in self.content:
            where_comment = self.content.find('--')
            self.comment = self.content[where_comment:]
            self.content = self.content[:where_comment]

        # Split operands
        instruct_fields = tuple(operand.strip() for operand in self.content.split())

        # Save opname, opcode, and optype
        opname = instruct_fields[0]
        opcode = self.__codes.get_opcode(opname)
        optype = self.__codes.get_optype(opname)
        self.opname = opname
        self.opcode = opcode
        self.optype = optype

        # Correct number of operands checking
        num_operands = self.__codes.get_num_operands(optype=self.optype)
        if len(instruct_fields) is not num_operands:
            raise SyntaxError(f"Expected {num_operands} operands, got {len(instruct_fields)}.\n"
                              f"Instruction: {self.content}")

        if optype == 'alu':
            self.funct_code = self.__codes.get_funct_code(opname)

            # The if statements may not activiate if we have directives.
            self.rd = instruct_fields[1]
            self.rs = instruct_fields[2]
            if self.rd.startswith('$'):
                self.rd = self.__codes.get_regcode(self.rd)
            if self.rs.startswith('$'):
                self.rs = self.__codes.get_regcode(self.rs)

        elif optype == 'alui':
            self.rd = instruct_fields[1]
            self.immediate = instruct_fields[2]
            # The if statement may not activiate if we have directives.
            if self.rd.startswith('$'):
                self.rd = self.__codes.get_regcode(self.rd)

        elif optype == 'mem':
            # The if statements may not activiate if we have directives.
            self.rd = instruct_fields[1]
            self.rs = instruct_fields[2]
            if self.rd.startswith('$'):
                self.rd = self.__codes.get_regcode(self.rd)
            if self.rs.startswith('$'):
                self.rs = self.__codes.get_regcode(self.rs)

            self.mem_offset = instruct_fields[3]

        elif optype == 'branch':
            self.rd = instruct_fields[1]
            # The if statement may not activiate if we have directives.
            if self.rd.startswith('$'):
                self.rd = self.__codes.get_regcode(self.rd)

            self.branch_addr = instruct_fields[2]

        elif optype == 'jump':
            self.jump_addr = instruct_fields[1]

            # If we have a jr instruction
            if self.jump_addr.startswith('$'):
                if self.opname != 'jr':
                    raise SyntaxError(f"Expected {'jr'} opname when using jump address {self.jump_addr}\n"
                                      f"Instruction: {self.content}")
                else:
                    self.jump_addr = self.__codes.get_regcode(self.jump_addr)

        elif optype == 'pseudo':
            self.rd = instruct_fields[1]
            self.immediate = instruct_fields[2]
            # The if statement may not activiate if we have directives.
            if self.rd.startswith('$'):
                self.rd = self.__codes.get_regcode(self.rd)

    @property
    def opname(self):
        return self.__opname

    @opname.setter
    def opname(self, value):
        self.__opname = value

    @property
    def optype(self):
        return self.__optype

    @optype.setter
    def optype(self, value):
        self.__optype = value

    @property
    def opcode(self):
        return self.__opcode

    @opcode.setter
    def opcode(self, opcode: int):
        self.__opcode = opcode

    @property
    def funct_code(self):
        return self.__funct_code

    @funct_code.setter
    def funct_code(self, funct_code: int):
        self.__funct_code = funct_code

    @property
    def rd(self):
        return self.__rd

    @rd.setter
    def rd(self, rd: int):
        self.__rd = rd

    @property
    def rs(self):
        return self.__rs

    @rs.setter
    def rs(self, rs: int):
        self.__rs = rs

    @property
    def immediate(self):
        return self.__immediate

    @immediate.setter
    def immediate(self, immediate: int):
        self.__immediate = immediate

    @property
    def mem_offset(self):
        return self.__mem_offset

    @mem_offset.setter
    def mem_offset(self, value):
        self.__mem_offset = value

    @property
    def branch_addr(self):
        return self.__branch_addr

    @branch_addr.setter
    def branch_addr(self, value):
        self.__branch_addr = value

    @property
    def jump_addr(self):
        return self.__jump_addr

    @jump_addr.setter
    def jump_addr(self, value):
        self.__jump_addr = value


class Directive(BaseInstruction):
    def __init__(self, raw_instruction: str):
        super().__init__()
        self._ASCII_OFFSET = 0x30
        self.instruct_type = 'directive'
        self.content = raw_instruction
        self._label = None
        self._type = None
        self._value = None
        self._parse_comment()
        self._parse_directive()

    def _parse_comment(self):
        if '--' in self.content:
            where_comment = self.content.find('--')
            self.comment = self.content[where_comment:]
            self.content = self.content[:where_comment]

    def _parse_directive(self):
        instruct_fields = tuple(operand.strip() for operand in self.content.split())

        # Hack
        if instruct_fields[1] == '.asciiz':
            if not (instruct_fields[2].startswith('"') and instruct_fields[-1].endswith('"')):
                raise SyntaxError("Expected string with quotations, got {}".format(self.content))
            instruct_fields = [instruct_fields[0], instruct_fields[1],
                               " ".join(instruct_fields[2:])]
            instruct_fields[2] = instruct_fields[2][1:-1]  # Removes " from both sides

        if len(instruct_fields) != 3:
            raise SyntaxError(f"Expected 3 operands, got {len(instruct_fields)}\n"
                              f"Instruction: {self.content}")

        self.label, self.type, self.value = instruct_fields

        if not self.label.endswith(':'):
            raise SyntaxError(f"Expected : operator for directive.\n"
                              f"Got instruction: {self.content}")
        else:
            self.label = self.label[:-1]  # Removes ':'

        if not self.type.startswith('.'):
            raise SyntaxError(f"Expected directive types to start with a period.\n"
                              f"Got instruction: {self.content}")

        if self.type in ('.word', '.byte'):
            try:
                self.value = int(self.value, 16)
            except ValueError:
                raise SyntaxError(f"Expected hexadecimal, but got {self.value}\n"
                                  f"Instruction: {self.content}")

        elif self.type == '.asciiz':
            for char in self.value:
                if not char.isascii():
                    raise SyntaxError(f"Expected ascii value, got {self.value}\n"
                                      f"Instruction: {self.content}")
        else:
            raise SyntaxError(f"Expected .byte, .word, or .asciiz, but got {self.type}\n"
                              f"Instruction: {self.content}")

    @property
    def label(self):
        return self._label

    @label.setter
    def label(self, value):
        self._label = value

    @property
    def type(self):
        return self._type

    @type.setter
    def type(self, value):
        self._type = value

    @property
    def value(self):
        return self._value

    @value.setter
    def value(self, value):
        self._value = value


class Comment(BaseInstruction):
    def __init__(self):
        super().__init__()
        self.instruct_type = 'comment'
