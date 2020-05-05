	.arch	armv7
	.cpu	cortex-a53
	.fpu	neon-fp-armv8
	.global	main
	.text

@@@ Columnar Transposition implementation
@@@ CSCI-6616 Assembly Language
@@@ Krikor Herlopian/Rick Aliwalas

@ argc is the number of arguments passed (int)
@
@       int main(int argc, char *argv[])
@
@ R0 will contain the argc + 1 for the program name
@ i.e., "progname encrypt keyval" yields R0=3

main:
	mov	R3, R0		@ R3 <- R0
	str	R0, [SP,#-4]	@ store contents of R0 (#args+1) into byte
				@ address stored in [SP-4 bytes]

	str	R1, [SP,#-8]	@ store contents of R1 (arg1) into byte
				@ address stored in [SP - 8 bytes]

	cmp	R3, #3		@ is #args + 1 equal to 3?
				@ if not, write msg to user and exit

	bne	endProgram	@ if more or less arguments than 2 args passed,
				@ exit program

@ arg1 should be "encrypt" or "decrypt" (case insensitive)

checkEncrypt:	@ in loopEncrypt, checkEncryptCaseInsensitive, updateLoopEncrypt,
		@ we loop over each char in arg1, check if "e" then "n",...

	ldr 	R3, [SP,#-8]	@ load R3 with value located in byte address
				@ contained in [SP,#-8] (i.e. arg1)
	add	R3, R3, #4	@ change R3 to addr of next char in arg1
	ldr	R5, =encryptStr	@ load addr of word "encrypt" into R5
	ldr	R3, [R3]	@ load R3 with value in byte address in R3
	mov	R4, #0		@ initialize R4 (loop index)


@ we want to loop over every character, and check if its e than n
@ than c ...until we confirm encrypt  was typed

loopEncrypt: 
	@ note ldrb loads a byte into the lower 8 bits of the destination
	@ register padding the upper 24 bits to zeros

	ldrb	R6, [R3,R4]	@ load R6 with value at address R3+R4 bytes
				@ i.e., char in arg1 (ideally "encrypt")

	ldrb	R7, [R5,R4]	@ load R7 with the value at address stored
				@ in R5 offset by R4 bytes (this is the char
				@ in the string "encrypt" for comparison

	cmp	R6, R7		@ check if they are equal, if not check
				@ uppercase case.
	bne	checkEncryptCaseInsensitive
	b	updateLoopEncrypt

	@ check for lowercase, in case we confirm its not encrypt,
	@ call checkdecrypt to check if its decrypt.

checkEncryptCaseInsensitive:	@ check for lowercase ENCRYPT.
	add	R6, R6, #32	@ offset the char in arg1 (R6) by 32 bytes
				@ i.e., change "E" to "e" for ex
	cmp	R6, R7		@ compare, if equal, goto updateLoopEncrypt 
				@ otherwise, chk if user entered "decrypt"
	bne	checkDecrypt
	b	updateLoopEncrypt

	@ update loop index to move to compare second letter

updateLoopEncrypt:
	add	R4, R4,#1	@ increment index R4
	cmp	R4, #7		@ compare if reached 7 (encrypt is 7
				@ letters). If yes, check last element
				@ otherwise goto loopEncrypt
	beq	checkLastElementEncrypt
	b	loopEncrypt

	@ check if 1st arg is "decrypt", if confirmed it is not "encrypt"

checkDecrypt:			@ check if "decrypt" (case-insentive) passed
	ldr	R3, [SP,#-8]	@ load R3 with value in byte addrress [
				@ [SP-8 bytes] - back to start of string
	add	R3, R3, #4	@ change R3 to addr of next char in arg1
	ldr	R5, =decryptStr	@ load word decrypt for comparison
	ldr	R3, [R3]	@ load R3 with value in byte address in R3
	mov	R4, #0		@ initialize R4 (loop index)

	@ loop over every character, and check if its d than e
	@ than c ...until we confirm "decrypt" was typed

loopDecrypt:
	ldrb	R6, [R3,R4]	@ load R6 with value at address R3+R4 bytes
				@ i.e., char at index R4 of arg1
	ldrb	R7, [R5,R4]	@ load letter at index R4 of string "decrypt"
	cmp	R6, R7		@ check if equal, if not check for upper case
	bne	checkDecryptCaseInsensitive
	b	updateLoopDecrypt

	@ check for lowercase letter as well. D or d. If we get to confirm
	@ its not decrypt , end program.

checkDecryptCaseInsensitive:
	add	R6, R6,#32	@ add 32, lowercase the character.
	cmp	R6, R7		@ check if equal, if not end program since
				@ neither encrypt or decrypt was 1st arg
	bne	endProgram	@ arg1 is neither "encrypt" nor "decrypt"
	b	updateLoopDecrypt

	@ update loop index to move to compare second letter

updateLoopDecrypt:
	add	R4, R4,#1	@ update index R4
	cmp	R4, #7		@ in case we reached end of word decrypt(7),
				@ check last element.
	beq	checkLastElementDecrypt
	b	loopDecrypt

	@ check if last element is 0. So that we confirm "encrypt" was
	@ typed without additional letters. For example, "encrypt1" will end
	@ program. Since last element will fail.

checkLastElementEncrypt:
	ldrb	R6, [R3,R4]	@ load last char
	cmp	R6, #0		@ if 0 goto goToEncrypt, if not it means user
				@ typed "encrypt1" for example (program ends
				@ in this case)
	beq	goToEncrypt
	b	endProgram

	@ we check if last element is 0 (null terminator) so that we confirm
	@ "decrypt" was typed without any more letters. "decrypt1" will end
	@ program. Since last element will fail.

checkLastElementDecrypt:
	ldrb	R6, [R3,R4]	@ load last letter
	cmp	R6, #0		@ if 0 gotodecrypt, if not it means user typed
				@ decrypt1 for example (program ends)
	beq	goToDecrypt
	b	endProgram

goToDecrypt:
	mov	R10, #1		@ R10=1 indicates decrypting
	b	loadKey

	@ we store 0 in R10,so we know in future we are encrypting.
goToEncrypt:
	mov	R10, #0		@ R10=0 indicates encrypting
	b	loadKey

	@ get key (arg2) and check length.
	@ It is in R3 now.

	@ lets get the key (2nd arg from command line), and call to check
	@ for its length. It is in R3 now.

loadKey:
	mov	R4, #0		@ initialize index
	ldr	R3, [SP,#-8]	@ load R3 with the contents at addr [SP,#-8]
				@ points to start of 3 arguments
	add	R3, R3, #8	@ add 8 to R3 to get to the key
	ldr	R3, [R3]	@ load key into R3
	b	getKeyLen

	@ We get key length here. At end, the key length will be in R4
	@ and the key will be in R3. Any character (including spaces) are
	@ acceptable for the key.

getKeyLen:
	ldrb	R6, [R3,R4]	@ load letter at index R4 of key (2nd
				@ command line argument).
	cmp	R6,#0		@ compare its not end
	beq	inputUser	@ if you reached end of key, go to input User
	sub	R8, R6, #'A'	@ subtract -65 from letter at index R4 of .
	cmp	R8, #25	@ check against 25
	bgt	checkIfSmallKeyLetter	@ if greater than, check for small case
					@ scenario
	cmp	R8, #0		@ compare against 0
				@ error should be  letters between A-Z @ less
				@ than 0, end program. Should be a-z or A-Z.
	blt	endProgram
	add	R4, R4, #1	@ update index R4, at the end R4 will be key
				@ length when loop over.
	b	getKeyLen

	@ We check if key typed in lowercase letter, we move it to uppercase
	@ letter. If the char is not A-Z or a-z, we continue but in our
	@ encryption/decryption we keep that character as it is.
	@ The key will be stored in R6.

checkIfSmallKeyLetter:
	sub	R8, R8, #32	@ subtract 32 from letter
	cmp 	R8, #25		@ compare to 25
	bgt 	asIs 		@ >25 means char is not A-Z/a-z
	cmp 	R8, #0		@ compare to 0
	blt 	asIs		@ not A-Z/a-z
	@ convert to uppercase to ease encryption/decryption:
	sub 	R6, R6, #32 
	strb 	R6, [R3,R4]
	add 	R4, R4,#1	@ update index, R4 will be key length at end
	b	getKeyLen

@ keep key as is, since its neither small or uppercase letter between A-Z/a-z
asIs:
	add 	R4, R4 ,#1	@ update index, R4 will be key length at end
	b	getKeyLen	

	@ We will read input of plain or ciphered text. We store it in R3.
	@ We want to write result to stack.We are allocating on stack space of
	@ 4 * key length * key length for inbuff and outbuff

inputUser:
	mul	R11, R4, R4
	mov	R9, #4
	mul	R11, R11, R9	@ allocating space key*key*4  (64b if key=4)
	sub	SP, SP, R11
	mov	R9, #0		@ key index

readInput:
	mul	R11, R4, R4
	mov	R12, #2
	mul	R11, R11, R12	@ 32b (if key=4)
	add     R11, SP, R11	@ where to start writing from
	mov	R0, #0
	mov	R6, R3
	mov	R1, R11
	mul	R11,R4,R4
	mov	R12, #2 	
	mul	R11,R11,R12 @ read first 32b
	mov	R2, R11		@ we will be reading 32 characters if key
				@ is (4*4*2=16)
	bl	read
	mov	R3, R1
	mov	R1, R0		@ moving length of plain/ciphered text to R1
	mov	R0, R6		@ moving key to R0
	mov	R6, #0
	mov	R2, R10		@ moving whether its encrypt(0) or decrypt(1) to R2
	mov	R5, R0
	mov	R6, R1
	mov	R7, R2
	mov	R8, R3
	mov	R11, R4

@ R0 is the key
@ R1 is the length of the plain/ciphered text
@ R4 is key length
@ R3 is plain/ciphered text
@ R2 to tell whether to do encrypt(0) or decrypt(1)
	mov	R5, #0
	mov	R6, #0
	mov	R7, #0
	mov	R9, #0
	mov	R10, #0
	mov	R11, #0
	mov	R12, #0
	mov	R8, #0
	mov	R7, R1
	push	{R6,R7,R10,R11}
	bl	transposition	
	b	printFinal

printFinal: 
	mov	R9, #0
	mov	R10, R0		@ moving result to R10
	mov	R0, #1
	mov	R2, R7		@ moving length to print into R2.
	mov	R1, R10		@ moving result to R1
	sub	R7, R2, #1
	ldrb	R7, [R3,R7]
	cmp	R7, #10
	beq	removeLast
	cmp	R7, #0
	beq	removeLast
	mov	R7, R2
	mov	R10, #0
	bl	write
	mov	R0, #0
	mov	R7, #1
	mov	R3, #0
	b	endProgram
	
removeLast:
	sub	R2, R2, #1	
	mov	R10, #0
	bl	write
	mov	R0, #0
	mov	R7, #1
	mov	R3, #0

endProgram:
	mov	R0, #0
	mov	R7, #1
	swi	0

@ function called to do transposition based on key.
transposition:
	mul	R11, R4, R4
	mov	R7, #4
	mul	R11, R11, R7
	add	R11, SP, R11	@ where we want to write from result
	mul	R7, R4, R4
	add	R11, R11, R7
	mov	R7, #0
	mov	R8, #0
	mov	R9, #0
	mov	R6, #0
	cmp	R7, R4
	mov	R10, #0
	blt	compare2

compare10:
	mov	R7, #0
	ldrb	R10, [R0,R5]
	add	R10, #100
	strb	R10, [R0,R5]	@ update key we just used by adding 00, to
				@ find next lowest key easily.
	mov	R8, #0
	add	R6, R6,#1
	mov	R5, #0
	cmp	R6, R4		@ we want to loop as much as key length
	blt	compare2
	mul	R11, R4, R4
	mov	R7, #4
	mul	R11, R11, R7
	add	R11, SP, R11
	mul	R7, R4, R4
	add	R11, R11, R7	@ where we want to print from on stack.
	mov	R7, #0
	mov	R5,R0
	mov	R0, R11
	
	pop	{R6,R7,R10,R11}
	mov	pc, lr

@ We loop based on key length. If key length 6, we will loop 6 times to
@ determine lowest column 6 times. In case a column determined to be lowest,
@ in compare10 we update that column key by adding 100 so we determine next
@ lowest easier. Lowest column key to be in R8.
@ Once we determined lowest column , we go to setup9.

compare1:
	add	R7, #1
	cmp	R7, R4
	blt	compare2
	b	setUP9

compare2:
	ldrb	R10, [R0,R8]	@ load current lowest column key letter
	ldrb	R12, [R0,R7]	@ load key letter at index R7.
	cmp	R12, R10	@ compare columns
	blt	add1		@ if lower update current lowest column index
	cmp	R10,R12
	beq	cgeck 
	b	compare1
cgeck:
	cmp	R7, R8
	blt	add1
	b	compare1
	
@ in case new column determined to be lowest move R7 to R8 and R5.
add1:
	mov	R8, R7
	mov	R5, R8
	b	compare1

@ R8 which column.
setUP9:
	mov	R10, #0
	cmp	R2, #0
	beq	setEncryption
	b 	setDecryption
	
@ We want to loop, and add to our result. So assuming column 4 determined to be lowest, 
@ we add column 4 results into r11. We go over the column by adding key length.
@ So first R8 is 3 ( column 4), next loop we want text at index 9 ( if key length is 6), next loop 
@ we want letter at index 15..so on. 
setEncryption:
	cmp	R8, R1
	bge	compare10
	@ in case new line is last letter, i am handling scenario where
	@ new line is added in middle of result.
	add	R12, R8, #1
	cmp	R12, R1
	beq	checkNewLine
	ldrb	R12, [R3,R8]
	strb	R12, [R11],#1
	add	R8, R4
	cmp	R8, R1
	blt	setEncryption
	b	compare10

@ in case new line is last letter, i am handling scenario where new line is
@ added in middle of result.

checkNewLine:
	ldrb	R12, [R3,R8]
	cmp	R12, #10
	beq	compare10
	cmp	R12, #0
	beq	compare10
	ldrb	R12, [R3,R8]
	strb	R12, [R11],#1
	add	R8, R4
	cmp	R8, R1
	blt	setEncryption
	b	compare10
		
@ We want to loop, and add to our result. So assuming column 4 determined
@ to be lowest, we add column first key letter into column 4.
@ For example in case key length is 6.
@ We add first letter ldrb R12, [R3,#0] to strb R12, [R11,#3]
@ We loop and  add second letter ldrb R12, [R3,#1] to strb R12, [R11,#9].

setDecryption:
	cmp	R8, R1
	bge	compare10
	@ in case new line is last letter, i am handling scenario where new
	@ line is added in middle of result.
	add	R12, R8, #1
	cmp	R12, R1
	beq	checkNewLine1
	@mul	R12, R6, R9
	@add	R12, R12, R9
	ldrb	R12, [R3,R9]
	strb	R12, [R11,R8]
	add	R9, R9, #1
	add	R8, R4
	cmp	R8, R1
	blt	setDecryption
	b	compare10

@ in case new line is last letter, i am handling scenario where new line is added in middle of result.
checkNewLine1:
	mul	R12, R6, R4
	add	R12, R12, R9
	ldrb	R12, [R3,R12]
	cmp	R12, #10
	beq	compare10
	cmp	R12, #0
	beq	compare10
	ldrb	R12, [R3,R12]
	strb	R12, [R11,R8]
	add	R8, R4
	cmp	R8, R1
	blt	setDecryption
	b	compare10	

.data
	encryptStr: .ascii "encrypt"
		.equ encryptStrlen, (.-encryptStr)

	decryptStr: .ascii "decrypt"
		.equ decryptStrlen, (.-decryptStr)

