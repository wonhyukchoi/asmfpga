main:
	li $sp 65535 -- Initialize stack 
	li $v0 greeting
	jal strOut

	li $v0 input
	jal strOut
	jal intToReg 
	cp $s3 $r0 

	li $v0 input 
	jal strOut
	jal intToReg 
	cp $v0 $r0 
	cp $v1 $s3

	jal multiply 
	cp $s2 $r0 

	li $v0 result
	jal strOut

	cp $v0 $s2
	jal regToInt -- sends multiplication result to IO 
	j main 

-- Returns $r0 = $v0 * $v1.
multiply:
	cp $s0 $v0 -- Save input params
	cp $s1 $v1
	cp $s2 $v1

	slti $s0 0 
	slti $s1 0 

	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $r

	jal absValue1
	cp $v0 $r0
	cp $s2 $v0 -- Save $v0 
	jal absValue2
	cp $v1 $r0
	cp $v0 $s2 -- Revert $v0

	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack pointer

	cp $t0 $s0
	xor $t0 $s1 -- If the sign bits differ, $t0 will become a 1.
	subi $t0 1 -- For branching 
	beq $t0 negMultiply 

	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $ra

	li $r0 16 -- Prescribed settings to use multLoop 
	andi $r1 0
	jal multLoop -- $r1 = multiplicand 

	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack pointer

	cp $r0 $r1 -- Saves result

	jr $ra

-- EXTREMELY awkward subroutine b/c I have no branch & link
-- Takes $v0 and its sign $s0 = 0 if $v0 < 0
absValue1:
	cp $r0 $v0 
	beq $s0 absoluteValue
	jr $ra

absValue2:
	cp $r0 $v1
	cp $v0 $v1
	beq $s1 absoluteValue
	jr $ra

-- Returns $r0 = -$v0.
absoluteValue:
	andi $r0 0 
	sub $r0 $v0 
	jr $ra

-- $r0 = 16, $r1 = 0 must be set beforehand.
-- $r0 keeps track of how many times we loop
-- $r1 = running sum.
-- $v0 the multiplicand, $v1 the multiplier
-- Returns $r1 = $v0 * $v1.
multLoop:
	cp $t1 $v1 
	cp $s1 $v1
	andi $t1 1
	subi $t1 1
	cp $v1 $t1

	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $ra

	jal addRoutine -- $r1 = multiplicand 

	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack point

	cp $v1 $s1

	li $t0 1
	sll $v0 $t0
	srl $v1 $t0

	subi $r0 1
	beq $r0 exit
	j multLoop

-- $v0 = multiplicand
-- $v1 = multiplier & 1 : 0 ? something else 
addRoutine:
	beq $v1 addMultiplicand
	addi $r1 0 -- If mutiplier & 1 = 0, don't add to running sum
	jr $ra

addMultiplicand:
	add $r1 $v0
	jr $ra

negMultiply:
	subi $sp 2 -- Decrement stack pointer 
	sw $ra $sp 0 -- Store $ra

	li $r0 16 -- Prescribed settings to use multLoop 
	andi $r1 0
	jal multLoop -- $r1 = multiplicand 

	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack point

	cp $t0 $r1 -- Saves result 
	andi $r0 0 
	sub $r0 $t0 -- Gets the negative result

	jr $ra


-- GOTO statement for breaking loops
exit:
	jr $ra
	

-- Reads int from input and returns it in $r0.
intToReg:
	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $ra
	li $v0 placeHolder -- placeholder addr to load string
	jal strIn -- #### LOADS STRING ####
	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack pointer

	li $v0 placeHolder -- reload addr of first char
	lb $t0 $v0 0 -- Loads first char of string; check for sign
	subi $t0 45 -- '-' is 45 in ascii
	beq $t0 negIntToReg -- Need separate subroutine for neg numbers 

	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $ra
	andi $r0 0 -- Zero return value 
	jal strToInt -- ### Returns int value in $r0 ###
	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack pointer

	jr $ra

negIntToReg:
	addi $v0 1 -- Integer will actually start after sign bit
	
	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $ra
	andi $r0 0 -- Zero return value 
	jal strToInt -- ### Returns int value in $r0 ###

	cp $t0 $r0 -- Saves the returned integer
	andi $r0 0 
	sub $r0 $t0 -- Make return value negative

	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack pointer
	jr $ra

-- $v0 should point to the first addr of the string
-- Converts the string to an integer and returns in $r0
-- If you don't have an numeric value, this will break!
-- $r0 must be set to 0 before this subroutine.
strToInt:
	cp $s1 $v0 -- Saves char addr
	lb $s2 $s1 0 -- Loads char
	beq $s2 exit -- If null terminator, exit
	
	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $ra

	cp $v0 $r0 -- Copy prev sum into multiplication 
	jal timesTen -- running sum = 10 * prev value + new digit

	subi $s2 48 -- Subtract ascii offset to get int value
	add $r0 $s2 -- + new digit part 

	cp $v0 $s1 -- Reload char addr
	addi $v0 1 -- Increment string addr

	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack pointer

	j strToInt -- Loop until null terminator

-- Returns $r0 = $v0 * 10
timesTen:
	li $t0 1 
	li $t1 3
	cp $r0 $v0 
	sll $r0 $t0 -- $r0 = $r0 << 1
	cp $t0 $v0 
	sll $t0 $t1 -- $t0 = $r0 << 3
	add $r0 $t0 -- $r0 = $r0 << 1 + $r0 << 3
	jr $ra

-- Sends register content of $v0 to IO
-- Converts the signed 16-bit integer to ascii.
regToInt:
	cp $t0 $v0 -- Copy reg value for usage
	slti $t0 0
	beq $t0 negRegToInt -- do neg version

	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $ra

	jal printRegContent

	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack pointer

	jr $ra	

exitJumper:
	j exit

-- FIXME: use array instead of copypasta
printRegContent:
	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $ra

	li $v1 10000 -- To print floor($v0/10000)
	andi $r0 0 -- Needed in order to use returnDividend
	jal returnDividend
	cp $v0 $r0 -- Copies the dividend
	addi $v0 48 -- Adds ascii offset
	jal charOut -- Prints the dividend

	cp $v0 $r1 -- The remainder is now the new divisor
	li $v1 1000 -- To print floor($v0/1000)
	andi $r0 0 -- Needed in order to use returnDividend
	jal returnDividend
	cp $v0 $r0 -- Copies the dividend
	addi $v0 48 -- Adds ascii offset
	jal charOut -- Prints the dividend

	cp $v0 $r1 -- The remainder is now the new divisor
	li $v1 100 -- To print floor($v0/100)
	andi $r0 0 -- Needed in order to use returnDividend
	jal returnDividend
	cp $v0 $r0 -- Copies the dividend
	addi $v0 48 -- Adds ascii offset
	jal charOut -- Prints the dividend

	cp $v0 $r1 -- The remainder is now the new divisor
	li $v1 10 -- To print floor($v0/10)
	andi $r0 0 -- Needed in order to use returnDividend
	jal returnDividend
	cp $v0 $r0 -- Copies the dividend
	addi $v0 48 -- Adds ascii offset
	jal charOut -- Prints the dividend

	cp $v0 $r1 -- The remainder is now the new divisor
	li $v1 1 -- To print floor($v0/1)
	andi $r0 0 -- Needed in order to use returnDividend
	jal returnDividend
	cp $v0 $r0 -- Copies the dividend
	addi $v0 48 -- Adds ascii offset
	jal charOut -- Prints the dividend

	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack pointer

	jr $ra

-- Returns dividend and remainder of $v0/$v1.
-- Dividend: $r0, remainder: $r1
-- To avoid superflous code, you must set $r0 to 0 
-- before calling this subroutine!! 
returnDividend:
	cp $r1 $v0 -- Saves running subtracted value 
	sub $v0 $v1 -- $v0 = $v0 - $v1
	cp $t0 $v0 -- For negativity branching
	addi $t0 255 -- For checking negativity
	slti $t0 255
	beq $t0 exit -- If running dividend < $v1, we are done

	addi $r0 1 -- If $v0>$v1, increment running dividend
	j returnDividend


-- Prints -$v0.
-- Should take in $v0, a registers whose values 
-- should be printed out to stdout.
negRegToInt:
	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $ra 
	subi $sp 2 -- Decrement stack pointer
	sw $v0 $sp 0 -- Store $v0 

	li $v0 45 -- ascii 45 is '-' 
	jal charOut -- #### Print char ####

	lw $v0 $sp 0 -- Reload $v0
	addi $sp 2 -- Increment stack pointer
	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack pointer

	andi $t0 0 -- Zeros register
	sub $t0 $v0 -- Gets negative version of $v0
	
	cp $v0 $t0 -- Copies -$v0 into $v0

	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $ra

	jal printRegContent

	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack pointer

	jr $ra

-- Sends string starting from $v0 until null termination.
-- $v0 should hold the addr of the first char.
strOut:
	cp $s0 $v0 -- Copies register for usage
	lb $t0 $s0 0 -- Reads first byte

	beq $t0 exitJumper -- if we have a null terminator, exit
	cp $v0 $t0 -- Set parameter for charOut

	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $ra
	jal charOut -- #### Print char ####
	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack pointer

	cp $v0 $s0 -- Reset parameter for strOut loop
	addi $v0 1 -- Get next character
	j strOut -- Loop until null terminator

-- Reads string in from REG_IOBUFFER_1 to addr set at $v0.
-- Will read continously until a null terminator is given to REG_IOBUFFER_1. 
strIn:
	subi $sp 2 -- Decrement stack pointer
	sw $ra $sp 0 -- Store $ra
	jal charIn -- #### Reads in the first char ####
	lw $ra $sp 0 -- Reload $ra
	addi $sp 2 -- Increment stack pointer 

	sb $r0 $v0 0 -- Stores input char into addr
	beq $r0 exitJumper -- If we got a null terminator, exit

	addi $v0 1 -- Increment byte address for storing char
	j strIn -- Loop until null terminator 

-- Sends char in $v0 into first memory of REG_IOBUFFER_1.
charOut:
	li $t0 REG_IOCONTROL -- Gets addr of directive
	lw $t2 $t0 0 -- Gets memory addr of REG_IOCONTROL
	lw $t2 $t2 0 -- Gets contents of REG_IOCONTROL

	li $t1 2 -- To test for bit 1 of REG_IOCONTROL
	and $t1 $t2 -- If first bit is set, $t0 should remain 2
	beq $t1 charOut -- If not ready, check again

	li $t0 REG_IOBUFFER_1 -- Gets addr of directive
	lw $t0 $t0 0 -- Gets memory addr of REG_IOBUFFER_1
	sb $v0 $t0 0 -- Sends char to IOBuffer

	jr $ra

-- Reads first char in from REG_IOBUFFER_1 to $r0. 
charIn:
	li $t0 REG_IOCONTROL -- Gets addr of directive
	lw $t2 $t0 0 -- Gets memory addr of REG_IOCONTROL
	lw $t2 $t2 0 -- Gets contents of REG_IOCONTROL

	li $t1 1 -- To test for bit 0 of REG_IOCONTROL
	and $t1 $t2 -- If first bit is set, $t0 should remain 1
	beq $t1 charIn -- If not ready, check again

	li $t0 REG_IOBUFFER_1 -- Gets addr of directive
	lw $t0 $t0 0 -- Gets memory addr of <REG_IOBUFFER_1>
	lb $r0 $t0 0 -- Stores contents of REG_IOBUFFER_1

	jr $ra
REG_IOCONTROL: .word 0xff00
REG_IOBUFFER_1: .word 0xff04
greeting: .asciiz "\r\nLoading integer multiplier...\n"
input: .asciiz "Please enter a number:"
result: .asciiz "Product is:"
firstMem: .word 0x3333
secondMem: .word 0x8888
placeHolder: .word 0xcccc