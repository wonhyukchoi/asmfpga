import sys

MAX_INT = (2 ** 15) - 1


# FIXME: The fact that Python's ints are objects are killing me.
def to_hex(value: int, num_bits=4, debug_instruction=None, debug_comment=''):
    """
    Returns the hex, two's complement value of an integer
    signed extended to the appropriate number of bits.
    :param debug_comment: for debugging purposes
    :param debug_instruction: for debugging purposes
    :param value: integer to be converted
    :param num_bits: num of bits to sign extend
    :return: hex as string
    """
    if type(value) != int:
        if debug_instruction:
            debug_comment = debug_instruction.content
        raise SyntaxError(f"Expected int, got {value}\n"
                          f"Instruction: {debug_comment}")

    # To sign extend a positive integer, just zero extend it
    if 0 <= value < (2 ** (num_bits-1)) - 1:
        return zero_extend(value=value, num_bits=num_bits,
                           debug_instruction=debug_instruction, debug_comment=debug_comment)

    if (num_bits % 4) != 0:
        raise ValueError(f"Expected num_bits to be a power of 4, but got {num_bits}")
    hex_str = hex(value & ((1 << num_bits) - 1))  # Convert to two's complement
    hex_str = hex_str[2:]  # To strip '0x'

    return hex_str


def zero_extend(value: int, num_bits: int, debug_instruction=None, debug_comment=''):
    if (num_bits % 4) != 0:
        raise ValueError(f"Expected num_bits to be a power of 4, but got {num_bits}")
    bit_len = value.bit_length()
    if num_bits < bit_len:
        if debug_instruction:
            debug_comment = debug_instruction.content
        raise ValueError(f"Expected {num_bits} bit int, got {value}\n"
                         f"Instruction: {debug_comment}")
    num_hex_digits = num_bits // 4
    hex_str = hex(value)[2:]  # Need [2:] to strip '0x'
    return hex_str.rjust(num_hex_digits, '0')


def from_twos_complement(value, num_bits=8):
    max_val = (1 << num_bits - 1) - 1
    all_f = (1 << num_bits) - 1
    if value <= max_val:
        return value
    else:
        ones_complement = value ^ all_f
        complement = ones_complement + 1
        return -complement


def to_twos_complement(value, num_bits=8):
    if value >= 0:
        return value
    else:
        all_f = (1 << num_bits) - 1
        value_inv = - value
        ones_complement = value_inv ^ all_f
        return ones_complement + 1


def print_as_bin(machine_code: str):
    """
    Prints 4-digit hex instructions in their binary form.
    Used for debugging purposes.
    :param machine_code: String, something like '43ff'
    :return: None, but prints the binary forms of the instruction
    """
    assert len(machine_code) == 4, "Instructions should be 4 hex digits"

    print(machine_code, end=' : ')

    for hex_char in machine_code:
        bin_str = bin(int(hex_char, 16))[2:]
        bin_str = bin_str.rjust(4, '0')
        print(bin_str, end=' ')
    print()


def arg_parse(file_extension='', enforce_second=False):
    """
    Helper function to parse in arguments.
    :param file_extension: .asm or .mif
    :param enforce_second: to enforce second argument
    :return: input_file, debug_mode
    """
    arg_len = len(sys.argv) - 1
    input_file, second_arg = '', ''
    if arg_len > 2 or arg_len <= 0:
        raise IOError(f"Expected one or two arguments, "
                      f"but got {arg_len}\n"
                      f"Your arguments:"
                      f"{sys.argv[1:]}")
    else:
        input_file = sys.argv[1]

        if not input_file.endswith(file_extension):
            raise IOError(f"Expected file extension "
                          f"{file_extension}, "
                          f"but got {input_file}")

        if enforce_second:
            if arg_len != 2:
                raise IOError(f"Expected two arguments, "
                              f"but got {arg_len}\n"
                              f"Your arguments:"
                              f"{sys.argv[1:]}")

        if arg_len == 2:
            second_arg = sys.argv[2]

    return input_file, second_arg
