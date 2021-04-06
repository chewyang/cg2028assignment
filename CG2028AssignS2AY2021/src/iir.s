 	.syntax unified
 	.cpu cortex-m3
 	.thumb
 	.align 2
 	.global	iir
 	.thumb_func

@ CG2028 Assignment, Sem 2, AY 2020/21
@ (c) CG2028 Teaching Team, ECE NUS, 2021

@Register map
@R0 - N, returns y
@R1 - b
@R2 - a
@R3 - x_n
@R4 - <use(s)>
@R5 - <use(s)>
@....

iir:

	@ PUSH / save (only those) registers which are modified by your function
	PUSH {R4-R12};


	MOV R12, R0; @ R12 = N
	ADD R12, #1; @ R12 = N+1

	LDR R4, [R1];@, #4; @R4 = value of b[0]
	LDR R5, [R2]; @R5 = value of a[0]

	MUL R6, R3, R4; @x_n * b[0] and store it in R6

	LDR R7, =y_store; @loads address at y_store into R3 0x1000 0000
	LDR R8, =x_store; @loads address at x_store into R4 0x1000 0030

loop_1:
	LDR R11, [R2, #4]!; @ R11 = a[1++] - pre-indexed addressing 120

	LDR R9, [R8], #4; @ R9 = x_store[1++]
	LDR R10, [R7], #4; @ R10 = y_store[1++]
	LDR R4, [R1, #4]!; @ R4 = b[1++] - pre-indexed addressing 250

	MUL R9, R4, R9; @ b[] * x_store
	MUL R10, R11, R10; @ a[] *y_store
	SUB R9, R9, R10;
	ADD R6, R6, R9; @y_n += (b[j+1] * x_store[j] - a[j+1] * y_store[j]);

	SUBS R12, #1; @reduce the counter
	BNE loop_1;
	SDIV R6, R6, R5; @divide all at once by a[0] after first loop

	SUB R0, R0, #1; @ counter = 4-1 = 3
	SUB R12, R0, #1; @ R12 = 3-1 = 2

	SUB R7, R7, #20; @return back to original pointer y_store[0]
	SUB R8, R8, #20; @return back to original pointer x_store[0]
loop_2:

	MOV R9, #4; @const 4 for making it easier to point to array index
	MUL R10, R12, R9; @ helps to point to array index with the counter in R12

	ADD R9, R8, R10; @ goes to x_store[j-1]
	ADD R10, R7, R10; @ goes to y_store[j-1]

	LDR R5, [R9];
	LDR R4, [R10];

	STR R5, [R9, #4]; @ y_store[j] = y_store[j-1];
	STR R4, [R10, #4]; @ x_store[j] = x_store[j-1];

	SUB R12, #1; @ reduce array index
	SUBS R0, #1; @ reduce counter
	BNE loop_2;

	STR R3, [R8]; @ x_store[0] = x_n;
	STR R6, [R7]; @ y_store[0] = y_n;

	MOV R5, #100;
	SDIV R6, R6, R5; @y_n /= 100; // scaling down

	MOV R0, R6
	POP {R4-R12}


@ parameter registers need not be saved.

@ write asm function body here

@ prepare value to return (y_n) to C program in R0

@ POP / restore original register values. DO NOT save or restore R0. Why?

@ return to C program
		BX	LR

@label: .word value
.equ N_MAX, 10
@.lcomm label num_bytes

const4:
	.word 2
.lcomm y_store 4*11
.lcomm x_store 4*11

