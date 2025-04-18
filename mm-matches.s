@ This ARM Assembler code should implement a matching function, for use in the MasterMind program, as
@ described in the CW2 specification. It should produce as output 2 numbers, the first for the
@ exact matches (peg of right colour and in right position) and approximate matches (peg of right
@ color but not in right position). Make sure to count each peg just once!
	
@ Example (first sequence is secret, second sequence is guess):
@ 1 2 1
@ 3 1 3 ==> 0 1
@ You can return the result as a pointer to two numbers, or two values
@ encoded within one number
@
@ -----------------------------------------------------------------------------

.text
@ this is the matching fct that should be called from the C part of the CW	
.global matches
@ use the name main here, for standalone testing of the assembler code
@ when integrating this code into master-mind.c, choose a different name
@ otw there will be a clash with the main function in the C code
.global main_matches
main_matches: 
	LDR  R2, =secret	@ pointer to secret sequence
	LDR  R3, =guess		@ pointer to guess sequence

	@ you probably need to initialise more values here

	@ ... COMPLETE THE CODE BY ADDING YOUR CODE HERE, you should use sub-routines to structure your code

exit:	@MOV	 R0, R4		@ load result to output register
	MOV 	 R7, #1		@ load system call code
	SWI 	 0		@ return this value
  
@ -----------------------------------------------------------------------------
@ sub-routines

@ this is the matching fct that should be callable from C	
matches:
    STR FP, [SP, #-4]!    @ saving frame pointer(FP) and adjusting stack pointer(SP)
    ADD FP, SP, #0        @ setting up the FP (pointer to base address of functions stack frame)
    SUB SP, SP, #28       @ allocating space on the stack for local variables
    
    STR R0, [FP, #-24]    @ storing the pointer to first sequence in stack
    STR R1, [FP, #-28]    @ storing the pointer to second sequence in stack
    
    MOV R3, #0            @ initializing counters for exact matches, approximate matches, and loop
    STR R3, [FP, #-8]     @ storing exact matches counter
    MOV R3, #0
    STR R3, [FP, #-12]    @ storing approximate matches counter
    MOV R3, #0
    STR R3, [FP, #-16]    @ storing loop counter
    
    B   mainLoop          @ jump to the start of the main loop

exactMatchCheck:         @ loop for checking the exact matches 
    LDR R3, [FP, #-16]   @ loading loop counter
    LSL R3, R3, #2       @ calculating the offset for accessing elements in the sequences
    LDR R2, [FP, #-24]   @ loading pointer to the first sequence
    ADD R3, R2, R3       @ calculating address of the current element in the first sequence
    LDR R2, [R3]         @ loading the current element from the first sequence
    LDR R3, [FP, #-16]   @ loading loop counter again to access next element
    LSL R3, R3, #2       @ calculating offset for accessing elements in the sequences
    LDR R1, [FP, #-28]   @ loading pointer to the second sequence
    ADD R3, R1, R3       @ calculating address of the current element in the second sequence
    LDR R3, [R3]         @ loading the current element from the second sequence
    
    CMP R2, R3           @ comparing the elements from both sequences
    BNE approxFlag       @ branches to approximate check if it is not an exact match
    
    LDR R3, [FP, #-8]    @ loading exact matches counter
    ADD R3, R3, #1       @ incrementing the exact matches counter by 1
    STR R3, [FP, #-8]    @ storing the updated exact matches counter
    
    B   endOfLoop        @ jump to end of the loop iteration

approxFlag:              @ flag for approximate matches
    MOV R3, #0           @ initializing a flag to check if an approximate match is found
    STR R3, [FP, #-20]   @ storing the flag
    B   approxFlagCheck  @ jump to the flag check
    
approxMatchCheck:        @ loop for checking the approximate matches
    LDR R3, [FP, #-16]   @ loading loop counter
    LSL R3, R3, #2       @ calculating offset for accessing elements in the sequences
    LDR R2, [FP, #-28]   @ loading pointer to the second sequence
    ADD R3, R2, R3       @ calculating address of the current element in the second sequence
    LDR R2, [R3]         @ loading the current element from the second sequence
    
    LDR R3, [FP, #-20]   @ loading the flag
    LSL R3, R3, #2       @ calculating offset for accessing elements in the sequences
    LDR R1, [FP, #-24]   @ loading pointer to the first sequence
    ADD R3, R1, R3       @ calculating address of the current element in the first sequence
    LDR R3, [R3]         @ loading the current element from the first sequence
    
    CMP R2, R3           @ comparing the elements from both sequences
    BNE approxLoopEnd    @ branches to end of loop for approx if approximate match is not found
    
    LDR R3, [FP, #-20]   @ loading the flag
    LSL R3, R3, #2       @ calculating offset for accessing elements in the sequences
    LDR R2, [FP, #-24]   @ loading pointer to the first sequence
    ADD R3, R2, R3       @ calculating address of the current element in the first sequence
    LDR R2, [R3]         @ loading the current element from the first sequence
    
    LDR R3, [FP, #-20]   @ loading the flag
    LSL R3, R3, #2       @ calculating offset for accessing elements in the sequences
    LDR R1, [FP, #-28]   @ loading pointer to the second sequence
    ADD R3, R1, R3       @ calculating address of the current element in the second sequence
    LDR R3, [R3]         @ loading the current element from the second sequence
    
    CMP R2, R3           @ comparing the elements from both sequences
    BEQ approxLoopEnd    @ branches to end of loop for approx if approximate match is found
    
    LDR R3, [FP, #-12]   @ loading approximate matches counter
    ADD R3, R3, #1       @ incrementing approximate matches counter
    STR R3, [FP, #-12]   @ storing the updated approximate matches counter
    B   endOfLoop        @ jump to end of the loop iteration
    

approxLoopEnd:           @ end of the loop iteration for approximate match check
    LDR R3, [FP, #-20]   @ loading the flag
    ADD R3, R3, #1       @ incrementing the flag by 1
    STR R3, [FP, #-20]   @ storing the updated flag

approxFlagCheck:                    
    LDR R3, [FP, #-20]   @ loading the flag
    CMP R3, #2           @ comparing flag value with 2
    BLE approxMatchCheck @ branches to loop for checking approx if flag value is less than or equal to 2

endOfLoop:               @ end of loop iteration
    LDR R3, [FP, #-16]   @ loading the loop counter
    ADD R3, R3, #1       @ incrementing the loop counter for the first sequence
    STR R3, [FP, #-16]   @ storing the updated loop counter
    
mainLoop:                @ main loop
    LDR R3, [FP, #-16]   @ loading the loop counter
    CMP R3, #2           @ comparing the loop counter with sequence length
    BLE exactMatchCheck  @ branches to exact match check if the loop counter is less than or equal to sequence length
    
    LDR R2, [FP, #-8]    @ loading exact matches counter (instruction below essentially perform same function as "return exact * 10 + approx;")
    MOV R3, R2           @ moving exact matches counter to R3
    LSL R3, R3, #2       @ multiplying exact matches counter by 10
    ADD R3, R3, R2       @ adding the approximate matches counter
    LSL R3, R3, #1       @ multiplying the sum of exact and approximate matches counter by 10
    MOV R2, R3           @ moving the sum to R2
    LDR R3, [FP, #-12]   @ loading the approximate matches counter
    ADD R3, R2, R3       @ adding the approximate matches counter to the sum
    MOV R0, R3           @ moving the sum (the final result) to R0
    ADD SP, FP, #0       @ cleaning up the stack frame
    LDR FP, [SP], #4     @ restoring the frame pointer
    BX  LR               @ returning from the subroutine
@ show the sequence in R0, use a call to printf in libc to do the printing, a useful function when debugging 
showseq: 			@ Input: R0 = pointer to a sequence of 3 int values to show
	@ COMPLETE THE CODE HERE (OPTIONAL)
	
	
@ =============================================================================

.data

@ constants about the basic setup of the game: length of sequence and number of colors	
.equ LEN, 3
.equ COL, 3
.equ NAN1, 8
.equ NAN2, 9

@ a format string for printf that can be used in showseq
f4str: .asciz "Seq:    %d %d %d\n"

@ a memory location, initialised as 0, you may need this in the matching fct
n: .word 0x00
	
@ INPUT DATA for the matching function
.align 4
secret: .word 1 
	.word 2 
	.word 1 

.align 4
guess:	.word 3 
	.word 1 
	.word 3 

@ Not strictly necessary, but can be used to test the result	
@ Expect Answer: 0 1
.align 4
expect: .byte 0
	.byte 1

.align 4
secret1: .word 1 
	 .word 2 
	 .word 3 

.align 4
guess1:	.word 1 
	.word 1 
	.word 2 

@ Not strictly necessary, but can be used to test the result	
@ Expect Answer: 1 1
.align 4
expect1: .byte 1
	 .byte 1

.align 4
secret2: .word 2 
	 .word 3
	 .word 2 

.align 4
guess2:	.word 3 
	.word 3 
	.word 1 

@ Not strictly necessary, but can be used to test the result	
@ Expect Answer: 1 0
.align 4
expect2: .byte 1
	 .byte 0
